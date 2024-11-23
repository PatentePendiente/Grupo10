/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Encriptacion de datos sensibles de empleados
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Creacion de certificados y claves para encriptacion
2) Modificacion de la tabla Empleado para  la encriptacion de los datos
3) Modificacion del stored procedure para importar los datos de empleados
4) Creacin de un stored procedure para mostrar a los empleados desencriptados

*/

USE Com5600G10
GO

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

-- 2) Modificacion de la tabla Empleado para  la encriptacion de los datos
-- Debido a que en la entrega 3 creamos la tabla Empleado sin tener en cuenta la encriptacion de los datos,
-- vamos a modificar la tabla Empleado para que los datos sensibles de los empleados esten encriptados.

-- Paso 1: Verificamos si la tabla HR.Empleado ya está encriptada
-- (Verificamos si la columna nombre es de tipo VARBINARY)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[HR].[Empleado]') AND name = 'nombre' AND system_type_id = 165)
BEGIN
    PRINT 'La tabla Empleado ya está encriptada.';
END
ELSE
BEGIN
    -- Paso 2: Creamos una tabla temporal para almacenar los datos de HR.Empleado mientras hacemos la transformacion
    CREATE TABLE #EmpleadoTemp (
        legajo INT PRIMARY KEY,
        nombre VARCHAR(60),
        apellido VARCHAR(60),
        dni BIGINT,
        direccion VARCHAR(300),
        cargo CHAR(20),
        turno CHAR(16),
        idSuc TINYINT,
        mailPersonal VARCHAR(70),
        mailEmpresa VARCHAR(70),
        fechaBorrado DATE
    );

    -- Copiamos los datos de HR.Empleado a la tabla temporal
    INSERT INTO #EmpleadoTemp
    SELECT legajo, nombre, apellido, dni, direccion, cargo, turno, idSuc, mailPersonal, mailEmpresa, fechaBorrado
    FROM HR.Empleado;

    -- Paso 3: Alteramos la tabla HR.Empleado para agregar nuevas columnas VARBINARY
    ALTER TABLE HR.Empleado ADD nombre_nuevo VARBINARY(8000);
    ALTER TABLE HR.Empleado ADD apellido_nuevo VARBINARY(8000);
    ALTER TABLE HR.Empleado ADD dni_nuevo VARBINARY(8000);
    ALTER TABLE HR.Empleado ADD direccion_nuevo VARBINARY(8000);
    ALTER TABLE HR.Empleado ADD mailPersonal_nuevo VARBINARY(8000);
    ALTER TABLE HR.Empleado ADD mailEmpresa_nuevo VARBINARY(8000);

    -- Paso 4: Abrimos la clave simétrica
    OPEN SYMMETRIC KEY EmpleadosClaveSimetrica DECRYPTION BY CERTIFICATE EmpleadosCert;

    -- Paso 5: Insertamos los datos en las nuevas columnas encriptando los campos necesarios
    UPDATE HR.Empleado
    SET 
        nombre_nuevo = ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), temp.nombre),
        apellido_nuevo = ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), temp.apellido),
        dni_nuevo = ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), CAST(temp.dni AS VARCHAR(8000))),
        direccion_nuevo = ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), temp.direccion),
        mailPersonal_nuevo = ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), temp.mailPersonal),
        mailEmpresa_nuevo = ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), temp.mailEmpresa)
    FROM #EmpleadoTemp temp
    WHERE HR.Empleado.legajo = temp.legajo;

	-- Eliminamos la tabla temporal
    DROP TABLE #EmpleadoTemp;

    -- Cerramos la clave simétrica
    CLOSE SYMMETRIC KEY EmpleadosClaveSimetrica;

    -- Paso 6: Eliminamos las columnas antiguas
    ALTER TABLE HR.Empleado DROP COLUMN nombre;
    ALTER TABLE HR.Empleado DROP COLUMN apellido;
    ALTER TABLE HR.Empleado DROP COLUMN dni;
    ALTER TABLE HR.Empleado DROP COLUMN direccion;
    ALTER TABLE HR.Empleado DROP COLUMN mailPersonal;
    ALTER TABLE HR.Empleado DROP COLUMN mailEmpresa;

    -- Paso 7: Renombramos las nuevas columnas con los nombres originales
    EXEC sp_rename 'HR.Empleado.nombre_nuevo', 'nombre', 'COLUMN';
    EXEC sp_rename 'HR.Empleado.apellido_nuevo', 'apellido', 'COLUMN';
    EXEC sp_rename 'HR.Empleado.dni_nuevo', 'dni', 'COLUMN';
    EXEC sp_rename 'HR.Empleado.direccion_nuevo', 'direccion', 'COLUMN';
    EXEC sp_rename 'HR.Empleado.mailPersonal_nuevo', 'mailPersonal', 'COLUMN';
    EXEC sp_rename 'HR.Empleado.mailEmpresa_nuevo', 'mailEmpresa', 'COLUMN';

    PRINT 'Datos encriptados y actualizados en la tabla Empleado.';
