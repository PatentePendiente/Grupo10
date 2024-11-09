/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 3 Testing de SP
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

Asunto: Testing de Importacion de archivos
INDICE:
1) Ejecucion de SP para consultar Api
2) Ejecucion de SP para insercion de los 4 tipos de clientes
3) Test de SP para el borrado logico de producto
4) Test de SP para el borrado logico de empleado
3) Test de SP insercion individual y control de duplicados del SP ImportadorDeArchivos.InsertarProducto
4) Test de SP insercion individual y control de duplicados de factura del SP ImportadorDeArchivos.InsertarFactura
*/

--1) Api de Dolar
-- Ejecutar la consulta de precio Dolar
EXEC ImportadorDeArchivos.consultarDolarAPI;
GO

--2) Ejecucion de SP para insercion de los 4 tipos de clientes
EXEC DBA.InsertarClientes
GO

SELECT * FROM HR.Cliente
GO

--3) Test de SP para el borrado logico de producto
--Inserto producto test para ser borrado
IF NOT EXISTS (SELECT 1 FROM Prod.Producto WHERE nombreProd = 'Coca cola expirada')
BEGIN
    INSERT INTO Prod.Producto (lineaDeProducto, nombreProd)
    VALUES ('Producto de Test', 'Coca cola expirada');
END
GO
--producto antes del borrado
SELECT * FROM PROD.Producto p
where p.nombreProd = 'Coca cola expirada';
GO

--borrado
EXEC ImportadorDeArchivos.BorrarProducto 'Coca cola expirada'
GO

--producto post borrado
SELECT * FROM PROD.Producto p
where p.nombreProd = 'Coca cola expirada';
GO

--4) Test de SP para el borrado logico de empleado
--insercion sucursal de test
DECLARE @idSucursal INT;

IF NOT EXISTS (SELECT 1 FROM HR.Sucursal WHERE ciudad = 'test')
BEGIN
    INSERT INTO HR.Sucursal (ciudad, localidad)
    VALUES ('test', 'sucursal para testeo');

    -- Obtener el idSuc recien generado
    SET @idSucursal = SCOPE_IDENTITY();
END
ELSE
BEGIN
    -- Si la sucursal ya existe, obtener el idSuc de la sucursal 'test'
    SELECT @idSucursal = nroSucursal
    FROM HR.Sucursal
    WHERE ciudad = 'test';
END;

--insercion de empleado test
IF NOT EXISTS (SELECT 1 FROM HR.Empleado WHERE legajo = 1234)
BEGIN
    INSERT INTO HR.Empleado (legajo, dni, idSuc,nombre)
    VALUES (1234, 45129672, @idSucursal,'Empleado de Test de borrado');
END;
GO

-- Ver el estado del empleado antes del borrado
SELECT * FROM HR.Empleado
WHERE legajo = 1234
GO

-- Ejecutar el procedimiento de borrado lógico para el empleado con legajo 1234
EXEC ImportadorDeArchivos.BorrarEmpleado 1234;
GO

-- Ver el estado del empleado después del borrado
SELECT * FROM HR.Empleado
WHERE legajo = 1234;
GO


--5) Test de insercion individual y control de duplicados de producto
--Inserta un producto prueba
EXEC ImportadorDeArchivos.InsertarProducto 
    @lineaDeProducto = 'testLineaProducto',
    @nombreProd = 'productoDeTest',
    @precioArs = 0,
    @precioUsd = 200,
    @unidadRef = '1 unidad';
GO

--traigo todos los ids de producto y compruebo que me muestre un unico registro
SELECT * FROM PROD.Producto
WHERE nombreProd = 'productoDeTest'
GO

--Inserta nuevamente el producto y se controla que no duplique producto y que solo lo actualice
EXEC ImportadorDeArchivos.InsertarProducto 
    @lineaDeProducto = 'testLineaProducto',
    @nombreProd = 'productoDeTest',
    @precioArs = 0,
    @precioUsd = 270,
    @unidadRef = '1 unidad';
GO

--traigo todos los ids de producto y compruebo que me muestre un unico registro
SELECT * FROM PROD.Producto
WHERE nombreProd = 'productoDeTest'
GO


/*
--6) Test de insercion individual y control de duplicados de factura
--inserto factura test
EXEC ImportadorDeArchivos.InsertarFactura
    @idFactura = '000-00-0000',     
    @legajoEmp = 257020,                  
    @tipoFac = 'A',                
    @tipoCliente = 'test',         
    @genero = 'Female'
GO

--intento insertar nuevamente para probar duplicado
EXEC ImportadorDeArchivos.InsertarFactura
    @idFactura = '000-00-0000',     
    @legajoEmp = 257020,                  
    @tipoFac = 'A',                
    @tipoCliente = 'test',         
    @genero = 'Female'
GO

--traigo todos los ids de factura y compruebo que me muestre un unico registro
SELECT * FROM INV.Factura
WHERE idFactura = '000-00-0000'
GO


*/



















