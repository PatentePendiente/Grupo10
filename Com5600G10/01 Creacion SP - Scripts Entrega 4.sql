/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 4 Insercion de Tablas
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MAMANI ESTRADA, LUCAS GABRIEL  --
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

INDICE: 
1) Api de Dolar
2) Importado de Productos_importados.xlsx
3) Importado de Sucursales
4) Importado de Catalogo.csv
5) Importado de Electronic accessories.xlsx
6) Importado de Empleados
7) Importado de Ventas
*/

USE Com5600G10
GO

--1) Api de Dolar
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.consultarDolarAPI
AS
BEGIN
	-- Para ejecutar un llamado a una API desde SQL primero vamos a tener que 
	-- habilitar ciertos permisos que por default vienen bloqueados (Ole Auomation Procedures).
	EXEC sp_configure 'show advanced options', 1;
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
--EXEC PROD.consultarDolarAPI;
-- DROP PROCEDURE PROD.consultarDolarAPI;


--2) Importado de Productos_importados.xlsx
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarProductosImportados
	@ruta VARCHAR(MAX)
AS
BEGIN
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
	RECONFIGURE;

	CREATE TABLE #tablaImportada (
		idProducto VARCHAR(MAX),
		nombreProducto NVARCHAR(MAX),
		proveedor NVARCHAR(MAX),
		categoria NVARCHAR(MAX),
		cantidadUnidad NVARCHAR(MAX),
		precioUnidad VARCHAR(MAX)
	)

	DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'INSERT INTO #tablaImportada SELECT * FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database=' + @ruta + ';HDR=YES'', ''SELECT * FROM [Listado de Productos$]'');';
    exec sp_executesql @sql;

	--Control de que no hayan productos duplicados en la tabla
	WITH Duplicados AS (
    SELECT 
        idProducto,
        nombreProducto,
        ROW_NUMBER() OVER (PARTITION BY nombreProducto ORDER BY (SELECT NULL)) AS RowNum
    FROM 
        #tablaImportada
	)
	DELETE FROM Duplicados
	WHERE RowNum > 1;


-- Merge para controlar que no se duplique la informacion, si ya se encuentra el registro entonces actualizara los campos
-- por si el valor del producto cambio
    MERGE INTO PROD.Producto AS TARGET
    USING (
        SELECT 
            nombreProducto AS nombreProd, 
            CAST(precioUnidad AS DECIMAL(6,2)) AS precioArs, 
            cantidadUnidad AS unidadRef,
            categoria AS lineaDeProducto
        FROM #tablaImportada
    ) AS source
    ON target.nombreProd = source.nombreProd
    WHEN MATCHED THEN
        UPDATE SET 
            target.precioArs = source.precioArs,
            target.unidadRef = source.unidadRef
    WHEN NOT MATCHED THEN
        INSERT (nombreProd, precioArs, unidadRef, lineaDeProducto)
        VALUES (source.nombreProd, source.precioArs, source.unidadRef, source.lineaDeProducto);

	DROP TABLE #tablaImportada;
END;
GO
-- Ejecutar el procedimiento almacenado para importar los productos
--EXEC PROD.importarProductosImportados 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\Productos_importados.xlsx';
--SELECT * FROM PROD.Producto;
-- DROP PROCEDURE PROD.importarProductosImportados;


--3) Importado de Sucursales
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarSucursales
	@ruta VARCHAR(MAX)
AS
BEGIN
    -- Habilitar consultas distribuidas ad hoc
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
    RECONFIGURE;

	CREATE TABLE #tablaImportada (
		ciudad VARCHAR(16),
		reemplazarPor VARCHAR(32),
		direccion NVARCHAR(MAX),
		horario  VARCHAR(64),
		telefono CHAR(9)
	)

    -- Usamos OPENROWSET para importar datos desde archivo Excel
	DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'INSERT INTO #tablaImportada SELECT * FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database=' + @ruta + ';HDR=YES'', ''SELECT * FROM [sucursal$B2:F]'');';
    EXEC sp_executesql @sql;

	-- MERGE para controlar que no se duplique informacion
	MERGE INTO HR.Sucursal AS TARGET
		USING (
		 SELECT 
			 ciudad, 
			 reemplazarPor
			FROM #tablaImportada
		) AS source
	 ON target.ciudad = source.ciudad
	 WHEN MATCHED THEN
		    UPDATE SET 
	         target.localidad = source.reemplazarPor
	    WHEN NOT MATCHED THEN
		    INSERT (ciudad, localidad)
		 VALUES (source.ciudad, source.reemplazarPor);

    -- Eliminamos la tabla temporal después de la importación
    DROP TABLE #tablaImportada;
END;
GO
-- Ejecutar el procedimiento almacenado para importar las sucursales
--EXEC HR.importarSucursales 'C:\Users\JuanD\OneDrive\Escritorio\bbdda\Informacion_complementaria.xlsx';
--EXEC HR.importarSucursales 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';
--SELECT * FROM HR.Sucursal;
-- DROP PROCEDURE HR.importarSucursales;


