/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 15/11/2024
Entrega Final: Reportes XML
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Reporte completo en XML de "Reporte futuro"
ID Factura Tipo de FacturaCiudad Tipo de clienteGenero Linea de producto Producto Precio Unitario Cantidad Fecha hora Medio de Pago Empleado Sucursal

2) Reporte Mensual en XML
Pedido: Mensual: ingresando un mes y año determinado mostrar el total facturado por días de la semana, incluyendo sábado y domingo.

3) Reporte trimestral de los anteriores 3 meses a la fecha actual en XML
Pedido: mostrar el total facturado por turnos de trabajo por mes.

4) Reporte de Cantidad de Productos Vendidos Entre Dos Fechas dadas en XML
Pedido: Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango,
ordenado de mayor a menor.

5) Reporte de Cantidad de Productos Vendidos Entre Dos Fechas dadas por cada sucursal en XML
Pedido: Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese 
rango por sucursal, ordenado de mayor a menor.

No Resuelto: 6) Reporte de los 5 productos mas vendido para el mes de una fecha dada
Pedido: Mostrar los 5 productos más vendidos en un mes, por semana

7) Reporte de los 5 productos menos vendidos
Pedido: Mostrar los 5 productos menos vendidos en el mes.

8) Reporte de Total vendido para una fecha y sucursal dada
Pedido: Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha y sucursal particulares
*/

USE Com5600G10
GO

--1) Reporte completo a XML de "Reporte futuro"
CREATE OR ALTER PROCEDURE Reportes.VentasXML
AS
BEGIN
    -- Selección de datos en formato XML
    SELECT 
        f.nroFactura AS [ID_factura],
        f.tipoFac AS [Tipo_de_factura],
        s.ciudad AS Ciudad,
        c.tipoCliente AS [Tipo_de_cliente],
        c.genero AS Genero,
        p.lineaDeProducto AS [Linea_de_producto],
        p.nombreProd AS Producto,
        p.precioArs AS [Precio_Unitario],
        dv.cant AS Cantidad,
        f.fecha AS Fecha,
        f.hora AS Hora,
        e.legajo AS Empleado,
        s.localidad AS Sucursal
    FROM 
        INV.Factura f
    JOIN 
        INV.DetalleVenta dv ON f.nroFactura = dv.nroFactura
    JOIN 
        HR.Empleado e ON f.idEmp = e.legajo
    JOIN 
        HR.Sucursal s ON e.idSuc = s.nroSucursal
    JOIN 
        HR.Cliente c ON f.idCliente = c.idCliente
    JOIN 
        PROD.Producto p ON dv.idProducto = p.idProd
    ORDER BY 
        f.fecha, f.hora
    FOR XML AUTO, ELEMENTS, ROOT('ReporteVentas')
END;
GO


--2) Reporte Mensual en XML
CREATE OR ALTER PROCEDURE Reportes.MensualXML
    @Mes INT,
    @Anio INT
AS
BEGIN
	SET LANGUAGE Spanish; -- Cambio de idioma a español para que los dias de la semana se muestren en español

    SELECT 
        DATENAME(WEEKDAY, f.fecha) AS DiaSemana,
        SUM(dv.subTotal) AS TotalFacturado
    FROM 
        INV.Factura f
    JOIN 
        INV.DetalleVenta dv ON f.nroFactura = dv.nroFactura
    WHERE 
        MONTH(f.fecha) = @Mes
        AND YEAR(f.fecha) = @Anio
    GROUP BY 
        DATENAME(WEEKDAY, f.fecha) 

    FOR XML PATH('Dia'), ROOT('ReporteMensual');
END;
GO


--3) Reporte trimestral de los anteriores 3 meses a la fecha actual
CREATE OR ALTER PROCEDURE Reportes.UltimosTresMesesPorTurnosXML
AS
BEGIN
	SET LANGUAGE Spanish; -- Cambio de idioma a español para que los meses se muestren en español

	DECLARE @FechaActual DATE = '2019-04-10'; -- Fecha 2019 porque no hay reportes actuales de 2014 **eliminar**
    --DECLARE @FechaActual DATE = GETDATE(); -- Fecha hoy
    DECLARE @FechaInicio DATE = DATEADD(MONTH, -3, @FechaActual); -- Fecha de inicio de los ultimos tres meses

    -- Generar el reporte en XML con total facturado por mes y turno
    SELECT 
        DATENAME(MONTH, f.fecha) AS Mes,
        e.turno AS Turno,
        SUM(dv.subTotal) AS TotalFacturado
    FROM 
        INV.Factura f
    JOIN 
        INV.DetalleVenta dv ON f.nroFactura = dv.nroFactura
    JOIN
        HR.Empleado e ON f.idEmp = e.legajo
    WHERE 
        f.fecha >= @FechaInicio
        AND f.fecha <= @FechaActual
    GROUP BY 
        DATENAME(MONTH, f.fecha),
        e.turno
    ORDER BY 
        DATENAME(MONTH, f.fecha),
        e.turno
    FOR XML PATH('FacturaPorTurno'), ROOT('ReporteUltimosTresMesesPorTurnos');
END;
GO


