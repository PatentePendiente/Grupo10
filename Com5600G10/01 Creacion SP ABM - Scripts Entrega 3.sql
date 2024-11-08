/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 3 - SP de ABM
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) SP para api de dolar
2) Trigger para el borrado logico de productos
3) Trigger para el borrado logico de empleados
4) SP para insertar productos de manera individual
5) SP para registrar una factura 
6) SP para registrar Detalle de Venta

*/


USE Com5600G10
GO

--1) SP para api de dolar
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.consultarDolarAPI
AS
BEGIN
	-- Para ejecutar un llamado a una API desde SQL primero vamos a tener que 
	-- habilitar ciertos permisos que por default vienen bloqueados (Ole Auomation Procedures).
	EXEC sp_configure 'show advanced options', 1; --borrar 
	RECONFIGURE;
	EXEC sp_configure 'Ole Automation Procedures', 1;
	RECONFIGURE;

	-- Declarar variables
	DECLARE @url VARCHAR(64) = 'https://dolarapi.com/v1/dolares';
	DECLARE @Object INT;
	DECLARE @json TABLE(respuesta VARCHAR(MAX));
	DECLARE @respuesta VARCHAR(MAX);

	-- Crear una instancia de objete OLE
	EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;

	-- Definir las propiedades del objeto OLE para hacer llamada HTTP GET
	EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';

	-- Enviar la consulta
	EXEC sp_OAMethod @Object, 'SEND';

	-- Almacenar el texto de la respuesta de la consulta
	EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT;

	-- Insetar la respuesta de la consulta en la tabla @json
	INSERT @json 
	EXEC sp_OAGetProperty @Object, 'RESPONSETEXT' -- Obtenemos el valor de la propiedad 'RESPONSETEXT' del objeto OLE luego de realizar la consulta.

	-- Eliminar el objeto OLE
	EXEC sp_OADestroy @Object;

	-- Parsear la respuesta JSON y retornar los resultados
	DECLARE @datos VARCHAR(MAX) = (SELECT * FROM @json);
	SELECT * FROM OPENJSON(@datos)
	WITH
	(
		[moneda] CHAR(3) '$.moneda',
		[casa] VARCHAR(16) '$.casa',
		[nombre] VARCHAR(16) '$.nombre',
		[compra] DECIMAL(6, 2) '$.compra',
		[venta] DECIMAL(6, 2) '$.venta',
		[fechaActualizacion] DATETIME2 '$.fechaActualizacion'
	);
END;
GO

--2) SP para el borrado logico de producto
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.BorrarProducto
    @nombreProd NVARCHAR(256)
AS
BEGIN
    UPDATE Prod.Producto
    SET fechaBorrado = GETDATE() -- Fecha de borrado lógico
    WHERE nombreProd = @nombreProd; -- Filtrar por el nombre del producto

    -- Verificación de si se realizó el borrado lógico
    IF @@ROWCOUNT = 0
        PRINT ('No se encontró el producto que se desea borrar')
		--RAISEERROR('No se encontró el producto que se desea borrar', 16, 1);
    ELSE
        -- Si se actualizó correctamente, confirmar el borrado
        PRINT 'Producto borrado correctamente'
END;
GO

--3) SP para el borrado logico de empleado
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.BorrarEmpleadoLogico
    @legajo INT
AS
BEGIN
    -- Realizar el borrado lógico (actualizar la fecha de borrado)
    UPDATE HR.Empleado
    SET fechaBorrado = GETDATE() -- Fecha de borrado lógico
    WHERE legajo = @legajo; -- Filtrar por el legajo del empleado

    -- Verificación de si se realizó el borrado lógico
    IF @@ROWCOUNT = 0
        -- Si no se actualizó ningún registro, lanzar un error
        --RAISEERROR('No se encontró el empleado con el legajo proporcionado.', 16, 1);
		PRINT 'No se encontro al empleado'
    ELSE
        -- Si se actualizó correctamente, confirmar el borrado
        PRINT 'Empleado borrado correctamente.';
END;
GO


--4) SP para insertar productos de manera individual
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.InsertarProducto
    @lineaDeProducto VARCHAR(64),
    @nombreProd NVARCHAR(256),
    @precioArs DECIMAL(6,2) = 0,
    @precioUsd DECIMAL(6,2) = 0,  
    @unidadRef VARCHAR(64)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Prod.Producto WHERE nombreProd = @nombreProd)
    BEGIN
        -- Si el producto ya existe lo actualiza
        UPDATE Prod.Producto
        SET 
            lineaDeProducto = @lineaDeProducto,
            precioArs = @precioArs,
            precioUsd = @precioUsd,
            unidadRef = @unidadRef
        WHERE 
            nombreProd = @nombreProd;
        
        PRINT 'Producto actualizado correctamente.';
    END
    ELSE
    BEGIN
        -- Si el producto no existe, lo inserta
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
    END
