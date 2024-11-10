/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Seguridad, Encriptación y Backup
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
2) Creacion de usuario y sede de permisos para el responsable de importar archivos
3) Creacion del login para el supervisor
4) Creacion del usuario para el supervisor
5) Creacion del rol para el supervisor
6) Creación de stored procedure para crear una nota de crédito
7) Conceder permiso de ejecución del SP crearNotaCredito al rol de Supervisor

*/


--2) Creacion de usuario y sede de permisos para el responsable de importar archivos
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

-- 3) Creacion del login para el supervisor
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'SupervisorLogin')
BEGIN
    CREATE LOGIN SupervisorLogin WITH PASSWORD = 'Supervisor123!';
    PRINT 'Login SupervisorLogin creado.';
END
GO

-- 4) Creacion del usuario para el supervisor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SupervisorUser')
BEGIN
    CREATE USER SupervisorUser FOR LOGIN SupervisorLogin;
    PRINT 'Usuario SupervisorUser creado.';
END
GO

-- 5) Creacion del rol para el supervisor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SupervisorRol')
BEGIN
    CREATE ROLE SupervisorRol;
    ALTER ROLE SupervisorRol ADD MEMBER SupervisorUser;
    PRINT 'Rol SupervisorRol creado.';
END
GO


-- 6) Creación de stored procedure para crear una nota de crédito
CREATE OR ALTER PROCEDURE INV.CrearNotaCredito
    @idFactura CHAR(11),
    @nombreProducto VARCHAR(256),
    @tipoNota CHAR(1) -- 'P': 'Producto' o 'V': 'Valor'
AS
BEGIN
    -- Verificar si el usuario tiene el rol de Supervisor
    IF IS_ROLEMEMBER('SupervisorRol') = 0
    BEGIN
        PRINT 'Solo los Supervisores pueden crear una nota de crédito.'
        RETURN;
    END

    -- Verificar si la factura existe y si el producto es válido y pertenece a la factura
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

    -- Insertar la nota de crédito
    INSERT INTO NotaCredito (idFactura, idProducto, tipoNotaCredito, monto)
    VALUES (@idFactura, @idProducto, @tipoNota, @monto);

    PRINT 'Nota de crédito creada exitosamente.';
END
GO


-- 7) Conceder permiso de ejecución del SP crearNotaCredito al rol de Supervisor
GRANT EXECUTE ON INV.CrearNotaCredito TO SupervisorRol;

























