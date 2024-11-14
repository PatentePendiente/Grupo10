/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 3 - SP de ABM
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

NOTA: cambiamos la funcionalidad de la api, ahora solo devuelve el valor del dolar que nos interesa a nostros
INDICE: 
1) SP intermedio para api de dolar y conseguir valores de dolar
2) SP intermedio para registrar los 4 tipos de clientes del sistema
3) SP para el borrado logico de productos
4) SP para el borrado logico de empleados
5) SP para insertar productos de manera individual, sin duplicados y que actualiza en caso de coincidencia

Registracion de ventas
----------------------
6) Procedimiento para crear detalles de ventas
7) Procedimiento para confirmar la compra
8) Procedimiento para cancelar la compra
*/


USE Com5600G10
GO

--1) SP para api de dolar
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.consultarDolarAPI
	@valorDolarCompra DECIMAL(6,2) OUT
AS
BEGIN
    -- Declarar variables
    DECLARE @url VARCHAR(64) = 'https://dolarapi.com/v1/dolares';
    DECLARE @Object INT;
    DECLARE @json TABLE(respuesta VARCHAR(MAX));
    DECLARE @respuesta VARCHAR(MAX);

    -- Crear una instancia de objeto OLE
    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;

    -- Definir las propiedades del objeto OLE para hacer llamada HTTP GET
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';

    -- Enviar la consulta
    EXEC sp_OAMethod @Object, 'SEND';

    -- Almacenar el texto de la respuesta de la consulta
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT;

    -- Insertar la respuesta de la consulta en la tabla @json
    INSERT INTO @json (respuesta)
    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';

    -- Eliminar el objeto OLE
    EXEC sp_OADestroy @Object;

    -- Parsear la respuesta JSON y retornar los resultados
    DECLARE @datos VARCHAR(MAX) = (SELECT respuesta FROM @json);
    SELECT @valorDolarCompra = compra FROM OPENJSON(@datos)
    WITH
    (
        [moneda] CHAR(3) '$.moneda',
        [casa] VARCHAR(16) '$.casa',
        [nombre] VARCHAR(16) '$.nombre',
        [compra] DECIMAL(6, 2) '$.compra',
        [venta] DECIMAL(6, 2) '$.venta',
        [fechaActualizacion] DATETIME2 '$.fechaActualizacion'
    ) WHERE casa LIKE 'oficial';

END;
GO

--2) SP para registrar los 4 tipos de clientes
CREATE OR ALTER PROCEDURE DBA.InsertarClientes
AS
BEGIN
    -- Verificar si no existen los tipos de cliente
    IF NOT EXISTS (SELECT 1 FROM HR.Cliente WHERE tipoCliente = 'Member' AND genero = 'Female')
    BEGIN
        INSERT INTO HR.Cliente (tipoCliente, genero)
        VALUES ('Member', 'Female');
    END

    IF NOT EXISTS (SELECT 1 FROM HR.Cliente WHERE tipoCliente = 'Member' AND genero = 'Male')
    BEGIN
        INSERT INTO HR.Cliente (tipoCliente, genero)
        VALUES ('Member', 'Male');
    END

    IF NOT EXISTS (SELECT 1 FROM HR.Cliente WHERE tipoCliente = 'Normal' AND genero = 'Female')
    BEGIN
        INSERT INTO HR.Cliente (tipoCliente, genero)
        VALUES ('Normal', 'Female');
    END

    IF NOT EXISTS (SELECT 1 FROM HR.Cliente WHERE tipoCliente = 'Normal' AND genero = 'Male')
    BEGIN
        INSERT INTO HR.Cliente (tipoCliente, genero)
        VALUES ('Normal', 'Male');
    END
END;
GO

--3) SP para el borrado logico de producto
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.BorrarProducto
    @nombreProd NVARCHAR(256)
AS
BEGIN
    UPDATE Prod.Producto
    SET fechaBorrado = GETDATE() -- Fecha de borrado lógico
    WHERE nombreProd = @nombreProd; -- Filtrar por el nombre del producto

    -- Verificación de si se realizó el borrado lógico
    IF @@ROWCOUNT = 0
	BEGIN
       -- PRINT ('No se encontró el producto que se desea borrar')
		RAISERROR('No se encontró el producto que se desea borrar %s', 16, 1, @nombreProd);
		RETURN;
	END
    ELSE
        -- Si se actualizó correctamente, confirmar el borrado
        PRINT 'Producto borrado correctamente'
END;
GO

