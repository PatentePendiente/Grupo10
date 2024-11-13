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
CREATE OR ALTER PROCEDURE INV.CrearNotaCredito
    @idFactura CHAR(11),
    @nombreProducto VARCHAR(256),
    @tipoNota CHAR(1) -- 'P': 'Producto' o 'V': 'Valor'
AS
BEGIN
    -- Verificamos si el usuario tiene el rol de Supervisor
    IF IS_ROLEMEMBER('SupervisorRol') = 0
    BEGIN
        PRINT 'Solo los Supervisores pueden crear una nota de crédito.'
        RETURN;
    END

    -- Verificamos si la factura existe y si el producto es válido y pertenece a la factura
    DECLARE @idProducto INT, @monto DECIMAL(6,2);

    IF NOT EXISTS (SELECT 1 FROM INV.Factura WHERE idFactura = @idFactura AND regPago <> 'Pendiente de Pago')
    BEGIN
        PRINT 'La factura no existe o está pendiente de pago.'
        RETURN;
    END

    SELECT @idProducto = p.idProd, @monto = p.precioArs
    FROM PROD.Producto p
    INNER JOIN INV.DetalleVenta dv ON dv.idProducto = p.idProd
    WHERE dv.idFactura = @idFactura AND p.nombreProd = @nombreProducto;

    IF @idProducto IS NULL
    BEGIN
        PRINT 'El producto no corresponde a la factura.'
        RETURN;
    END

    -- Insertamos la nota de crédito
    INSERT INTO NotaCredito (idFactura, idProducto, tipoNotaCredito, monto)
    VALUES (@idFactura, @idProducto, @tipoNota, @monto);

    PRINT 'Nota de crédito creada exitosamente.';
END
GO


-- 6) Concedemos permiso de ejecución del SP crearNotaCredito al rol de Supervisor
GRANT EXECUTE ON INV.CrearNotaCredito TO SupervisorRol;

























