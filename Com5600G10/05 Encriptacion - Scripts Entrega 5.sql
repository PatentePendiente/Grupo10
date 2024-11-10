/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Encriptacion de datos sensibles de empleados
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 



*/


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



	/*

	-- MODIFICACION PARA LA ENTREGA 5
	-- Se nos pide encriptar la tabla de empleados porque contiene informacion privada.
	-- Debido a que la version de SQL SERVER que utilizamos para dise�ar la base de datos (SQL SERVER EXPRESS)
	-- no admite la encriptaci�n por tabla, tenemos que hacerla por columnas.
	-- Debemos encriptar cada valor antes de insertarlo en la tabla Empleado.

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
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), t.cargo) AS cargo, 
		ENCRYPTBYKEY(KEY_GUID('EmpleadosClaveSimetrica'), t.turno) AS turno, 
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
	



