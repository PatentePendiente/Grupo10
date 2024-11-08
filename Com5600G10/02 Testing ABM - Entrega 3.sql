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
1) Test de SP Api de Dolar
2) Test de SP insercion individual y control de duplicados del SP ImportadorDeArchivos.InsertarProducto
3) Test de SP insercion individual y control de duplicados de factura del SP ImportadorDeArchivos.InsertarFactura
*/

--1) Api de Dolar
-- Ejecutar la consulta de precio Dolar
EXEC ImportadorDeArchivos.consultarDolarAPI;
GO


--2) Test de insercion individual y control de duplicados de producto
--Inserta un producto prueba
EXEC ImportadorDeArchivos.InsertarProducto 
    @lineaDeProducto = 'testLineaProducto',
    @nombreProd = 'productoDeTest',
    @precioArs = 0,
    @precioUsd = 200,
    @unidadRef = '1 unidad';
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



--3) Test de insercion individual y control de duplicados de factura
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






















