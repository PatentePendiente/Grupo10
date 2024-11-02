/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 3 Creacion de Tablas
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MAMANI ESTRADA, LUCAS GABRIEL  --
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978

INDICE: 
Creacion de Schemas:
1) HR
2) INV
3) PROD
4) ImportadorDeArchivos
5) Reportes

Creacion de Tablas:
1) Tabla Sucursal
2) Tabla Producto
3) Tabla Empleado
4) Tabla LineaProducto
5) Tabla Factura
 
agregar schema de exportadorDeArchivos para el trismestral y anual
*/

--Creacion de bd:
IF not exists(
	SELECT NAME FROM sys.databases
	WHERE NAME = 'Com5600G10'
)
CREATE DATABASE Com5600G10;
ELSE
PRINT 'La base de datos Com5600G10 ya existe';
GO

USE Com5600G10
GO

-- modulo de creacion de esquemas: HR(Sucursal y Empleado), 
-- INV(Facturacion) y PROD(Producto, Catalogo)
--1) Esquema HR
IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'HR'
)
	EXEC('CREATE SCHEMA HR');
ELSE
    PRINT 'El esquema HR ya existe.';
GO
--2) Esquema INV
IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'INV'
)
	EXEC('CREATE SCHEMA INV');
ELSE
    PRINT 'El esquema INV ya existe.';
GO
--3) Esquema PROD
IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'PROD'
)
	EXEC('CREATE SCHEMA PROD');
ELSE
    PRINT 'El esquema PROD ya existe.';
GO
--4) Esquema ImportadorDeArchivos
IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'ImportadorDeArchivos'
)
	EXEC('CREATE SCHEMA ImportadorDeArchivos');
ELSE
    PRINT 'El esquema ImportadorDeArchivos ya existe.';
GO
--5) Esquema Reportes
IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'Reportes'
)
	EXEC('CREATE SCHEMA Reportes');
ELSE
    PRINT 'El esquema Reportes ya existe.';
GO

-- modulo de creacion de tablas:
--1) TABLA SUCURSAL
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HR].[Sucursal]') AND type in (N'U'))
BEGIN
    CREATE TABLE HR.Sucursal (
			nroSucursal TINYINT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			ciudad CHAR(15),
			localidad VARCHAR(25)
    );

    PRINT 'Tabla Sucursal creada.';
END
ELSE
    PRINT 'La tabla Sucursal ya existe.';
GO

--2) TABLA PRODUCTO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prod].[Producto]') AND type in (N'U'))
BEGIN
    CREATE TABLE Prod.Producto (
            idProd INT PRIMARY KEY IDENTITY(1,1),
			lineaDeProducto VARCHAR(64),
			nombreProd NVARCHAR(256),
			precioArs DECIMAL(6,2) null default 0, --Valor nulo cuando no aplica 
			precioUsd DECIMAL(6,2) null default 0, --Valor nulo cuando no aplica
			unidadRef VARCHAR(64),		
			fechaBorrado DATE DEFAULT NULL --BORRADO LOGICO
    );

    PRINT 'Tabla Producto creada.';
END
ELSE
    PRINT 'La tabla Producto ya existe.';
GO

--3) TABLA EMPLEADO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HR].[EMPLEADO]') AND type in (N'U'))
BEGIN
    CREATE TABLE HR.Empleado (
			legajo INT PRIMARY KEY CLUSTERED NOT NULL,
			nombre VARCHAR(60),
			apellido VARCHAR(60),
			dni BIGINT NOT NULL,
			direccion VARCHAR(300),
			cargo CHAR(20),
			turno CHAR(16), --tt,tm,tn,jornada completa
			idSuc TINYINT NOT NULL,
			mailPersonal VARCHAR(70),
			mailEmpresa VARCHAR(70),
			fechaBorrado DATE DEFAULT NULL --BORRADO LOGICO
			
	CONSTRAINT fkSucursal FOREIGN KEY (idSuc) REFERENCES hr.sucursal(nroSucursal)
    );

    PRINT 'Tabla Empleado creada.';
END
ELSE
    PRINT 'La tabla Empleado ya existe.';
GO

--4) TABLA FACTURA
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[INV].[Factura]') AND type in (N'U'))
BEGIN
    CREATE TABLE INV.Factura (
			idFactura CHAR(11) PRIMARY KEY,
			idEmp INT NOT NULL,
			tipoFac CHAR(1),
			tipoCliente CHAR(6),
			genero CHAR(6),
			fecha DATE,
			hora TIME,
			regPago VARCHAR(22)

	CONSTRAINT fkEmp  FOREIGN KEY (idEmp)  REFERENCES HR.Empleado(legajo)
	);
    PRINT 'Tabla Factura creada.';
END
ELSE
    PRINT 'La tabla Factura ya existe.';
GO


--5) TABLA DetalleVenta
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[INV].[DetalleVenta]') AND type in (N'U'))
BEGIN
    CREATE TABLE INV.DetalleVenta (
			idLineaProducto INT PRIMARY KEY IDENTITY(1,1),
			idProducto	INT,
			idFactura	CHAR(11),
			subTotal	DECIMAL(9,2),
			cant		SMALLINT NOT NULL,
			precio		DECIMAL(6,2)

	CONSTRAINT fkFactura FOREIGN KEY (idFactura) REFERENCES INV.Factura(idFactura),
	CONSTRAINT fkProducto  FOREIGN KEY (idProducto)  REFERENCES PROD.Producto(idProd),
	);
    PRINT 'Tabla DetalleVenta creada.';
END
ELSE
    PRINT 'La tabla DetalleVenta ya existe.';
GO



--BORRADO DE TABLAS:
/*

drop table hr.Sucursal

drop table prod.Producto
*/

--VISTA DE TABLAS:
/*
drop table hr.Empleado
drop table INV.FACTURA
Select * from HR.Sucursal
Select * from HR.Empleado
Select * from INV.Factura
Select * from prod
*/