--4) SP para el borrado logico de empleado
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.BorrarEmpleado
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
	BEGIN
        RAISERROR('No se encontró el empleado con el legajo proporcionado %d', 16, 1, @legajo);
        RETURN;
	END
    ELSE
        -- Si se actualizó correctamente, confirmar el borrado
        PRINT 'Empleado borrado correctamente.';
END;
GO

--5) SP para insertar productos de manera individual
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



-----------------------------------------------------------------------
--				      REGISTRACION DE VENTAS				      	 --
-----------------------------------------------------------------------
/*
Severidad de Raise_Error:
00-10 -> informativo o advertencias
11-16 -> errores de usuario 
17-25 -> errores graves que pueden requerir intervencion administrativa o cierre de sesion
*/

--6) Registrar Detalle de venta nuevo, si la factura no existe para el cajero que esta registrando la venta
--se crea una nueva factura con estado falta confirmacion y si existe se crea un nuevo detalle de venta asociado a ese id fanstasma
CREATE OR ALTER PROCEDURE Cajero.AgregarDetalleVenta
    @nombreProducto VARCHAR(256), -- Nombre del producto
    @cantidadEnGr SMALLINT, -- Cantidad en gramos
    @legajoCajero INT -- Legajo del cajero (empleado)
AS
BEGIN
	DECLARE @idProd INT;
    DECLARE @nroFactura INT;
    DECLARE @idFactura CHAR(11);
    DECLARE @unidadRef VARCHAR(64);
	DECLARE @cantRef DECIMAL(6,2);
	DECLARE @unidad NVARCHAR(50);
    DECLARE @precioUsd DECIMAL(6,2); -- Precio en USD
    DECLARE @precioArs DECIMAL(6,2); -- Precio en ARS
    DECLARE @precioEnLocal DECIMAL(9,2); -- Precio prod en pesos
    DECLARE @subTotalVendido DECIMAL(9,2); -- Precio final multiplicado por la cantidad comprada

	--Validacion de que existe el nroLegajo
	IF NOT EXISTS (SELECT 1 FROM HR.Empleado WHERE legajo = @legajoCajero)
	BEGIN
		RAISERROR ('El legajo del cajero %d no se encuentra registrado.', 16, 1, @legajoCajero);
		RETURN;
	END

    -- Paso 1: Buscar el precio del producto por nombre
    SELECT @precioUsd = precioUsd,
           @precioArs = precioArs,
           @unidadRef = unidadRef,
		   @idProd = idProd
    FROM Prod.Producto
    WHERE nombreProd = @nombreProducto;

    -- Verificar si el producto existe
    IF @idProd IS NULL
    BEGIN
        RAISERROR('Producto no registrado: %s', 16, 1, @nombreProducto);
        RETURN;
    END

    -- Paso 2: Buscar si ya existe una factura pendiente de confirmacion
    SELECT @nroFactura = nroFactura 
    FROM INV.Factura
    WHERE idEmp = @legajoCajero AND regPago = 'falta confirmacion'

    -- Si no se encuentra una factura pendiente, crear una nueva factura asociada al legajo del cajero
    IF @nroFactura IS NULL
    BEGIN
        -- Crear una nueva factura
        INSERT INTO INV.Factura (idEmp, fecha, hora, regPago)
        VALUES (@legajoCajero, GETDATE(), CONVERT(TIME, GETDATE()), 'falta confirmacion'); 
        SET @nroFactura = SCOPE_IDENTITY(); -- Obtener el nro de factura recién creado
    END

	--paso 3 consultar la api para conseguir el precio de dolar
	DECLARE @valorDolarVenta DECIMAL(6,2);
	EXEC ImportadorDeArchivos.consultarDolarAPI @valorDolarVenta OUT;
	PRINT 'DOLAR COMPRA: ' + CAST(@valorDolarVenta AS VARCHAR);

    -- Paso 4: Determinar el precio final en base a la moneda
    IF @precioUsd > 0 -- Si el precio está en USD
        SET @precioEnLocal = @precioUsd * @valorDolarVenta;
    ELSE
        SET @precioEnLocal = @precioArs;

	-- Paso 5: Control de unidades y estandarizar a Gr
	SET @cantRef = 
    CASE 
        WHEN @unidadRef LIKE 'kg' THEN 
            1000
        WHEN @unidadRef LIKE '[0-9][0-9][0-9] g' 
             OR @unidadRef LIKE '[0-9][0-9] g' 
             OR @unidadRef LIKE '[0-9] g' THEN 
            CAST(SUBSTRING(@unidadRef, 1, CHARINDEX(' ', @unidadRef) - 1) AS INT)  -- Extraemos la cantidad en gramos
        ELSE 
            1  
    END;

    -- Paso 6: Registrar nuevo detalle de venta
	SET @subTotalVendido = (@precioEnLocal * @cantidadEnGr) / @cantRef

    INSERT INTO INV.DetalleVenta (idProducto, nroFactura, subTotal, cant, precio)
    SELECT p.idProd, @nroFactura, @subTotalVendido, @cantidadEnGr, @precioEnLocal
    FROM Prod.Producto p
    WHERE p.nombreProd = @nombreProducto;

