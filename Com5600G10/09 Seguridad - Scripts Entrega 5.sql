/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Seguridad, Encriptación y Backup
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Creacion del login y usuario para el responsable de crear los reportes
2) Creacion del login, usuario y rol para los cajeros
3) Creacion de SP para crear una nota de credito
4) Creacion del login, usuario y rol para el supervisor
*/


USE Com5600G10
GO


-- 1) Creacion del login y usuario para el responsable de crear los reportes
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
	PRINT 'Se creo el UsuarioReportes';
END
ELSE
    PRINT 'El usuario UsuarioReportes ya existe en la base de datos.';

--Conceder permisos para la creacion de reportes
GRANT EXECUTE ON SCHEMA::Reportes TO UsuarioReportes;
GO



-- 2) Creacion del login y usuario para el cajero
-- Creamos el login para el usuario de caja
USE Com5600G10
GO

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
	PRINT 'Se creo el Usuario UsuarioCaja.';
END
ELSE
    PRINT 'El usuario UsuarioCaja ya existe en la base de datos.';
GO

-- Creamos un rol para los cajeros
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'CajeroExecutor')
BEGIN
    CREATE ROLE CajeroExecutor;
    PRINT 'Se creo el rol CajeroExecutor.';
END
ELSE
    PRINT 'El rol CajeroExecutor ya existe.';

-- Asignar el rol al usuario UsuarioCaja
EXEC sp_addrolemember 'CajeroExecutor', 'UsuarioCaja';

--Conceder permisos para ejecutar SP de caja
GRANT EXECUTE ON SCHEMA::Cajero TO CajeroExecutor
GO



-- 3) Creacion de stored procedure para crear una nota de credito
CREATE OR ALTER PROCEDURE INV.crearNotaCredito
    @nroFactura INT,
    @idProducto INT,
    @tipoNota CHAR(1) -- 'P': 'Producto' o 'V': 'Valor'
AS
BEGIN
    DECLARE @precio DECIMAL(10, 2);

	-- Validamos que tipoNota sea 'P' o 'V'
	IF @tipoNota NOT IN ('P', 'V')
	BEGIN
		RAISERROR('El valor de @tipoNota debe ser "P" para Producto o "V" para Valor.', 16, 1);
		RETURN;
	END

	-- Verificamos si la factura existe
	IF NOT EXISTS (SELECT 1 FROM INV.Factura WHERE nroFactura = @nroFactura)
	BEGIN
		RAISERROR('LA FACTURA NO EXISTE.', 16, 1);
		RETURN;
	END

	-- Verificamos si la factura no esta perdiente de pago
	IF EXISTS (SELECT 1 FROM INV.Factura WHERE nroFactura = @nroFactura AND regPago = 'Pendiente de Pago')
	BEGIN
		RAISERROR('LA FACTURA ESTA PENDIENTE DE PAGO POR LO QUE NO SE PUEDE REALIZAR NOTA DE CREDITO.', 16, 1);
		RETURN;
	END

	-- Verificamos si el producto pertenece a la factura
    SELECT @precio = dv.precio
    FROM INV.DetalleVenta dv
    WHERE dv.nroFactura = @nroFactura AND dv.idProducto = @idProducto;

    IF @precio IS NULL
    BEGIN
        RAISERROR('EL PRODUCTO NO CORRESPONDE A LA FACTURA.', 16, 1);
        RETURN;
    END

    -- Insertamos la nota de crédito
    INSERT INTO INV.NotaCredito (idFactura, idProducto, tipoNotaCredito, monto, Fecha)
    VALUES (@nroFactura, @idProducto, @tipoNota, @precio, GETDATE());

    PRINT 'Nota de credito creada exitosamente.';
END;
GO



-- 4) Creacion del login, usuario y rol para el supervisor
-- Creamos el login para el supervisor
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'UsuarioSupervisor')
BEGIN
    CREATE LOGIN UsuarioSupervisor WITH PASSWORD = 'supervisor123';
    PRINT 'Login UsuarioSupervisor creado.';
END
GO

-- Creamos el usuario para el supervisor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'UsuarioSupervisor')
BEGIN
    CREATE USER UsuarioSupervisor FOR LOGIN SupervisorLogin;
    PRINT 'Usuario UsuarioSupervisor creado.';
END
GO

-- Creamos el rol para el supervisor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SupervisorRol')
BEGIN
    CREATE ROLE SupervisorRol;
    PRINT 'Rol SupervisorRol creado.';
END
GO
-- Concedemos permiso de ejecución del SP crearNotaCredito al rol de Supervisor
GRANT EXECUTE ON INV.CrearNotaCredito TO SupervisorRol;
GO

-- Agregamos al supervisor al rol
ALTER ROLE SupervisorRol ADD MEMBER UsuarioSupervisor;
PRINT 'Usuario Supervisor agregado al rol SupervisorRol.';
GO

















