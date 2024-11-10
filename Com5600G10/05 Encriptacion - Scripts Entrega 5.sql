/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Encriptacion de datos sensibles de empleados
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Creación de certificados y claves para encriptación
2) Creacion de la tabla EmpleadoEncriptado
3) Creacion de un stored procedure para importar los datos de empleados encriptados


*/

-- 1) Creación de certificados y claves para encriptación
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

-- 2) Creacion de la tabla EmpleadoEncriptado
-- Debido a los datos privados de los empleados deben estar encritados,
-- creamos una nueva tabla que va a almacenar los datos encriptados de los empledos
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HR].[EmpleadoEncriptado]') AND type in (N'U'))
BEGIN
	CREATE TABLE HR.EmpleadoEncriptado(
		legajo INT PRIMARY KEY, -- No encriptamos el legajo porque es una clave primaria
		nombre VARBINARY(8000),  
		apellido VARBINARY(8000),  
		dni VARBINARY(8000),  
		direccion VARBINARY(8000),  
		cargo CHAR(20),
		turno CHAR(16), --tt,tm,tn,jornada completa
		idSuc TINYINT NOT NULL, -- No encriptamos el id de la sucursal porque es una clave for�nea
		mailPersonal VARBINARY(8000),  
		mailEmpresa VARBINARY(8000),  
		fechaBorrado DATE NULL,

    	CONSTRAINT fkSucursal FOREIGN KEY (idSuc) REFERENCES hr.sucursal(nroSucursal)
	);
END
ELSE
	PRINT 'La tabla EmpleadoEncriptado ya existe.';





