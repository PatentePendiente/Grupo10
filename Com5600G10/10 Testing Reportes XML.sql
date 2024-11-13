/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 15/11/2024
Entrega Final: Testing de Reportes XML
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Test de Reportes.VentasXML
2) Test de Reportes.MensualXML
3) Test de Reportes.UltimosTresMesesPorTurnosXML
4) Test de Reportes.CantidadProductosVendidosEntreDosFechas
5) Test de Reportes.ProductosVendidosPorSucursalEntreDosFechas
6) No resuelto
7) Test de Reportes.ProductosMenosVendidosEnElMesXML
8) Test de Reportes.TotalAcumuladoVentasParaUnaLocalidadYFechaXML
*/

USE Com5600G10
GO

--1) Test de Reportes.VentasXML
-- Reporte de todas las ventas registradas
EXEC Reportes.VentasXML
GO

--2) Test de Reportes.MensualXML
-- Reporte de ventas del mes de Febrero de 2019
EXEC Reportes.MensualXML @Mes = 2, @Anio = 2019;
GO

--3) Test de Reportes.UltimosTresMesesPorTurnosXML
EXEC Reportes.UltimosTresMesesPorTurnosXML
GO

--4) Test de Reportes.CantidadProductosVendidosEntreDosFechas
-- Reporte de ventas desde inicio de 2019 hasta la mitad del año 2019
EXEC Reportes.CantidadProductosVendidosEntreDosFechasXML '2019-01-01', '2019-06-30';
GO

--5) Test de Reportes.ProductosVendidosPorSucursalEntreDosFechas
-- Reporte de ventas por sucursal desde inicio de 2019 hasta la mitad del año 2019
EXEC Reportes.ProductosVendidosPorSucursalEntreDosFechasXML '2019-01-01', '2019-06-30';
GO

/*
--6)
EXEC Reportes.ProductosMasVendidosPorSemanaDelMesXML @Fecha = '2019-01-01'
GO
*/

--7) productos menos vendidos 
-- Reporte de los 5 productos menos del mes se modifico el getFecha para que sea la fecha de '2019-02-01' y no la actual que
-- no registra ventas hechas por el momento
EXEC Reportes.ProductosMenosVendidosEnElMesXML;
GO


--8) total acumulado para una sucursal y fecha 
-- ventas hechas por la sucursal de San Justo en la fecha 2019-01-05
EXEC Reportes.TotalAcumuladoVentasParaUnaLocalidadYFechaXML '2019-01-05', 'San Justo';
GO



