--4) Reporte de Cantidad de Productos Vendidos Entre Dos Fechas dadas
CREATE OR ALTER PROCEDURE Reportes.CantidadProductosVendidosEntreDosFechasXML
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    -- cantidad de productos vendidos en el rango de fechas
    SELECT 
        p.nombreProd AS 'Producto',
        SUM(dv.cant) AS 'CantidadVendida'
    FROM 
        INV.DetalleVenta dv
    INNER JOIN 
        PROD.Producto p ON dv.idProducto = p.idProd
    INNER JOIN 
        INV.Factura f ON dv.nroFactura = f.nroFactura
    WHERE 
        f.fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY 
        p.nombreProd
    ORDER BY 
        SUM(dv.cant) DESC
    FOR XML PATH('ProductoVendido'), ROOT('ReporteProductosVendidos');
END;
GO


--5) Reporte de Cantidad de Productos Vendidos Entre Dos Fechas dadas por sucursal
CREATE OR ALTER PROCEDURE Reportes.ProductosVendidosPorSucursalEntreDosFechasXML
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SELECT 
        s.localidad AS 'Sucursal',
        SUM(dv.cant) AS 'CantidadTotalVendida'
    FROM 
        INV.DetalleVenta dv
    INNER JOIN 
        INV.Factura f ON dv.nroFactura = f.nroFactura
    INNER JOIN 
        HR.Empleado e ON f.idEmp = e.legajo
    INNER JOIN 
        HR.Sucursal s ON e.idSuc = s.nroSucursal -- Aquí se usa idSuc de Empleado
    WHERE 
        f.fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY 
        s.localidad
    ORDER BY 
        'CantidadTotalVendida' DESC
    FOR XML PATH('SucursalVendida'), ROOT('ReporteCantidadProductosVendidosPorSucursal');
END;
GO


--6) Reporte de los 5 productos mas vendido para el mes de una fecha dada


--7) Reporte de los cinco productos menos vendidos
CREATE OR ALTER PROCEDURE Reportes.ProductosMenosVendidosEnElMesXML
AS
BEGIN
 --   DECLARE @fechaHoy DATE = GETDATE();
    DECLARE @fechaHoy DATE = '2019-02-01';

    SELECT TOP 5
        p.nombreProd AS 'Producto',
        SUM(dv.cant) AS 'CantidadTotalVendida'
    FROM 
        INV.DetalleVenta dv
    INNER JOIN 
        INV.Factura f ON dv.nroFactura = f.nroFactura
    INNER JOIN 
        PROD.Producto p ON dv.idProducto = p.idProd
    WHERE 
        MONTH(f.fecha) = MONTH(@fechaHoy) AND YEAR(f.fecha) = YEAR(@fechaHoy)
    GROUP BY 
        p.nombreProd
    ORDER BY 
        SUM(dv.cant) ASC
    FOR XML PATH('ProductoMenosVendido'), ROOT('ReporteProductosMenosVendidos');
END;
GO

--8) 
CREATE OR ALTER PROCEDURE Reportes.TotalAcumuladoVentasParaUnaLocalidadYFechaXML
    @Fecha DATE,          -- Fecha de las ventas
    @Localidad VARCHAR(25)  -- Localidad de la sucursal
AS
BEGIN
    -- Busqueda de nroSucursal
    DECLARE @Sucursal INT;

    SELECT @Sucursal = nroSucursal
    FROM HR.Sucursal
    WHERE localidad = @Localidad;

    -- control de si existe la sucursal
    IF @Sucursal IS NULL
    BEGIN
        RAISERROR('Sucursal no encontrada para la localidad especificada.', 16, 1);
        RETURN;
    END

    -- 1. Detalle de ventas
    SELECT 
        p.nombreProd AS 'Producto',  -- Nombre del producto
        SUM(dv.cant) AS 'CantidadVendida',  -- Total de unidades vendidas
        SUM(dv.subTotal) AS 'Subtotal'  -- Total de facturacion
    FROM 
        INV.DetalleVenta dv
    INNER JOIN 
        INV.Factura f ON dv.nroFactura = f.nroFactura
    INNER JOIN 
        PROD.Producto p ON dv.idProducto = p.idProd
    INNER JOIN 
        HR.Empleado e ON f.idEmp = e.legajo
    INNER JOIN 
        HR.Sucursal s ON e.idSuc = s.nroSucursal
    WHERE 
        f.fecha = @Fecha  -- Filtro por la fecha dada
        AND s.nroSucursal = @Sucursal  -- Filtro por la sucursal dada
    GROUP BY 
        p.nombreProd
    ORDER BY 
        'Subtotal' DESC  -- Ordenamos por subtotal vendido
    FOR XML PATH('DetalleVenta'), ROOT('ReporteVentasPorLocalidadYFecha');

    -- 2. Total de ganancias
    SELECT 
        SUM(dv.subTotal) AS 'TotalDeGanancias'
    FROM 
        INV.DetalleVenta dv
    INNER JOIN 
        INV.Factura f ON dv.nroFactura = f.nroFactura
    INNER JOIN 
        HR.Empleado e ON f.idEmp = e.legajo
    INNER JOIN 
        HR.Sucursal s ON e.idSuc = s.nroSucursal
    WHERE 
        f.fecha = @Fecha  
        AND s.nroSucursal = @Sucursal;  
END;
GO
