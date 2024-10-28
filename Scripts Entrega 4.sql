USE Com5600G10
GO


CREATE PROCEDURE PROD.consultarDolarAPI
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

EXEC PROD.consultarDolarAPI;

-- DROP PROCEDURE PROD.consultarDolarAPI;






CREATE PROCEDURE PROD.importarProductosImportados
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
    EXEC sp_executesql @sql;

	INSERT INTO PROD.Producto(lineaDeProducto, nombreProd, precioUsd, unidad)
	SELECT categoria, nombreProducto, CAST(precioUnidad AS DECIMAL(6,2)), 0
	FROM #tablaImportada;

	DROP TABLE #tablaImportada;
END;

-- Ejecutar el procedimiento almacenado para importar los productos
EXEC PROD.importarProductosImportados 'C:\Users\JuanD\OneDrive\Escritorio\bbdda\Productos_importados.xlsx';
SELECT * FROM PROD.Producto;
-- DROP PROCEDURE PROD.importarProductosImportados;






CREATE PROCEDURE HR.importarSucursales
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

	-- Insertamos las columnas que no interesan en la tabla final
	INSERT INTO HR.Sucursal (ciudad, localidad)
	SELECT ciudad, reemplazarPor
	FROM #tablaImportada;

    -- Eliminamos la tabla temporal después de la importación
    DROP TABLE #tablaImportada;
END;

-- Ejecutar el procedimiento almacenado para importar las sucursales
EXEC HR.importarSucursales 'C:\Users\JuanD\OneDrive\Escritorio\bbdda\Informacion_complementaria.xlsx';
SELECT * FROM HR.Sucursal;
-- DROP PROCEDURE HR.importarSucursales;









CREATE PROCEDURE PROD.importarCatalogo
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

	INSERT INTO PROD.Producto (lineaDeProducto, PrecioUsd, unidad, nombreProd)
	SELECT categoria, CAST(precio AS DECIMAL(6,2)), 0, nombre
	FROM #tablaImportada;

	DROP TABLE #tablaImportada;
	
END;

-- Ejecutar el procedimiento almacenado para importar el catálogo
EXEC PROD.importarCatalogo 'C:\Users\JuanD\OneDrive\Escritorio\bbdda\catalogo.csv';

-- DROP PROCEDURE PROD.importarCatalogo;






-- SP para obtener el id de un producto por medio de su nombre
CREATE PROCEDURE PROD.obtenerIdProducto
    @nombreProducto NVARCHAR(MAX),
	@idProducto INT OUTPUT
AS
BEGIN
    SET @idProducto = (SELECT idProd
					   FROM PROD.Producto
					   WHERE nombreProd = @nombreProducto);
END;

DECLARE @idProd INT;
EXEC PROD.obtenerIDProducto 'Langostinos tigre Carnarvon', @idProd OUTPUT;
PRINT @idProd;

-- DROP PROCEDURE PROD.obtenerIDProducto;




CREATE PROCEDURE INV.importarVentas
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
	
	/*
	INSERT INTO INV.Factura (idFactura, idProd, idSuc, idEmp, tipoFac, tipoCliente, genero, cantVendida, fecha, hora, regPago)
	SELECT 
		
	FROM #tablaImportada;
	*/

	DROP TABLE #tablaImportada;
END;

EXEC INV.importarVentas 'C:\Users\JuanD\OneDrive\Escritorio\bbdda\Ventas_registradas.csv'

-- DROP PROCEDURE PROD.importarCatalogo;
-- DROP PROCEDURE INV.importarVentas;
