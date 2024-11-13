/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 - Testing de SP de encriptacion
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Mostramos como se ve la tabla Empleado encriptada después de la encriptación
2) Ejecutamos el SP mostrarEmpleados para ver los empleados desencriptados
3) Vemos si se insertan correctamente en la tabla Empleado los valores encriptados desde el documento EXCEL
4) Vemos si el borrado logico de un empleado se hace correctamente después de la encriptacion

*/

USE Com5600G10
GO



-- 1) Mostramos como se ve la tabla Empleado encriptada
SELECT * FROM HR.Empleado;



-- 2) Ejecutamos el SP mostrarEmpleados para ver los empleados desencriptados
EXEC DBA.mostrarEmpleados
GO



-- 3) Vemos si se insertan correctamente en la tabla Empleado los valores encriptados desde el documento EXCEL

-- Primero borramos algunos valores de la tabla Empleado
UPDATE HR.Empleado
SET 
    nombre = NULL,
    apellido = NULL,
    dni = NULL,
    direccion = NULL,
    mailPersonal = NULL,
    mailEmpresa = NULL;

-- Miramos la tabla Empleado
SELECT * FROM HR.Empleado;

-- Si la modificacion SP de importacion de empleados se hizo correctamente,
-- Los datos que fueron eliminados se deberian actualizar con los que son leidos del documento.
-- EXEC ImportadorDeArchivos.importarEmpleados 'C:\Users\user\Desktop\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';
EXEC ImportadorDeArchivos.importarEmpleados 'C:\Users\JuanD\OneDrive\Escritorio\bbdda\projecto_github\Com5600G10\TP_integrador_Archivos\Informacion_complementaria.xlsx';

-- Observamos si los valores se insertaron de manera encriptada en la tabla Empleado
EXEC DBA.mostrarEmpleados
GO



-- 4) Vemos si el borrado logico de un empleado se hace correctamente después de la encriptacion
EXEC ImportadorDeArchivos.borrarEmpleado 257020;

EXEC DBA.mostrarEmpleados;
GO

-- Revertimos el borrado logico del empleado
UPDATE HR.Empleado SET fechaBorrado = NULL WHERE legajo = 257020;










