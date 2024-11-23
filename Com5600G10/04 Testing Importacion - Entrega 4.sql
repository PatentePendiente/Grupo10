/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 4 Insercion de Tablas
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

Asunto: Testing de Importacion de archivos

INDICE:
Ejecucion Intermedia de DBA.InsertarClientes
1) Ejecucion de ImportadorDeArchivos.importarSucursales
2) Ejecucion de ImportadorDeArchivos.importarEmpleados
3) Ejecucion de ImportadorDeArchivos.importarProductosImportados
4) Ejecucion de ImportadorDeArchivos.importarCatalogo
5) Ejecucion de ImportadorDeArchivos.importarProductosAccesoriosElectronicos
6) Ejecucion de ImportadorDeArchivos.importarVentas
*/

USE Com5600G10
GO

--/--

SELECT * FROM HR.Cliente
GO
--2) Ejecucion de SP para insercion de los 4 tipos de clientes
EXEC DBA.InsertarClientes
GO

SELECT * FROM HR.Cliente
GO

--/--

--1) Importado de Sucursales
SELECT * FROM HR.Sucursal -- SE MUESTRA VACIA
GO

EXEC ImportadorDeArchivos.importarSucursales 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';
GO

SELECT * FROM HR.Sucursal --SE MUESTRA LLENA
GO

--/--

--2) Importado de Empleados
SELECT * FROM HR.Empleado -- SE MUESTRA VACIA
GO

EXEC ImportadorDeArchivos.importarEmpleados 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';
GO

SELECT * FROM HR.Empleado -- SE MUESTRA VACIA
GO

--/--

SELECT * FROM PROD.Producto -- SE MUESTRA VACIA
GO

--3) Importado de Productos_importados.xlsx
EXEC ImportadorDeArchivos.importarProductosImportados 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\Productos_importados.xlsx';
GO

--4) Carga de Catalogo.csv
EXEC ImportadorDeArchivos.importarCatalogo 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\catalogo.csv';
GO

--5) Importado de Productos_importados.xlsx
EXEC ImportadorDeArchivos.importarProductosAccesoriosElectronicos 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Productos\Electronic accessories.xlsx';
GO

SELECT * FROM PROD.Producto -- SE MUESTRA LLENA
GO

--/--
SELECT * FROM INV.Factura -- SE MUESTRA VACIA
GO

SELECT * FROM INV.DetalleVenta -- SE MUESTRA VACIA
GO

--6) Importado de Ventas
EXEC ImportadorDeArchivos.importarVentas 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Ventas_registradas.csv'
GO

SELECT * FROM INV.Factura -- SE MUESTRA LLENA
GO

SELECT * FROM INV.DetalleVenta -- SE MUESTRA LLENA
GO

--SE VUELVE A EJECUTAR PARA VER Y CONTROLAR QUE NO SE DUPLIQUEN ARCHIVOS
--7) Importado de Ventas
EXEC ImportadorDeArchivos.importarVentas 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Ventas_registradas.csv'
GO

SELECT * FROM INV.Factura -- SE MUESTRA LLENA Y SIN DUPLICADOS
GO

SELECT * FROM INV.DetalleVenta -- SE MUESTRA LLENA Y SIN DUPLICADOS
GO






