/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 - Testing de SP de encriptacion
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Ver Users
2) Test del Usuario: Importador de Archivos
3) Test del Usuario: ReportesXML
4) Test del Usuario: Cajero
5) Test del Usuario: Supervisor y de INV.crearNotaCredito
*/

USE Com5600G10
GO

--1) Ver Users
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp.authentication_type_desc AS AuthenticationType
FROM 
    sys.database_principals dp
WHERE 
    dp.type IN ('S', 'U', 'G') -- 'S' = SQL User, 'U' = Windows User, 'G' = Windows Group
ORDER BY 
    dp.name;
GO

/*
--2) Test del Usuario: Importador de Archivos
EXECUTE AS USER = 'UsuarioImportador';
SELECT USER_NAME() AS UsuarioActual;
GO

revert


-- Ejecucion de un sp que si puede
BEGIN TRY
    PRINT 'El procedimiento ImportadorDeArchivos.importarVentas fue ejecutado correctamente por el UsuarioImportador';
	EXEC ImportadorDeArchivos.importarVentas 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Ventas_registradas.csv';
END TRY
BEGIN CATCH
    PRINT 'Error al ejecutar ImportadorDeArchivos.importarVentas: ' + ERROR_MESSAGE();
END CATCH;
GO

/*
-- Ejecucion de un sp que tiene permisos
BEGIN TRY
    EXEC ImportadorDeArchivos.procedimientoNoPermitido; -- Suponiendo que este procedimiento no debe existir o no debe ser ejecutado por el usuario
    PRINT 'El procedimiento ImportadorDeArchivos.procedimientoNoPermitido fue ejecutado correctamente, lo cual no es esperado';
END TRY
BEGIN CATCH
    PRINT 'Error al ejecutar ImportadorDeArchivos.procedimientoNoPermitido (como se esperaba): ' + ERROR_MESSAGE();
END CATCH;
GO*/

REVERT;
*/


--3) Test del Usuario: ReportesXML
EXECUTE AS USER = 'UsuarioReportes';
SELECT USER_NAME() AS UsuarioActual;
GO

--Verificacion de que se tiene acceso a los reportes
EXEC Reportes.VentasXML;
EXEC Reportes.ProductosMasVendidosPorSemanaEnElMesXML 2, 2019


--Test que deberia de fallar: verificacion de que el cajero no pueda acceder a otros SP
EXEC ImportadorDeArchivos.importarEmpleados;
EXEC Cajero.ConfirmarVenta 111, 100;

REVERT



--4) Test del Usuario: Cajero
EXECUTE AS USER = 'UsuarioCaja';
SELECT USER_NAME() AS UsuarioActual;
GO

--Verificacion de que se tenga acceso a crear detalle de venta y luego cancelar la venta
EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = 'Harina de trigo Hacendado', 
    @cantidadEnGr = 1500, --1500gr
    @legajoCajero = 257020;
GO

--cancelacion de venta
EXEC Cajero.CancelarVenta 257020
GO

--Test que deberia de fallar: Verificacion de que no se tenga acceso a otros sp
EXEC Reportes.MensualXML;

REVERT
SELECT USER_NAME() AS UsuarioActual;



--5) Test de INV.crearNotaCredito para valor de producto
EXECUTE AS USER = 'UsuarioSupervisor';
SELECT USER_NAME() AS UsuarioActual;
GO

--Verificacion de que se tenga acceso a crear nota de credito
EXEC INV.crearNotaCredito 280, 1780, 'V';

REVERT
SELECT USER_NAME() AS UsuarioActual;


--Ver la creacion de nota de credito
SELECT * FROM INV.NotaCredito

--Eliminar nota de credito de test
DELETE FROM INV.NotaCredito
WHERE idNotaCredito > 0


--TEST QUE DEBERIAN PRODUCIR UN FALLO:
-- tipo de nota que no sea "P" o "V"
EXEC AS USER = 'UsuarioSupervisor';
EXEC INV.crearNotaCredito 280, 1780, 'X';
REVERT;

-- tratamos de crear una nota de credito de una factura que no existe
EXEC AS USER = 'UsuarioSupervisor';
EXEC INV.crearNotaCredito -1, 3462, 'P';
REVERT;

-- tratamos de crear una nota de credito de un producto que no esta asociada a la factura ingresada
EXEC AS USER = 'UsuarioSupervisor';
EXEC INV.crearNotaCredito 1, 1304, 'P';
REVERT;


-- EJECUTAR DESDE ACA
-- Tratamos de crear una nota de credito de una factura que este pendiente de pago
-- Primero, con el usuario del cajero, creamos una factura que este en estado pendiente de pago
EXEC AS USER = 'UsuarioCaja';
EXEC Cajero.AgregarDetalleVenta '34in Ultrawide Monitor', 1, 257020; -- Agregamos un producto
EXEC Cajero.ConfirmarVenta 257020; -- Creamos la factura, por default se crea como no pendiente de pago
REVERT;

-- tratamos de crear la nota de credito
DECLARE @ultimaFactura INT;
SELECT @ultimaFactura = MAX(nroFactura) FROM INV.Factura;

EXEC AS USER = 'UsuarioSupervisor';
EXEC INV.crearNotaCredito @ultimaFactura, 3462, 'P';
REVERT;

-- por ultimo elminamos el registro de test de facturas y detalles de venta
DELETE dv FROM INV.DetalleVenta dv
INNER JOIN INV.Factura f ON dv.nroFactura = f.nroFactura
WHERE f.regPago = 'pendiente de pago'
GO

DELETE FROM INV.Factura
WHERE regPago = 'pendiente de pago'
GO
-- EJECUTAR HASTA ACA













