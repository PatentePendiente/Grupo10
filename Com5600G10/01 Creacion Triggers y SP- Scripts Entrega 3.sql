/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 3 Insercion individual de tablas y control de borrados
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Trigger para el borrado logico de productos
2) Trigger para el borrado logico de empleados
3) SP para insertar productos de manera individual
4) SP para registrar una factura 
5) SP para registrar Detalle de Venta

*/


USE Com5600G10
GO

--1) Trigger para el borrado logico de productos
CREATE OR ALTER TRIGGER Prod.BorradoProductos ON Prod.Producto FOR DELETE
AS
BEGIN
    UPDATE Prod.Producto
    SET fechaBorrado = GETDATE() -- Fecha de borrado
    WHERE idProd IN (SELECT idProd FROM deleted); 
END;
GO

--2) Trigger para el borrado logico de empleados
CREATE OR ALTER TRIGGER HR.BorradoEmpleados ON HR.Empleado FOR DELETE
AS
BEGIN
    UPDATE HR.Empleado
    SET fechaBorrado = GETDATE() -- Fecha de borrado
    WHERE idSuc IN (SELECT idSuc FROM deleted); 
END;
GO


--3) SP para insertar productos de manera individual
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.InsertarProducto
    @lineaDeProducto VARCHAR(64),
    @nombreProd NVARCHAR(256),
    @precioArs DECIMAL(6,2) = 0,
    @precioUsd DECIMAL(6,2) = 0,  
    @unidadRef VARCHAR(64)
AS
BEGIN
    INSERT INTO Prod.Producto 
    (
        lineaDeProducto,
        nombreProd,
        precioArs,
        precioUsd,
        unidadRef
    )
    VALUES 
    (
        @lineaDeProducto,
        @nombreProd,
        @precioArs,
        @precioUsd,
        @unidadRef
    );
    
    PRINT 'Producto insertado correctamente.';
END;
GO

--4) SP para registrar una factura 
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.InsertarFactura
    @idFactura CHAR(11),
    @idEmp INT,
    @tipoFac CHAR(1),
    @tipoCliente CHAR(6),
    @genero CHAR(6),
    @fecha DATE = NULL, --Algunos campos son nulos para que no sea obligatorio indicarlos cuando se execute el sp
    @hora TIME = NULL,
    @regPago VARCHAR(22) = 'Pendiente de Pago'
AS
BEGIN
    -- Insertar la nueva factura
    INSERT INTO INV.Factura (idFactura, idEmp, tipoFac, tipoCliente, genero, fecha, hora, regPago)
    VALUES (@idFactura, @idEmp, @tipoFac, @tipoCliente, @genero, @fecha, @hora, @regPago)
END
GO

--5) SP para registrar un Detalle de Venta 
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.InsertarLineaDeVenta
    @idProducto INT,
    @idFactura CHAR(11),
    @cant SMALLINT
AS
BEGIN
    DECLARE @precio DECIMAL(6,2);
    DECLARE @precioEnArs DECIMAL(6,2);
    DECLARE @subTotal DECIMAL(9,2);
    DECLARE @tipoPrecio VARCHAR(3);
    DECLARE @cotizacionVenta DECIMAL(6,2);

    -- Obtener el precio y el tipo de moneda del producto
    SELECT @precio = 
                CASE
                    WHEN precioArs IS NOT NULL THEN precioArs -- Si el precio en ARS está disponible
                    ELSE precioUsd -- Si el precio esta en USD, lo convertimos a ARS usando la API
                END,
           @tipoPrecio = 
                CASE
                    WHEN precioArs IS NOT NULL THEN 'ARS' 
                    ELSE 'USD' 
                END
    FROM Prod.Producto
    WHERE idProd = @idProducto;

    -- Si el precio está en USD, obtener la cotización actual para la conversión
    IF @tipoPrecio = 'USD'
    BEGIN
        -- Consultar la API para obtener la cotización de USD a ARS
        DECLARE @json TABLE (moneda VARCHAR(3), casa VARCHAR(16), nombre VARCHAR(16), 
		compra DECIMAL(6,2), venta DECIMAL(6,2), fechaActualizacion DATETIME2);
        
        -- Llamar la API y cargar la respuesta en la tabla temporal @json
        INSERT INTO @json
        EXEC ImportadorDeArchivos.consultarDolarAPI;

        -- Seleccionar la cotización de venta que es la oficial (se podria haber seleccionado la 2da que es el dolar blue)
        SELECT TOP 1 @cotizacionVenta = venta 
        FROM @json;

        -- Convertir el precio de USD a ARS
        SET @precioEnArs = @precio * @cotizacionVenta;
    END
    ELSE
        SET @precioEnArs = @precio;
    
    SET @subTotal = @precioEnArs * @cant;

    INSERT INTO INV.DetalleVenta
    (
        idProducto,
        idFactura,
        subTotal,
        cant,
        precio
    )
    VALUES 
    (
        @idProducto,
        @idFactura,
        @subTotal,
        @cant,
        @precioEnArs
    );

    PRINT 'Detalle de venta insertado correctamente.';
END;








