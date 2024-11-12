/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 3 Testing de SP ABM
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
5) Test de insercion individual y control de duplicados de producto

Nota: Para que ejecutar estos test hay que ejecutar 03 e importar los productos
porque utilizo productos del catalogo como testing
6) Test de crear detalles de venta y luego confirmar la venta
7) Test de crear detalles de venta y luego cancelar la venta


TEST QUE DEBERIAN PRODUCIR FALLO:
8) Producto que no existe
9) Empleado no registrado en el sistema
*/


--1) Api de Dolar
-- Ejecutar la consulta de precio Dolar
DECLARE @valorDolarVenta DECIMAL(6,2);
EXEC ImportadorDeArchivos.consultarDolarAPI @valorDolarVenta OUT;
PRINT 'DOLAR COMPRA: ' + CAST(@valorDolarVenta AS VARCHAR);

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



/****** TESTING DE FACTURACIONES  CON CONFIRMACION******/
--6) Test de crear detalles de venta y luego confirmar la venta
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

--venta de producto dolarizado
--5618	Accesorio electronic	34in Ultrawide Monitor	0.00	379.99	1 unidad
EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = '34in Ultrawide Monitor', 
    @cantidadEnGr = 1,
    @legajoCajero = 1234;
GO

--venta de producto en gramos para ver la conversion
--1641	te_e_infusiones	Infusión Tila Hacendado	0.50	0.00	100 g	NULL
EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = 'Infusión Tila Hacendado', 
    @cantidadEnGr = 250, --250gr
    @legajoCajero = 1234;
GO

--venta de producto en kg para ver la conversion
--1211	harina_y_preparado_reposteria	Harina de trigo Hacendado	0.43	0.00	kg	NULL
EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = 'Harina de trigo Hacendado', 
    @cantidadEnGr = 1500, --1500gr
    @legajoCajero = 1234;
GO

--ver como una unica factura
SELECT * FROM INV.Factura
WHERE regPago = 'falta confirmacion'
GO
--ver los detalles de ventas asociados a la factura
SELECT dv.*, f.*
FROM INV.DetalleVenta dv
JOIN INV.Factura f ON dv.nroFactura = f.nroFactura
WHERE f.regPago = 'falta confirmacion' AND f.idEmp = 1234;
GO

--confirmacion de venta
EXEC Cajero.ConfirmarVenta 1234
GO

--ver como quedo la factura confirmada
SELECT * FROM INV.Factura
WHERE regPago = 'pendiente de pago'
GO
--ver los detalles de ventas asociados a la factura confirmada
SELECT dv.*, f.*
FROM INV.DetalleVenta dv
JOIN INV.Factura f ON dv.nroFactura = f.nroFactura
WHERE f.regPago = 'pendiente de pago' AND f.idEmp = 1234;
GO


--limpiar registros:
delete from INV.DetalleVenta
where nroFactura IN(
SELECT dv.nroFactura
FROM INV.DetalleVenta dv
JOIN INV.Factura f ON dv.nroFactura = f.nroFactura
WHERE f.regPago = 'pendiente de pago' AND f.idEmp = 1234
)
GO

--eliminar las facturas test finalmente:
delete from INV.Factura
where regPago = 'pendiente de pago' AND idEmp = 1234
GO
/****** TESTING DE FACTURACIONES CON CONFIRMACION EJECUTAR HASTA ACA******/






/****** TESTING DE FACTURACIONES CON CANCELACION******/
--7) Test de crear detalles de venta y luego cancelar la venta
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

EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = '34in Ultrawide Monitor', 
    @cantidadEnGr = 1,
    @legajoCajero = 1234;
GO

EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = 'Infusión Tila Hacendado', 
    @cantidadEnGr = 250, --250gr
    @legajoCajero = 1234;
GO

EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = 'Harina de trigo Hacendado', 
    @cantidadEnGr = 1500, --1500gr
    @legajoCajero = 1234;
GO

--ver como una unica factura
SELECT * FROM INV.Factura
WHERE regPago = 'falta confirmacion'
GO
--ver los detalles de ventas asociados a la factura
SELECT dv.*, f.*
FROM INV.DetalleVenta dv
JOIN INV.Factura f ON dv.nroFactura = f.nroFactura
WHERE f.regPago = 'falta confirmacion' AND f.idEmp = 1234;
GO

--cancelacion de venta
EXEC Cajero.CancelarVenta 1234
GO

--ver como se eliminaron la facturas
SELECT * FROM INV.Factura
WHERE regPago = 'pendiente de pago'
GO
--ver como se eliminaron los detalles de ventas asociados a la factura cancelada
SELECT dv.*, f.*
FROM INV.DetalleVenta dv
JOIN INV.Factura f ON dv.nroFactura = f.nroFactura
WHERE f.regPago = 'pendiente de pago' AND f.idEmp = 1234;
GO
/****** TESTING DE FACTURACIONES CON CANLACION EJECUTAR HASTA ACA******/





/****** TEST QUE DEBERIAN PRODUCIR UN FALLO ******/
/* Preparar escenario creando la sucursal y empleado para los test*/
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



--8) Producto que no existe
--Insertar producto que no existe y ver que se produzca el fallo
EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = 'producto de fallo', 
    @cantidadEnGr = 1,
    @legajoCajero = 1234;
GO

--ERROR que muestra: Producto no registrado: producto de fallo

--9) Empleado no registrado en el sistema
--Insertar legajo que no existe y ver que se produzca el fallo
EXEC Cajero.AgregarDetalleVenta
    @nombreProducto = 'Harina de trigo Hacendado', 
    @cantidadEnGr = 1500, --1500gr
    @legajoCajero = 1122; --legajo que no existe
GO
--ERROR que muestra: El legajo del cajero 1122 no se encuentra registrado



--Por ultimo eliminar los registros de testing:
DELETE FROM HR.Empleado 
WHERE legajo = 1234;
GO

DELETE FROM HR.Sucursal
WHERE ciudad = 'test'
GO

DELETE FROM PROD.Producto
WHERE lineaDeProducto = 'Producto de Test'
GO











