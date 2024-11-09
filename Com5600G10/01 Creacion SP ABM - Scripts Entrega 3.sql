/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 3 - SP de ABM
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) SP intermedio para api de dolar y conseguir valores de dolar
2) SP intermedio para registrar los 4 tipos de clientes del sistema
3) SP para el borrado logico de productos
4) SP para el borrado logico de empleados
5) SP para insertar productos de manera individual, sin duplicados y que actualiza en caso de coincidencia




*/


USE Com5600G10
GO

--1) SP para api de dolar
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.consultarDolarAPI
AS
BEGIN
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
        PRINT ('No se encontró el producto que se desea borrar')
		--RAISEERROR('No se encontró el producto que se desea borrar', 16, 1);
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
        --RAISEERROR('No se encontró el empleado con el legajo proporcionado.', 16, 1);
		PRINT 'No se encontro al empleado'
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
--1)
CREATE OR ALTER PROCEDURE Cajero.AgregarDetalleVenta
    @nombreProducto NVARCHAR(256), -- Nombre del producto
    @cantidadEnGr SMALLINT, -- Cantidad en gramos
    @legajoCajero INT -- Legajo del cajero (empleado)
AS
BEGIN
	DECLARE @idProd INT;
    DECLARE @nroFactura INT;
    DECLARE @idFactura CHAR(11);
    DECLARE @precio DECIMAL(6,2);
    DECLARE @precioFinal DECIMAL(6,2);
    DECLARE @unidadRef VARCHAR(64);
    DECLARE @tipoCambio DECIMAL(6,4); 
    DECLARE @precioEnLocal DECIMAL(6,2); -- Precio en moneda local (ARS)
    DECLARE @respuesta VARCHAR(MAX);
    DECLARE @precioUsd DECIMAL(6,2); -- Precio en USD
    DECLARE @precioArs DECIMAL(6,2); -- Precio en ARS
    DECLARE @json TABLE(respuesta VARCHAR(MAX)); -- Tabla temporal para almacenar respuesta de la API
    DECLARE @url VARCHAR(64) = 'https://dolarapi.com/v1/dolares';
    DECLARE @Object INT;

    -- Paso 1: Buscar si ya existe una factura pendiente de confirmacion
    SELECT @nroFactura = nroFactura 
    FROM INV.Factura
    WHERE idEmp = @legajoCajero AND regPago = 'Pendiente de Confirmacion'


    -- Si no se encuentra una factura pendiente, crear una nueva factura
    IF @nroFactura IS NULL
    BEGIN
        -- Crear una nueva factura
        INSERT INTO INV.Factura (idEmp, fecha, hora, regPago, tipoFac)
        VALUES (@legajoCajero, GETDATE(), CONVERT(TIME, GETDATE()), 'Pendiente de Pago', 'A'); -- Suponiendo tipoFac = 'A' para venta
        SET @nroFactura = SCOPE_IDENTITY(); -- Obtener el nro de factura recién creado
    END

    -- Paso 2: Buscar el precio del producto por nombre
    SELECT @precioUsd = precioUsd,
           @precioArs = precioArs,
           @unidadRef = unidadRef,
		   @idProd = idProd
    FROM Prod.Producto
    WHERE nombreProd = @nombreProducto;

    -- Verificar si el producto existe y tiene un precio
    IF @idProd IS NULL
    BEGIN
        PRINT 'Producto no registrado.';
        RETURN;
    END

	/******************
	--paso 3 consultar la api para conseguir el precio de dolar
	**************************/


	/***************************/
	print 'hasta aca todo bien'
	select * from INV.Factura
	where regPago = 'Pendiente de Pago'

	DECLARE @mensaje varchar(MAX)
	SET @mensaje = 'Precio USD: ' + CAST(@precioUsd AS VARCHAR(6)) + ', '
              + 'Precio ARS: ' + CAST(@precioArs AS VARCHAR(6)) + ', '
              + 'Unidad de Referencia: ' + ISNULL(@unidadRef, 'No disponible')
			  + '   IdProd:' + CAST(@idProd AS varchar(6));

	-- Mostrar el mensaje en el print
	PRINT @mensaje;

    --X controlar de kg a gr
	/****************************/


	/*
    -- Paso 4: Determinar el precio final en base a la moneda
    IF @precioUsd > 0 -- Si el precio está en USD
    BEGIN
        -- Convertir el precio de USD a la moneda local (ARS)
        SET @precioEnLocal = @precioUsd * @tipoCambio;
    END
    ELSE -- Si el precio está en ARS
    BEGIN
        SET @precioEnLocal = @precioArs;
    END

    -- Paso 5: Insertar el detalle de venta con el precio en pesos (ARS) y cantidad en gramos
    INSERT INTO INV.DetalleVenta (idProducto, idFactura, subTotal, cant, precio)
    SELECT p.idProd, @nroFactura, @cantidadEnGr * @precioEnLocal, @cantidadEnGr, @precioEnLocal
    FROM Prod.Producto p
    WHERE p.nombreProd = @nombreProducto;

    -- Paso 6: Mostrar resultados
    SELECT 
        @nombreProducto AS Producto,
        @nroFactura AS NroFactura,
        @cantidadEnGr * @precioEnLocal AS SubTotal, 
        @cantidadEnGr AS Cantidad, 
        @precioEnLocal AS Precio,
        @tipoCambio AS TipoCambio,
        @respuesta AS rta;
		*/


		--para ir eliminando duplicados:
		delete from INV.Factura
		where regPago = 'Pendiente de Pago'
END
GO


EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = '34in Ultrawide Monitor', 
    @cantidadEnGr = 1,
    @legajoCajero = 257020;



-- 2. Procedimiento para confirmar la compra


-- 3. Procedimiento para cancelar la compra