END
GO


-- 3) Modificacion del stored procedure para importar los datos de empleados
CREATE OR ALTER PROCEDURE ImportadorDeArchivos.ImportarEmpleados
	@ruta VARCHAR(MAX)
AS
BEGIN
	-- Creamos una tabla temporal para almacenar los datos importados
	--Legajo/ID	Nombre	Apellido	DNI  direccion email personal	email empresa	CUIL	Cargo	Sucursal	Turno
	CREATE TABLE #tablaImportada (
		legajo VARCHAR(MAX),
		nombre VARCHAR(MAX),
		apellido VARCHAR(MAX),
		--Tuve problemas para leer el documento del excel con un varchar, ya que excel maneja numeros grandes como el del
		-- documento de 10.000.000 como numeros flotantes, use decimal y lo lei directamente para luego castearlo a entero
		doc DECIMAL(15,2),
		direccion VARCHAR(MAX),
		emailPers VARCHAR(MAX),
		emailEmp VARCHAR(MAX),
		cuil VARCHAR(MAX),
		cargo VARCHAR(MAX),
		surcursal VARCHAR(MAX),
		turno VARCHAR(MAX)
	);

	-- Leemos los datos del archivo Excel
	DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'INSERT INTO #tablaImportada SELECT * FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database=' + @ruta + ';HDR=YES'', ''SELECT * FROM [Empleados$]'');';
    EXEC sp_executesql @sql;

	--Eliminamos filas que se leen nulas
	delete from #tablaImportada 
	where legajo is null

	-- Abrimos la clave simetrica para usarla para la encriptaci�n 
	OPEN SYMMETRIC KEY EmpleadosClaveSimetrica
	DECRYPTION BY CERTIFICATE EmpleadosCert;

	-- Insertamos los datos encriptado en la tabla
	MERGE INTO HR.Empleado AS TARGET
	USING (
	 SELECT 
		CAST(t.legajo AS INT) AS legajo, -- No encriptamos el legajo ya que es la clave primaria de la tabla
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), t.nombre) AS nombre, 
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), t.apellido) AS apellido, 
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), CAST(CAST(t.doc AS INT) AS CHAR(8))) AS dni, 
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), t.direccion) AS direccion, 
		cargo, 
		turno, 
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), t.emailPers) AS emailPers,
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), t.emailEmp) AS emailEmp, 
		S.nroSucursal AS nroSucursal -- No encriptamos el nro de sucursal ya que es clave foranea
	FROM #tablaImportada t
	INNER JOIN HR.Sucursal s on t.surcursal = s.localidad
	) AS SOURCE
	ON TARGET.legajo = SOURCE.legajo
	WHEN MATCHED THEN 
	  UPDATE SET 
        TARGET.nombre = SOURCE.nombre,
        TARGET.apellido = SOURCE.apellido,
        TARGET.dni = SOURCE.dni,
        TARGET.direccion = SOURCE.direccion,
        TARGET.cargo = SOURCE.cargo,
        TARGET.turno = SOURCE.turno,
        TARGET.mailPersonal = SOURCE.emailPers,
        TARGET.mailEmpresa = SOURCE.emailEmp,
        TARGET.idSuc = SOURCE.nroSucursal
	WHEN NOT MATCHED THEN 
    INSERT (legajo, nombre, apellido, dni, direccion, cargo, turno, mailPersonal, mailEmpresa, idSuc)
    VALUES (SOURCE.legajo, SOURCE.nombre, SOURCE.apellido, SOURCE.dni, SOURCE.direccion, SOURCE.cargo, SOURCE.turno, SOURCE.emailPers, SOURCE.emailEmp, SOURCE.nroSucursal);

	-- Cerramos la clave simetrica
	CLOSE SYMMETRIC KEY EmpleadosClaveSimetrica;
END
GO	

-- 4) Store Procedure para mostrar a los empleados desencriptados
CREATE OR ALTER PROCEDURE DBA.mostrarEmpleados 
AS
BEGIN
	-- Abrimos la clave simetrica para usarla para la desencriptacion 
	OPEN SYMMETRIC KEY EmpleadosClaveSimetrica
	DECRYPTION BY CERTIFICATE EmpleadosCert;

	SELECT
		legajo,
		CONVERT(VARCHAR(60), DecryptByKey(nombre)) AS nombre,
		CONVERT(VARCHAR(60), DecryptByKey(apellido)) AS apellido,
		CONVERT(CHAR(8), DecryptByKey(dni)) AS dni,
		CONVERT(VARCHAR(300), DecryptByKey(direccion)) AS direccion,
		cargo,
		turno,
		idSuc,
		CONVERT(VARCHAR(70), DecryptByKey(mailPersonal)) AS mailPersonal,
		CONVERT(VARCHAR(70), DecryptByKey(mailEmpresa)) AS mailEmpresa,
		fechaBorrado
	FROM HR.Empleado;

	CLOSE SYMMETRIC KEY EmpleadosClaveSimetrica;
END;
GO