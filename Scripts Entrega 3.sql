/*				--Trabajo Integrador de Base de Datos Aplicada--
Fecha: 1/11/2024
Entrega Nro: 3 Creacion de Tablas
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MAMANI ESTRADA, LUCAS GABRIEL  --
-MOSCOSO RENDON, JUAN DIEGO     --
-VARELA, DANIEL MARIANO		   --
*/

--Creacion de bd:
IF not exists(
	SELECT NAME FROM sys.databases
	WHERE NAME = 'Com5600G10'
)
BEGIN 
CREATE DATABASE Com5600G10;
END

ELSE
BEGIN 
PRINT 'La base de datos Com5600G10 ya existe';
END
GO

USE Com5600G10
GO

-- modulo de creacion de esquemas: HR(Sucursal y Empleado), 
-- INV(Facturacion) y PROD(Producto, Catalogo)
IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'HR'
)
BEGIN
	EXEC('CREATE SCHEMA HR');
END
ELSE
BEGIN
    PRINT 'El esquema HR ya existe.';
END
GO

IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'INV'
)
BEGIN
	EXEC('CREATE SCHEMA INV');
END
ELSE
BEGIN
    PRINT 'El esquema INV ya existe.';
END
GO

IF NOT EXISTS (
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'PROD'
)
BEGIN
	EXEC('CREATE SCHEMA PROD');
END
ELSE
BEGIN
    PRINT 'El esquema PROD ya existe.';
END
GO

-- modulo de creacion de tablas:
--1) TABLA SUCURSAL
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HR].[Sucursal]') AND type in (N'U'))
BEGIN
    CREATE TABLE HR.Sucursal (
			nroSucursal TINYINT PRIMARY KEY NOT NULL,
			ciudad CHAR(15),
			localidad VARCHAR(25)
    );

    PRINT 'Tabla Sucursal creada.';
END
ELSE
BEGIN
    PRINT 'La tabla Sucursal ya existe.';
END
GO

--2) TABLA PRODUCTO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prod].[Producto]') AND type in (N'U'))
BEGIN
    CREATE TABLE Prod.Producto (
            idProd INT PRIMARY KEY IDENTITY(1,1),
--			idSuc TINYINT NOT NULL,
			lineaDeProducto VARCHAR(30),
			precioArs DECIMAL(6,2) null default 0, --Valor nulo cuando no aplica 
			precioUsd DECIMAL(6,2) null default 0, --Valor nulo cuando no aplica
			unidad SMALLINT not null,	 --Almacena en gramos o en cantidad
			activo BIT DEFAULT 1		 --BORRADO LOGICO
	
--	CONSTRAINT fkSucursal FOREIGN KEY (idSuc) REFERENCES hr.sucursal(nroSucursal)
    );

    PRINT 'Tabla Producto creada.';
END
ELSE
BEGIN
    PRINT 'La tabla Producto ya existe.';
END
GO

--3) TABLA EMPLEADO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HR].[EMPLEADO]') AND type in (N'U'))
BEGIN
    CREATE TABLE HR.Empleado (
			legajo INT PRIMARY KEY CLUSTERED NOT NULL,
			documento INT NOT NULL,
			cargo CHAR(20),
			turno CHAR(2), --tt,tm,tn,jc(jornada completa)
			idSuc TINYINT NOT NULL,
			activo BIT DEFAULT 1  --BORRADO LOGICO
			
	CONSTRAINT fkSucursal FOREIGN KEY (idSuc) REFERENCES hr.sucursal(nroSucursal)
    );

    PRINT 'Tabla Empleado creada.';
END
ELSE
BEGIN
    PRINT 'La tabla Empleado ya existe.';
END
GO

--4) TABLA FACTURA
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[INV].[Factura]') AND type in (N'U'))
BEGIN
    CREATE TABLE INV.Factura (
			idFactura CHAR(11) PRIMARY KEY,
			idProd INT NOT NULL,
			idSuc TINYINT NOT NULL,
			idEmp INT NOT NULL,
			tipoFac CHAR(1),
			tipoCliente CHAR(6),
			genero CHAR(6),
			cantVendida INT NOT NULL,
			fecha DATE,
			hora TIME,
			regPago VARCHAR(22)

	CONSTRAINT fkProd FOREIGN KEY (idProd) REFERENCES Prod.Producto(idProd),
	CONSTRAINT fkSuc  FOREIGN KEY (idSuc)  REFERENCES HR.Sucursal(nroSucursal),
	CONSTRAINT fkEmp  FOREIGN KEY (idEmp)  REFERENCES HR.Empleado(legajo)
	);
    PRINT 'Tabla Factura creada.';
END
ELSE
BEGIN
    PRINT 'La tabla Factura ya existe.';
END
GO

--BORRADO DE TABLAS:
/*
drop table hr.Empleado
drop table hr.Sucursal
drop table prod.Producto
drop table INV.FACTURA
*/




