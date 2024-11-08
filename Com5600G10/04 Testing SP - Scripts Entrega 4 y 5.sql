/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 4 Insercion de Tablas
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

Asunto: Testing de Importacion de archivos
*/

USE Com5600G10
GO

--1) Api de Dolar
-- Ejecutar la consulta de precio Dolar
EXEC ImportadorDeArchivos.consultarDolarAPI;
GO
-- DROP PROCEDURE ImportadorDeArchivos.consultarDolarAPI;



--2) Importado de Productos_importados.xlsx
-- Ejecutar el procedimiento almacenado para importar los productos
EXEC ImportadorDeArchivos.importarProductosImportados 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\Productos_importados.xlsx';
GO
--SELECT * FROM PROD.Producto;
-- DROP PROCEDURE ImportadorDeArchivos.importarProductosImportados;


--3) Importado de Sucursales
-- Ejecutar el procedimiento almacenado para importar las sucursales
EXEC ImportadorDeArchivos.importarSucursales 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';
GO
--SELECT * FROM HR.Sucursal;
-- DROP PROCEDURE ImportadorDeArchivos.importarSucursales;


--4) Carga de Catalogo.csv
-- Ejecutar el procedimiento almacenado para importar el catálogo
EXEC ImportadorDeArchivos.importarCatalogo 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\catalogo.csv';
GO
--select * from PROD.Producto

--DROP PROCEDURE PROD.importarCatalogo;

--5) Importado de Productos_importados.xlsx
-- Ejecutar el procedimiento almacenado para importar los productos
EXEC ImportadorDeArchivos.importarProductosAccesoriosElectronicos 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\Electronic accessories.xlsx';
GO
--SELECT * FROM PROD.Producto;

--drop procedure PROD.importarProductosAccesoriosElectronicos



--6) Importado de Productos_importados.xlsx
--Ejecutar el procedimiento almacenado para importar los productos
EXEC ImportadorDeArchivos.importarEmpleados 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';
GO
--SELECT * FROM HR.Empleado;

--drop procedure PROD.importarEmpleados


--7) Importado de Ventas
EXEC ImportadorDeArchivos.importarVentas 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Ventas_registradas.csv'
-- DROP PROCEDURE PROD.importarCatalogo;
-- DROP PROCEDURE INV.importarVentas;