END;
GO

--5) SP para registrar una factura 
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.InsertarFactura
    @legajoEmp INT,                      -- Recibe el legajo del empleado
    @tipoFac CHAR(1),
    @tipoCliente CHAR(6),
    @genero CHAR(6),
    @fecha DATE = NULL,                  -- Algunos campos son nulos para que no sea obligatorio indicarlos
    @hora TIME = NULL,                   -- cuando se ejecute el sp
    @regPago VARCHAR(22) = 'Pendiente de Pago'
AS
BEGIN
    DECLARE @idEmp INT;

	/*
    -- Verificar si la factura ya existe
    IF EXISTS (
        SELECT 1 
        FROM INV.Factura
        WHERE idFactura = @idFactura
    )
    BEGIN
        PRINT 'La factura ya existe en el sistema.';
        RETURN;
    END*/

    -- Obtener el ID del empleado a partir del legajo para ver si existe
    SELECT @idEmp = legajo
    FROM HR.Empleado
    WHERE legajo = @legajoEmp;

    -- Verificar si el empleado esta registrado
    IF @idEmp IS NULL
    BEGIN
        PRINT 'El legajo del empleado no se encuentra registrado.';
        RETURN;
    END

    -- Insertar la nueva factura
    INSERT INTO INV.Factura (idFactura, idEmp, tipoFac, tipoCliente, genero, fecha, hora, regPago)
    VALUES (@idFactura, @idEmp, @tipoFac, @tipoCliente, @genero, @fecha, @hora, @regPago);

    PRINT 'Factura insertada correctamente.';
END;
GO


--6) SP para registrar un Detalle de Venta 
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.InsertarLineaDeVenta
    @nombreProd NVARCHAR(256),  -- Recibe el nombre del producto
    @idFactura CHAR(11), --factura vinculada
    @cant SMALLINT --cantidad vendida
AS
BEGIN
    DECLARE @idProducto INT;
    DECLARE @precio DECIMAL(6,2);
    DECLARE @precioEnArs DECIMAL(6,2);
    DECLARE @subTotal DECIMAL(9,2);
    DECLARE @tipoPrecio VARCHAR(3);
    DECLARE @cotizacionVenta DECIMAL(6,2);

    -- Obtener el idProducto desde el nombre del producto
    SELECT @idProducto = idProd
    FROM Prod.Producto
    WHERE nombreProd = @nombreProd;

    -- Verificar si el producto existe
    IF @idProducto IS NULL
    BEGIN
        PRINT 'El producto no se encuentra registrado.';
        RETURN;
    END

    -- Verificación de que no se dupliquen detalles de ventas para un mismo producto de una misma factura:
    IF EXISTS (
        SELECT 1 
        FROM INV.DetalleVenta
        WHERE idProducto = @idProducto AND idFactura = @idFactura
    )
    BEGIN
        PRINT 'Este producto ya ha sido agregado para esta factura.';
        RETURN;
    END
	/*
    -- Obtener el precio y el tipo de moneda del producto
    SELECT @precio = 
                CASE
                    WHEN precioArs IS NOT NULL THEN precioArs 
                    ELSE 
						CASE 
                            WHEN precioUsd IS NOT NULL THEN precioUsd 
                            ELSE 0
                        END
                END,
           @tipoPrecio = 
                CASE
                    WHEN precioArs IS NOT NULL AND precioArs > 0 THEN 'ARS' 
                    ELSE 'USD' 
                END
    FROM Prod.Producto
    WHERE idProd = @idProducto;*/

    -- Si el precio está en USD, obtener la cotización actual para la conversión
    IF @tipoPrecio = 'USD' AND @precio > 0
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

        -- Convertir el precio de USD a ARS si la cotización es válida
        IF @cotizacionVenta > 0
        BEGIN
            SET @precioEnArs = @precio * @cotizacionVenta;
        END
        ELSE
        BEGIN
            PRINT 'Error al obtener la cotización de USD a ARS.';
            RETURN;
        END
    END
    ELSE
    BEGIN
        SET @precioEnArs = @precio;
    END
    
    -- Validación para evitar que el subtotal sea 0
    IF @precioEnArs <= 0
    BEGIN
        PRINT 'El precio del producto es 0 o no válido.';
        RETURN;
    END

    -- Calcular el subtotal
    SET @subTotal = @precioEnArs * @cant;

    -- Validar que el subtotal no sea 0
    IF @subTotal <= 0
    BEGIN
        PRINT 'El subtotal calculado es 0 o no válido.';
        RETURN;
    END

    -- Insertar el detalle de la venta
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

    PRINT 'Detalle de venta registrado correctamente.';
END;







