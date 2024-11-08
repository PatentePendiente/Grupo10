/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Seguridad, Encriptación y Backup
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Creacion de Certificados y Claves para Encriptación
2) Creacion de usuario y sede de permisos para el responsable de importar archivos
3) Creacion del login para el supervisor
4) Creacion del usuario para el supervisor

*/

-- Modulo de creacion de certificados y claves:
-- 1) Certificados y Claves para Encriptación
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    -- Para encriptar la tabla de empleados, decidimos usar el algorítmo AES_256 de encriptación simétrica, 
	-- ya que es la más segura entre los algoritmos AES_128, AES_192, y AES_256

	-- Creamos una clave maestra para proteger los certificados y claves que creemos a nivel base de datos
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'ClaveEncriptacionEmpleados123';

	-- Creamos el certificado que va a proteger la clave simétrica
	CREATE CERTIFICATE EmpleadosCert
	WITH SUBJECT = 'Certificado para encriptar los datos de empleados';

	-- Creamos la clave simetrica que vamos a usar para encriptar la tabla de empleados 
	CREATE SYMMETRIC KEY EmpleadosClaveSimetrica
	WITH ALGORITHM = AES_256
	ENCRYPTION BY CERTIFICATE EmpleadosCert;

	PRINT 'Certificados y claves para encriptación creados';
END
ELSE
    PRINT 'La clave simétrica EmpleadosClaveSimetrica ya existe';	
GO

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

-- 4) Creacion del usuario para el supervisor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SupervisorUser')
BEGIN
    CREATE USER SupervisorUser FOR LOGIN SupervisorLogin;
    PRINT 'Usuario SupervisorUser creado.';
END


























