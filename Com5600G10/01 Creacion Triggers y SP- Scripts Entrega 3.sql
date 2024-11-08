/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 4 Insercion de Tablas
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MAMANI ESTRADA, LUCAS GABRIEL  --
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

FALTA:
trigger delete emp
trigger delete prod

INDICE: 




*/

USE Com5600G10
GO


select * from INV.DetalleVenta 
select * from INV.Factura
select * from PROD.Producto
select * from HR.sucursal
select * from HR.sucursal

drop table INV.DetalleVenta
drop table INV.Factura
drop table HR.Empleado
drop table HR.Sucursal
drop table PROD.Producto

select * from INV.DetalleVenta v
INNER JOIN INV.Factura f ON f.idFactura = v.idFactura