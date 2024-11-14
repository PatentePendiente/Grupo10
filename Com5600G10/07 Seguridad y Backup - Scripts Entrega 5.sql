/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Seguridad, Encriptación y Backup
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Creacion de usuario y sede de permisos para el responsable de importar archivos
2) Creacion del login y usuario para el responsable de crear los reportesXSLX
3) Creacion del login y usuario para el cajero
4) Creacion del login, usuario y rol para el supervisor
5) Creacion de stored procedure para crear una nota de credito
6) Concedemos permiso de ejecución del SP crearNotaCredito al rol de Supervisor

*/

USE Com5600G10
GO


--1) Creacion de usuario y sede de permisos para el responsable de importar archivos
-- Verificar si el LOGIN ya existe
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'UsuarioImportador')
BEGIN
    CREATE LOGIN UsuarioImportador WITH PASSWORD = 'importador123';
	PRINT 'Se creo el Login UsuarioImportador';
END
ELSE
    PRINT 'El Login UsuarioImportador ya existe';
GO


IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'UsuarioImportador')
BEGIN
    CREATE USER UsuarioImportador FOR LOGIN UsuarioImportador;
END
ELSE
    PRINT 'El usuario UsuarioImportador ya existe en la base de datos.';
GO

--Conceder permisos para el uso de los sp de importacion de archivos
GRANT EXECUTE ON SCHEMA::ImportadorDeArchivos TO UsuarioImportador;   
GO



-- 2) Creacion del login y usuario para el responsable de crear los reportesXSLX
-- Creamos el login para el usuario de reportes
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'UsuarioReportes')
BEGIN
    CREATE LOGIN UsuarioReportes WITH PASSWORD = 'reportes123';
    PRINT 'Se creo el Login UsuarioReportes';
END
ELSE
    PRINT 'El Login UsuarioReportes ya existe';
GO

-- Creamos el usuario de reportes
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'UsuarioReportes')
BEGIN
    CREATE USER UsuarioReportes FOR LOGIN UsuarioReportes;
END
ELSE
    PRINT 'El usuario UsuarioReportes ya existe en la base de datos.';

--Conceder permisos para la creacion de reportes
GRANT EXECUTE ON SCHEMA::Reportes TO UsuarioReportes;
GO



-- 3) Creacion del login y usuario para el cajero
-- Creamos el login para el usuario de caja
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'UsuarioCaja')
BEGIN
    CREATE LOGIN UsuarioCaja WITH PASSWORD = 'caja123';
    PRINT 'Se creo el Login UsuarioCaja';
END
ELSE
    PRINT 'El Login UsuarioCaja ya existe';

-- Creamos el usuario de caja
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'UsuarioCaja')
BEGIN
    CREATE USER UsuarioCaja FOR LOGIN UsuarioCaja;
END
ELSE
    PRINT 'El usuario UsuarioCaja ya existe en la base de datos.';
GO

-- Concedemos permisos al cajero al schema Cajero
GRANT EXECUTE ON SCHEMA::Cajero TO UsuarioCaja;
-- Concedemos permisos al cajero para consultar la API de dolar
GRANT EXECUTE ON ImportadorDeArchivos.consultarDolarAPI TO UsuarioCaja;
-- Concedemos los permisos necesarios al cajero para que el stored procedure consultarDolarApi funcione correctamente
USE master
GO
GRANT EXECUTE ON sys.sp_OACreate TO UsuarioCaja;
GRANT EXECUTE ON sys.sp_OAMethod TO UsuarioCaja;
GRANT EXECUTE ON sys.sp_OAGetProperty TO UsuarioCaja;
GRANT EXECUTE ON sys.sp_OADestroy TO UsuarioCaja;

USE Com5600G10
GO




-- 4) Creacion del login, usuario y rol para el supervisor
-- Creamos el login para el supervisor
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'SupervisorLogin')
BEGIN
    CREATE LOGIN SupervisorLogin WITH PASSWORD = 'Supervisor123!';
    PRINT 'Login SupervisorLogin creado.';
END
GO

-- Creamos el usuario para el supervisor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SupervisorUser')
BEGIN
    CREATE USER SupervisorUser FOR LOGIN SupervisorLogin;
    PRINT 'Usuario SupervisorUser creado.';
END
GO

-- Creamos el rol para el supervisor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SupervisorRol')
BEGIN
    CREATE ROLE SupervisorRol;
    ALTER ROLE SupervisorRol ADD MEMBER SupervisorUser;
    PRINT 'Rol SupervisorRol creado.';
END
GO




-- 5) Creacion de stored procedure para crear una nota de credito
CREATE OR ALTER PROCEDURE INV.crearNotaCredito
    @nroFactura CHAR(11),
    @idProducto INT,
    @tipoNota CHAR(1) -- 'P': 'Producto' o 'V': 'Valor'
AS
BEGIN
    DECLARE @precio DECIMAL(10, 2);

	-- Verificamos si la factura existe
	IF NOT EXISTS (SELECT 1 FROM INV.Factura WHERE nroFactura = @nroFactura)
	BEGIN
		RAISERROR('La factura no existe.', 16, 1);
		RETURN;
	END

	-- Verificamos si la factura no esta perdiente de pago
	IF EXISTS (SELECT 1 FROM INV.Factura WHERE nroFactura = @nroFactura AND regPago = 'Pendiente de Pago')
	BEGIN
		RAISERROR('La factura está pendiente de pago.', 16, 1);
		RETURN;
	END

	-- Verificamos si el producto pertenece a la factura
    SELECT @precio = dv.precio
    FROM INV.DetalleVenta dv
    WHERE dv.nroFactura = @nroFactura AND dv.idProducto = @idProducto;

    IF @precio IS NULL
    BEGIN
        RAISERROR('El producto no corresponde a la factura.', 16, 1);
        RETURN;
    END

    -- Insertamos la nota de crédito
    INSERT INTO INV.NotaCredito (idFactura, idProducto, tipoNotaCredito, monto, Fecha)
    VALUES (@nroFactura, @idProducto, @tipoNota, @precio, GETDATE());

    PRINT 'Nota de crédito creada exitosamente.';
END;
GO


-- 6) Concedemos permiso de ejecución del SP crearNotaCredito al rol de Supervisor
GRANT EXECUTE ON INV.CrearNotaCredito TO SupervisorRol;























