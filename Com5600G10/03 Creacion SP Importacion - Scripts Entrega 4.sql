/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 4 Insercion de Tablas
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

INDICE: 
1) Importado de Productos_importados.xlsx
2) Importado de Sucursales
3) Importado de Catalogo.csv
4) Importado de Electronic accessories.xlsx
5) Importado de Empleados
6) Importado de Ventas
*/

USE Com5600G10
GO

--1) Importado de Productos_importados.xlsx
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarProductosImportados
	@ruta VARCHAR(MAX)
AS
BEGIN

	CREATE TABLE #tablaImportada (
		idProducto VARCHAR(MAX),
		nombreProducto VARCHAR(MAX),
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
    FROM #tablaImportada
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


--2) Importado de Sucursales
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarSucursales
	@ruta VARCHAR(MAX)
AS
BEGIN

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


--3) Carga de Catalogo.csv
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarCatalogo
    @ruta VARCHAR(MAX)
AS
BEGIN
    -- creamos la tabla temporal donde se van a guardar los datos del archivo csv
    CREATE TABLE #tablaImportada (
        id VARCHAR(MAX),
        categoria VARCHAR(MAX),
        nombre VARCHAR(MAX),
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


--4) Importado de Productos_importados.xlsx
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarProductosAccesoriosElectronicos
	@ruta VARCHAR(MAX)
AS
BEGIN

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


--5) Importado de Empleados
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.importarEmpleados
	@ruta VARCHAR(MAX)
AS
BEGIN

	--Legajo/ID	Nombre	Apellido	DNI  direccion email personal	email empresa	CUIL	Cargo	Sucursal	Turno
	CREATE TABLE #tablaImportada (
		legajo VARCHAR(MAX),
		nombre VARCHAR(MAX),
		apellido VARCHAR(MAX),
		--Tuve problemas para leer el documento del excel con un varchar, ya que excel maneja numeros grandes como el del
		-- documento de 10.000.000 como numeros flotantes, use decimal y lo lei directamente para luego castearlo a entero
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

--6) Importado de Ventas
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
		regPago VARCHAR(MAX),
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
	SET producto = REPLACE(producto, 'Âº', 'º')
	WHERE producto LIKE '%Âº%';


	--Control de que el legajo del empleado que realizo la venta exista
	DELETE FROM #tablaImportada
	WHERE NOT EXISTS(
		SELECT 1
		FROM HR.Empleado e
		WHERE e.legajo = #tablaImportada.empleado
	)

	--busqueda de id de sucursal 
	ALTER TABLE #tablaImportada
	ADD idSucursal INT;

	UPDATE #tablaImportada
	SET #tablaImportada.idSucursal = s.nroSucursal
	FROM #tablaImportada
	INNER JOIN HR.Sucursal s ON s.ciudad = #tablaImportada.ciudad;
	
	--busqueda de id del tipo de cliente 
	ALTER TABLE #tablaImportada
	ADD idCliente INT;

	-- Obtener el idCliente de la tabla HR.Cliente basado en tipoCliente y genero
	UPDATE #tablaImportada
	SET idCliente = c.idCliente
	FROM #tablaImportada ti
	INNER JOIN HR.Cliente c 
    ON CAST(c.tipoCliente AS VARCHAR(6)) = CAST(ti.tipoCliente AS VARCHAR(6)) 
    AND CAST(c.genero AS VARCHAR(6)) = CAST(ti.genero AS VARCHAR(6));
	
	INSERT INTO INV.Factura (idFactura, idEmp, idCliente, tipoFac, fecha, hora, regPago)
	SELECT 
	ti.idFactura, ti.empleado, ti.idCliente, ti.tipoFac, ti.fecha, ti.hora, 
	CAST(ti.regPago AS VARCHAR(22))
	FROM #tablaImportada ti
	WHERE NOT EXISTS (
    SELECT 1
    FROM INV.Factura f
    WHERE f.idFactura = CAST(ti.idFactura AS CHAR(11))
	);

	--Registro de detalle de ventas asociadas al id de factura y al del producto:
	--busqueda de id de producto 
	ALTER TABLE #tablaImportada
	ADD idProducto INT;
	
	UPDATE #tablaImportada
	SET #tablaImportada.idProducto = p.idProd
	FROM #tablaImportada
	INNER JOIN PROD.Producto p ON p.nombreProd = #tablaImportada.producto;

	--busco el id que genero nuestro sistema para la factura
	ALTER TABLE #tablaImportada
	ADD nroFacturacionSistema BIGINT;
	
	UPDATE #tablaImportada
	SET #tablaImportada.nroFacturacionSistema = f.nroFactura
	FROM #tablaImportada
	INNER JOIN INV.Factura f ON f.idFactura = #tablaImportada.idFactura;

	--Registro de detalle de ventas y para evitar duplicados de detalles de ventas
	INSERT INTO INV.DetalleVenta(idProducto, nroFactura, subTotal, cant, precio)
	SELECT tt.idProducto,
    nroFacturacionSistema,
	CAST(tt.precioUnitario AS DECIMAL(6,2)) * CAST(tt.cantidad AS INT) AS subTotal,
    CAST(tt.cantidad AS INT),
    CAST(tt.precioUnitario AS DECIMAL(6,2))
	FROM #tablaImportada tt
	WHERE 
	idProducto IS NOT NULL AND
    NOT EXISTS (
        SELECT 1 
        FROM INV.DetalleVenta dv
        WHERE dv.nroFactura = nroFacturacionSistema
          AND dv.idProducto = tt.idProducto 
    );
	
	DROP TABLE #tablaImportada;
END;
GO