--4) Carga de Catalogo.csv
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarCatalogo
    @ruta VARCHAR(MAX)
AS
BEGIN
    -- creamos la tabla temporal donde se van a guardar los datos del archivo csv
    CREATE TABLE #tablaImportada (
        id VARCHAR(MAX),
        categoria VARCHAR(MAX),
        nombre NVARCHAR(MAX),
        precio VARCHAR(MAX),
        precioReferencia VARCHAR(MAX),
        unidad VARCHAR(MAX),
        fecha VARCHAR(MAX)
    );

	-- Usamos SQL dinamico para utilizar BULK INSERT con una ruta variable
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'BULK INSERT #tablaImportada FROM ''' + @ruta + ''' WITH (FORMAT = ''CSV'', FIELDQUOTE = ''"'' ,FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0A'', FIRSTROW = 2, CODEPAGE = ''65001'');';
	EXEC sp_executesql @sql;

	--La tabla cuenta con productos duplicados hay que eliminarlos
	WITH Duplicados AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY (SELECT NULL)) AS RowNum
    FROM #tablaImportada
	)
	DELETE FROM Duplicados
	WHERE RowNum > 1;


	--MERGE para no admitir duplicados y si ya existe entonces actualizar el precio viejo al nuevo
	MERGE INTO PROD.Producto AS TARGET
	 USING (
		 SELECT 
            categoria, 
            CAST(precio AS DECIMAL(6,2)) AS PrecioArs,
            nombre,
            unidad
        FROM #tablaImportada
	) AS source
    ON TARGET.nombreProd = source.nombre
    WHEN MATCHED THEN
        UPDATE SET 
            TARGET.lineaDeProducto = source.categoria,
            TARGET.PrecioArs = source.PrecioArs,
            TARGET.unidadRef = source.unidad
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (lineaDeProducto, PrecioArs, nombreProd, unidadRef)
        VALUES (source.categoria, source.PrecioArs, source.nombre, source.unidad);

	DROP TABLE #tablaImportada;
END;
GO
-- Ejecutar el procedimiento almacenado para importar el catálogo
--EXEC PROD.importarCatalogo 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\catalogo.csv';
--select * from PROD.Producto
--DROP PROCEDURE PROD.importarCatalogo;


--5) Importado de Productos_importados.xlsx
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarProductosAccesoriosElectronicos
	@ruta VARCHAR(MAX)
AS
BEGIN
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
	RECONFIGURE;

	CREATE TABLE #tablaImportada (
		nombreProducto NVARCHAR(MAX),
		precioUSD VARCHAR(MAX),
	)

	DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'INSERT INTO #tablaImportada SELECT * FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database=' + @ruta + ';HDR=YES'', ''SELECT * FROM [Sheet1$]'');';
    EXEC sp_executesql @sql;

	declare @lineaDeProd char(20);
	set @lineaDeProd = 'Accesorio electronico';

	--Control de productos duplicados en la carga
	WITH Duplicados AS (
    SELECT 
        nombreProducto,
        precioUSD,
        ROW_NUMBER() OVER (PARTITION BY nombreProducto ORDER BY (SELECT NULL)) AS RowNum
    FROM 
        #tablaImportada
	)
	DELETE FROM #tablaImportada
	WHERE nombreProducto IN (SELECT nombreProducto FROM Duplicados WHERE RowNum > 1);

	--MERGE para controlar duplicados
	MERGE INTO PROD.Producto AS TARGET
	USING (
	 SELECT 
		   nombreProducto, 
		    CAST(precioUSD AS DECIMAL(6, 2)) AS precioUSD
	  FROM #tablaImportada
	) AS source
	ON TARGET.nombreProd = source.nombreProducto
	WHEN MATCHED THEN
	   UPDATE SET 
	      TARGET.precioUsd = source.precioUSD  -- Actualiza el precio si existe
	WHEN NOT MATCHED THEN
		INSERT (lineaDeProducto, nombreProd, precioUsd, unidadRef)
		VALUES (@lineaDeProd, source.nombreProducto, source.precioUSD, '1 unidad');

	DROP TABLE #tablaImportada;
END;
GO

-- Ejecutar el procedimiento almacenado para importar los productos
--EXEC PROD.importarProductosAccesoriosElectronicos 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\Electronic accessories.xlsx';
--SELECT * FROM PROD.Producto;
--drop procedure PROD.importarProductosAccesoriosElectronicos


--6) Importado de Empleados
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarEmpleados
	@ruta VARCHAR(MAX)
AS
BEGIN
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
	RECONFIGURE;

	--Legajo/ID	Nombre	Apellido	DNI  direccion email personal	email empresa	CUIL	Cargo	Sucursal	Turno
	CREATE TABLE #tablaImportada (
		legajo VARCHAR(MAX),
		nombre VARCHAR(MAX),
		apellido VARCHAR(MAX),
		doc DECIMAL(15,2),
		direccion VARCHAR(MAX),
		emailPers VARCHAR(MAX),
		emailEmp VARCHAR(MAX),
		cuil VARCHAR(MAX),
		cargo VARCHAR(MAX),
		surcursal VARCHAR(MAX),
		turno VARCHAR(MAX)
	)

	DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'INSERT INTO #tablaImportada SELECT * FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database=' + @ruta + ';HDR=YES'', ''SELECT * FROM [Empleados$]'');';
    EXEC sp_executesql @sql;

	--Elimino filas que se leen nulas
	delete from #tablaImportada 
	where legajo is null
	

	MERGE INTO HR.Empleado AS TARGET
	USING (
	 SELECT 
        CAST(t.legajo AS INT) AS legajo,
        t.nombre,
        t.apellido,
        CAST(t.doc AS INT) AS dni,
        t.direccion,
        CAST(t.cargo AS CHAR(20)) AS cargo,
        CAST(t.turno AS CHAR(16)) AS turno,
        t.emailPers,
        t.emailEmp,
        s.nroSucursal
    FROM #tablaImportada t
    INNER JOIN HR.Sucursal s ON t.surcursal = s.localidad
	) AS SOURCE
	ON TARGET.legajo = SOURCE.legajo
	WHEN MATCHED THEN 
	  UPDATE SET 
        TARGET.nombre = SOURCE.nombre,
        TARGET.apellido = SOURCE.apellido,
        TARGET.dni = SOURCE.dni,
        TARGET.direccion = SOURCE.direccion,
        TARGET.cargo = SOURCE.cargo,
        TARGET.turno = SOURCE.turno,
        TARGET.mailPersonal = SOURCE.emailPers,
        TARGET.mailEmpresa = SOURCE.emailEmp,
        TARGET.idSuc = SOURCE.nroSucursal
	WHEN NOT MATCHED THEN 
    INSERT (legajo, nombre, apellido, dni, direccion, cargo, turno, mailPersonal, mailEmpresa, idSuc)
    VALUES (SOURCE.legajo, SOURCE.nombre, SOURCE.apellido, SOURCE.dni, SOURCE.direccion, SOURCE.cargo, SOURCE.turno, SOURCE.emailPers, SOURCE.emailEmp, SOURCE.nroSucursal);

	DROP TABLE #tablaImportada;
END;
GO

--Ejecutar el procedimiento almacenado para importar los productos
--EXEC PROD.importarEmpleados 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';
--SELECT * FROM HR.Empleado;
--drop procedure PROD.importarEmpleados

--7) Importado de Ventas
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarVentas
	@ruta VARCHAR(MAX)
AS	
BEGIN
	CREATE TABLE #tablaImportada (
        idFactura VARCHAR(MAX),
        tipoFac VARCHAR(MAX),
        ciudad NVARCHAR(MAX),
        tipoCliente VARCHAR(MAX),
        genero VARCHAR(MAX),
        producto NVARCHAR(MAX),
        precioUnitario VARCHAR(MAX),
		cantidad VARCHAR(MAX),
		fecha VARCHAR(MAX),
		hora VARCHAR(MAX),
		medioDePago VARCHAR(MAX),
		empleado VARCHAR(MAX),
		regPago VARCHAR(MAX)
    );

	-- Usamos SQL dinamico para utilizar BULK INSERT con una ruta variable
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'BULK INSERT #tablaImportada FROM ''' + @ruta + ''' WITH (FIELDTERMINATOR = '';'', ROWTERMINATOR = ''0x0A'', FIRSTROW = 2, CODEPAGE = ''65001'');';
	EXEC sp_executesql @sql;

	-- Reemplazamos los caracteres incorrectos
	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ã¡', 'á')
	WHERE producto LIKE '%Ã¡%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ã©', 'é')
	WHERE producto LIKE '%Ã©%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ã³', 'ó')
	WHERE producto LIKE '%Ã³%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ãº', 'ú')
	WHERE producto LIKE '%Ãº%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'ÃƒÂº', 'ú')
	WHERE producto LIKE '%ÃƒÂº%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ã±', 'ñ')
	WHERE producto LIKE '%Ã±%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ã‘', 'Ñ')
	WHERE producto LIKE '%Ã‘%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ã­' , 'í')
	WHERE producto LIKE '%Ã%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Ã', 'Á')
	WHERE producto LIKE '%Ã%';

	UPDATE #tablaImportada
	SET producto = REPLACE(producto, 'Âº', 'º')
	WHERE producto LIKE '%Âº%';
	
	select * from #tablaImportada t


	/*
	INSERT INTO INV.Factura (idFactura, idProd, idSuc, idEmp, tipoFac, tipoCliente, genero, cantVendida, fecha, hora, regPago)
	SELECT 
		
	FROM #tablaImportada;
	*/
	
	DROP TABLE #tablaImportada;
END;
GO

--EXEC ImportadorDeArchivos.importarVentas 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Ventas_registradas.csv'
-- DROP PROCEDURE PROD.importarCatalogo;
-- DROP PROCEDURE INV.importarVentas;