END
GO


-- 7. Procedimiento para confirmar la venta
CREATE OR ALTER PROCEDURE Cajero.ConfirmarVenta
    @legajoCajero INT, -- Legajo del cajero que desea confirmar la venta
	@regPago VARCHAR(22) = 'Pendiente de Pago' -- Puede no registrar el pago y quedaria como pendiente de pago
AS
BEGIN
    DECLARE @nroFactura INT;

	--Validacion de que existe el nroLegajo
	IF NOT EXISTS (SELECT 1 FROM HR.Empleado WHERE legajo = @legajoCajero)
	BEGIN
		RAISERROR ('El legajo del cajero %d no se encuentra registrado.', 16, 1, @legajoCajero);
		RETURN;
	END

    -- Paso 1: Buscar la factura pendiente de confirmación para el cajero
    SELECT @nroFactura = nroFactura 
    FROM INV.Factura
    WHERE regPago = 'falta confirmacion' AND idEmp = @legajoCajero;

    -- Verificar si existe una factura pendiente para este cajero
    IF @nroFactura IS NULL
    BEGIN
        RAISERROR('No hay una factura pendiente de confirmacion asociado al legajo %d.', 16, 1, @legajoCajero);
        RETURN;
    END

    -- Paso 2: Contar el total de detalles de la factura
    DECLARE @totalDetalles INT;
    SELECT @totalDetalles = COUNT(*)
    FROM INV.DetalleVenta
    WHERE nroFactura = @nroFactura;

    -- Paso 3: Verificar si la factura tiene detalles
    IF @totalDetalles = 0
    BEGIN
        RAISERROR('La factura %d no tiene detalles de venta para ser confirmados.', 16, 1, @nroFactura);
        RETURN;
    END

    -- Paso 4: Confirmar la venta actualizando el estado de la factura
    UPDATE INV.Factura
    SET regPago = @regPago
    WHERE nroFactura = @nroFactura;

    PRINT 'Venta confirmada exitosamente. Factura: ' + CAST(@nroFactura AS VARCHAR);
END
GO


-- 8. Procedimiento para cancelar la compra
CREATE OR ALTER PROCEDURE Cajero.CancelarVenta
    @legajoCajero INT -- Legajo del cajero que desea cancelar la venta
AS
BEGIN
    DECLARE @nroFactura INT;
    DECLARE @totalDetalles INT;

	--Validacion de que existe el nroLegajo
	IF NOT EXISTS (SELECT 1 FROM HR.Empleado WHERE legajo = @legajoCajero)
	BEGIN
		RAISERROR ('El legajo del cajero %d no se encuentra registrado.', 16, 1, @legajoCajero);
		RETURN;
	END

    -- Paso 1: Buscar la factura pendiente de confirmación para el cajero
    SELECT @nroFactura = nroFactura
    FROM INV.Factura
    WHERE idEmp = @legajoCajero AND regPago = 'falta confirmacion';

    -- Verificar si existe una factura pendiente para este cajero
    IF @nroFactura IS NULL
    BEGIN
        RAISERROR('No hay una factura pendiente para cancelar asociado al legajo %d.', 16, 1, @legajoCajero);
        RETURN;
    END

    -- Paso 2: Contar el total de detalles de la factura
    SELECT @totalDetalles = COUNT(*)
    FROM INV.DetalleVenta
    WHERE nroFactura = @nroFactura;

    -- Paso 3: Verificar si la factura tiene detalles
    IF @totalDetalles = 0
    BEGIN
        RAISERROR('La factura %d no tiene detalles asociados para ser cancelados.', 16, 1, @nroFactura);
        RETURN;
    END

    -- Paso 4: Eliminar los detalles de venta de la factura
    DELETE FROM INV.DetalleVenta
    WHERE nroFactura = @nroFactura;

    -- Paso 5: Eliminar la factura
    DELETE FROM INV.Factura
    WHERE nroFactura = @nroFactura

    PRINT 'Venta cancelada exitosamente. Factura: ' + CAST(@nroFactura AS VARCHAR);
END
GO



