/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Testing de Back-ups
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Vemos los trabajos creados para la automatizacion de backups
2) Vemos los pasos de los trabajos para la automatizacion de backups
3) Vemos los horarios de los trabajos para la automatizacion de backups
*/


-- 1) Vemos los trabajos creados para la automatizacion de backups
SELECT job_id, name, enabled, description, date_created, date_modified
FROM msdb.dbo.sysjobs
ORDER BY name;


-- 2) Vemos los pasos de los trabajos para la automatizacion de backups
SELECT j.name AS JobName, 
       s.step_id,
       s.step_name,
       s.command
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobsteps s
    ON j.job_id = s.job_id
ORDER BY j.name, s.step_id;


-- 3) Vemos los horarios de los trabajos para la automatizacion de backups
SELECT j.name AS JobName,
       s.name AS ScheduleName,
       s.freq_type,
       s.freq_interval,
       s.active_start_time
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobschedules js
    ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules s
    ON js.schedule_id = s.schedule_id
ORDER BY j.name;





































