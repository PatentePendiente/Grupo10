/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 - Testing de SP de encriptacion
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 

*/

USE Com5600G10
GO

-- 1) Tratamos de crear una nota de credito con un usuario que no tiene los permisos para hacerlo
EXEC AS USER = 'UsuarioCaja';
EXEC INV.crearNotaCredito 1, 3462, 'P';
REVERT;
-- Deberiamos obtener un error


-- 2) Con el usuario del supervisor, tratamos de crear una nota de credito de una factura que no existe
EXEC AS USER = 'SupervisorUser';
EXEC INV.crearNotaCredito -1, 3462, 'P';
REVERT;
-- Deberiamos obtener un error


-- 3) Con el usuario del supervisor, tratamos de crear una nota de credito de un producto que no esta asociada a la factura
EXEC AS USER = 'SupervisorUser';
EXEC INV.crearNotaCredito 1, 1304, 'P';
REVERT;
-- Deberiamos obtener un error


-- 4) Con el usuario del supervisor, creamos una nota de credito valida
EXEC AS USER = 'SupervisorUser';
EXEC INV.crearNotaCredito 1, 3462, 'P';
REVERT;

SELECT * FROM INV.NotaCredito;
-- Se deberia de crear correctamente la nota de credito


-- 5) Tratamos de crear una nota de credito de una factura que este pendiente de pago

-- Primero, con el usuario del cajero, creamos una factura que este pendiente de pago
EXEC AS USER = 'UsuarioCaja';
EXEC Cajero.AgregarDetalleVenta '34in Ultrawide Monitor', 1, 257020; -- Agregamos un producto
EXEC Cajero.ConfirmarVenta 257020; -- Creamos la factura, por default se crea como pendiente de pago
REVERT;

-- Ahora, con el usuario del supervisor, tratamos de crear la nota de credito
DECLARE @ultimaFactura INT;
SELECT @ultimaFactura = MAX(nroFactura) FROM INV.Factura;

EXEC AS USER = 'SupervisorUser';
EXEC INV.crearNotaCredito @ultimaFactura, 3462, 'P';
REVERT;
-- Se deberia obtener un error


SELECT * FROM PROD.Producto
WHERE nombreProd = '34in Ultrawide Monitor';








EXEC AS USER = 'SupervisorUser';



SELECT * FROM INV.Factura;
SELECT * FROM INV.DetalleVenta;



























