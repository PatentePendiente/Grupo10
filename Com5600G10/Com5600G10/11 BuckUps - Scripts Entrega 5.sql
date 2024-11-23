/*				--Trabajo Integrador de Base de Datos Aplicada--
Materia: Bases de Datos Aplicada
Fecha: 1/11/2024
Entrega Nro: 5 Back-ups
Grupo 10 sqLite, Integrantes:
-RAMATO, RODRIGO EXEQUIEL       -- 45129672	
-MOSCOSO RENDON, JUAN DIEGO     -- 95472958
-VARELA, DANIEL MARIANO			-- 40388978


INDICE: 
1) Creacion del para hacer backup de las ventas del supermercado
2) Automatizacion del backup de las ventas del supermercado
3) Automatizacion del backup del reporte mensual
4) Automatizacion del backup del reporte trimestral
5) Automatizacion del backup de los productos vendidos por sucursal
6) Automatizacion del backup de los productos mas vendidos por semana en el mes
7) Automatizacion del backup de los productos menos vendidos en el mes
*/


-- 1) Creacion del para hacer backup de las ventas del supermercado
CREATE OR ALTER PROCEDURE DBA.BackupVentas
AS
BEGIN
    -- Generamos el XML para la tabla DetalleVenta
    PRINT 'DetalleVenta XML:';

    SELECT * 
    FROM INV.DetalleVenta
    FOR XML PATH('DetalleVenta'), ROOT('Ventas');

    -- Generamos el XML para la tabla Factura
    PRINT 'Factura XML:';

    SELECT * 
    FROM INV.Factura
    FOR XML PATH('Factura'), ROOT('Facturas')
END;
GO

-- 2) Automatizacion del backup de las ventas del supermercado
-- Creacion del trabajo en SQL Server Agent para ejecutar el procedimiento semanalmente
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Ejecucion_Semanal_Ventas')
BEGIN
    -- Creamos el trabajo
    EXEC msdb.dbo.sp_add_job
        @job_name = N'Ejecucion_Semanal_Ventas',
        @description = N'Ejecución automática semanal del procedimiento BackupVentas';

    -- Agregamos un paso al trabajo para ejecutar el stored procedure
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Ejecucion_Semanal_Ventas',
        @step_name = N'Ejecutar BackupVentas',
        @subsystem = N'TSQL',
        @command = N'EXEC DBA.BackupVentas;',
        @database_name = N'Com5600G10',
        @retry_attempts = 3,  -- Intentar hasta 3 veces si falla
        @retry_interval = 5;  -- Esperar 5 minutos entre intentos

    -- Creamos un horario para ejecutar el trabajo semanalmente a las 3:00 AM
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Ejecucion_Semanal_3AM_Ventas',
        @freq_type = 8, -- Semanal
        @freq_interval = 1, -- Cada semana
        @freq_recurrence_factor = 1, -- Necesario para frecuencia semanal
        @active_start_time = 30000; -- 3:00 AM

    -- Adjuntamos el horario al trabajo
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'Ejecucion_Semanal_Ventas',
        @schedule_name = N'Ejecucion_Semanal_3AM_Ventas';

    -- Habilitamos el trabajo
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'Ejecucion_Semanal_Ventas';

    PRINT 'El trabajo "Ejecucion_Semanal_Ventas" ha sido creado exitosamente.';
END
ELSE
    PRINT 'El trabajo "Ejecucion_Semanal_Ventas" ya existe.';
GO


-- 3) Automatizacion del backup del reporte mensual
-- Creamos un trabajo en SQL Server Agent para el backup mensual del reporte
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Backup_Reporte_Mensual')
BEGIN
    -- Creamos el trabajo para el backup del reporte mensual
    EXEC msdb.dbo.sp_add_job
        @job_name = N'Backup_Reporte_Mensual',
        @description = N'Backup automático del reporte mensual de ventas';

    -- Agregamos un paso al trabajo para ejecutar el stored procedure que genera el reporte
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Backup_Reporte_Mensual',
        @step_name = N'Ejecutar Backup Reporte Mensual',
        @subsystem = N'TSQL',
        @command = N'
            -- Declaramos las variables para el mes y anio actual
            DECLARE @mes INT = MONTH(GETDATE());
            DECLARE @anio INT = YEAR(GETDATE());
            
            -- Ejecutamos el stored procedure que genera el reporte
            EXEC Reportes.ProductosMasVendidosPorSemanaEnElMesXML @mes, @anio;',
        @database_name = N'Com5600G10',
        @retry_attempts = 3,  -- Intentar hasta 3 veces si falla
        @retry_interval = 5;  -- Esperar 5 minutos entre intentos

    -- Creamos un horario para ejecutar el trabajo el primer día de cada mes a las 3:00 AM
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Ejecucion_Mensual_3AM',
        @freq_type = 16, -- Mensual
        @freq_interval = 1, -- Día 1 del mes
        @freq_recurrence_factor = 1, -- Necesario para frecuencia mensual
        @active_start_time = 30000; -- 3:00 AM

    -- Adjuntamos el horario al trabajo
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'Backup_Reporte_Mensual',
        @schedule_name = N'Ejecucion_Mensual_3AM';

    -- Habilitamos el trabajo
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'Backup_Reporte_Mensual';

    PRINT 'El trabajo "Backup_Reporte_Mensual" ha sido creado exitosamente.';
END
ELSE
    PRINT 'El trabajo "Backup_Reporte_Mensual" ya existe.';
GO


-- 4) Automatizacion del backup del reporte trimestral
-- Creamos un trabajo en SQL Server Agent para el backup trimestral del reporte
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Backup_Reporte_Trimestral')
BEGIN
    -- Creamos el trabajo para el backup del reporte trimestral
    EXEC msdb.dbo.sp_add_job
        @job_name = N'Backup_Reporte_Trimestral',
        @description = N'Backup automático del reporte trimestral de ventas por turnos';

    -- Agregamos un paso al trabajo para ejecutar el stored procedure que genera el reporte
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Backup_Reporte_Trimestral',
        @step_name = N'Ejecutar Backup Reporte Trimestral',
        @subsystem = N'TSQL',
        @command = N'
            -- Ejecutamos el stored procedure que genera el reporte trimestral
            EXEC Reportes.UltimosTresMesesPorTurnosXML;',
        @database_name = N'Com5600G10',
        @retry_attempts = 3,  -- Intentar hasta 3 veces si falla
        @retry_interval = 5;  -- Esperar 5 minutos entre intentos

    -- Creamos un horario para ejecutar el trabajo el primer día de cada tercer mes a las 3:00 AM
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Ejecucion_Trimestral_3AM',
        @freq_type = 8, -- Trimestral
        @freq_interval = 1, -- Cada 3 meses
        @freq_recurrence_factor = 3, -- Necesario para frecuencia trimestral
        @active_start_time = 30000; -- 3:00 AM

    -- Adjuntamos el horario al trabajo
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'Backup_Reporte_Trimestral',
        @schedule_name = N'Ejecucion_Trimestral_3AM';

    -- Habilitamos el trabajo
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'Backup_Reporte_Trimestral';

    PRINT 'El trabajo "Backup_Reporte_Trimestral" ha sido creado exitosamente.';
END
ELSE
    PRINT 'El trabajo "Backup_Reporte_Trimestral" ya existe.';
GO


-- 5) Automatizacion del backup de los productos vendidos por sucursal
-- Creamos un trabajo en SQL Server Agent para el backup mensual del reporte de productos vendidos por sucursal
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Backup_Reporte_Mensual_Sucursal')
BEGIN
    -- Creamos el trabajo para el backup del reporte mensual de productos vendidos por sucursal
    EXEC msdb.dbo.sp_add_job
        @job_name = N'Backup_Reporte_Mensual_Sucursal',
        @description = N'Backup automático del reporte mensual de productos vendidos por sucursal';

    -- Agregamos un paso al trabajo para ejecutar el stored procedure que genera el reporte
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Backup_Reporte_Mensual_Sucursal',
        @step_name = N'Ejecutar Backup Reporte Mensual Sucursal',
        @subsystem = N'TSQL',
        @command = N'
            -- Declaramos las variables para el mes y anio actual
            DECLARE @FechaInicio DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            DECLARE @FechaFin DATE = DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1);
            
            -- Ejecutamos el stored procedure que genera el reporte
            EXEC Reportes.ProductosVendidosPorSucursalEntreDosFechasXML @FechaInicio, @FechaFin;',
        @database_name = N'Com5600G10',
        @retry_attempts = 3,  -- Intentar hasta 3 veces si falla
        @retry_interval = 5;  -- Esperar 5 minutos entre intentos

    -- Creamos un horario para ejecutar el trabajo el primer día de cada mes a las 3:00 AM
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Ejecucion_Mensual_3AM_Sucursal',
        @freq_type = 16, -- Mensual
        @freq_interval = 1, -- Día 1 del mes
        @freq_recurrence_factor = 1, -- Necesario para frecuencia mensual
        @active_start_time = 30000; -- 3:00 AM

    -- Adjuntamos el horario al trabajo
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'Backup_Reporte_Mensual_Sucursal',
        @schedule_name = N'Ejecucion_Mensual_3AM_Sucursal';

    -- Habilitamos el trabajo
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'Backup_Reporte_Mensual_Sucursal';

    PRINT 'El trabajo "Backup_Reporte_Mensual_Sucursal" ha sido creado exitosamente.';
END
ELSE
    PRINT 'El trabajo "Backup_Reporte_Mensual_Sucursal" ya existe.';
GO

-- 6) Automatizacion del backup de los productos mas vendidos por semana en el mes
-- Creamos un trabajo en SQL Server Agent para el backup mensual del reporte de productos más vendidos por semana en el mes
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Backup_Reporte_Mensual_ProductosMasVendidos')
BEGIN
    -- Creamos el trabajo para el backup del reporte mensual de productos más vendidos por semana en el mes
    EXEC msdb.dbo.sp_add_job
        @job_name = N'Backup_Reporte_Mensual_ProductosMasVendidos',
        @description = N'Backup automático del reporte mensual de productos más vendidos por semana en el mes';

    -- Agregamos un paso al trabajo para ejecutar el stored procedure que genera el reporte
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Backup_Reporte_Mensual_ProductosMasVendidos',
        @step_name = N'Ejecutar Backup Reporte Mensual Productos Mas Vendidos',
        @subsystem = N'TSQL',
        @command = N'
            -- Declaramos las variables para el mes y anio actual
            DECLARE @mes INT = MONTH(GETDATE());
            DECLARE @anio INT = YEAR(GETDATE());
            
            -- Ejecutamos el stored procedure que genera el reporte
            EXEC Reportes.ProductosMasVendidosPorSemanaEnElMesXML @mes, @anio;',
        @database_name = N'Com5600G10',
        @retry_attempts = 3,  -- Intentar hasta 3 veces si falla
        @retry_interval = 5;  -- Esperar 5 minutos entre intentos

    -- Creamos un horario para ejecutar el trabajo el primer día de cada mes a las 3:00 AM
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Ejecucion_Mensual_3AM_ProductosMasVendidos',
        @freq_type = 16, -- Mensual
        @freq_interval = 1, -- Día 1 del mes
        @freq_recurrence_factor = 1, -- Necesario para frecuencia mensual
        @active_start_time = 30000; -- 3:00 AM

    -- Adjuntamos el horario al trabajo
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'Backup_Reporte_Mensual_ProductosMasVendidos',
        @schedule_name = N'Ejecucion_Mensual_3AM_ProductosMasVendidos';

    -- Habilitamos el trabajo
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'Backup_Reporte_Mensual_ProductosMasVendidos';

    PRINT 'El trabajo "Backup_Reporte_Mensual_ProductosMasVendidos" ha sido creado exitosamente.';
END
ELSE
    PRINT 'El trabajo "Backup_Reporte_Mensual_ProductosMasVendidos" ya existe.';
GO


-- 7) Automatizacion del backup de los productos menos vendidos en el mes
-- Creamos un trabajo en SQL Server Agent para el backup mensual del reporte de productos menos vendidos en el mes
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Backup_Reporte_Mensual_ProductosMenosVendidos')
BEGIN
    -- Creamos el trabajo para el backup del reporte mensual de productos menos vendidos en el mes
    EXEC msdb.dbo.sp_add_job
        @job_name = N'Backup_Reporte_Mensual_ProductosMenosVendidos',
        @description = N'Backup automático del reporte mensual de productos menos vendidos en el mes';

    -- Agregamos un paso al trabajo para ejecutar el stored procedure que genera el reporte
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Backup_Reporte_Mensual_ProductosMenosVendidos',
        @step_name = N'Ejecutar Backup Reporte Mensual Productos Menos Vendidos',
        @subsystem = N'TSQL',
        @command = N'
            -- Declaramos las variables para el mes y anio actual
            DECLARE @mes INT = MONTH(GETDATE());
            DECLARE @anio INT = YEAR(GETDATE());
            
            -- Ejecutamos el stored procedure que genera el reporte
            EXEC Reportes.ProductosMenosVendidosEnElMesXML @mes, @anio;',
        @database_name = N'Com5600G10',
        @retry_attempts = 3,  -- Intentar hasta 3 veces si falla
        @retry_interval = 5;  -- Esperar 5 minutos entre intentos

    -- Creamos un horario para ejecutar el trabajo el primer día de cada mes a las 3:00 AM
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Ejecucion_Mensual_3AM_ProductosMenosVendidos',
        @freq_type = 16, -- Mensual
        @freq_interval = 1, -- Día 1 del mes
        @freq_recurrence_factor = 1, -- Necesario para frecuencia mensual
        @active_start_time = 30000; -- 3:00 AM

    -- Adjuntamos el horario al trabajo
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'Backup_Reporte_Mensual_ProductosMenosVendidos',
        @schedule_name = N'Ejecucion_Mensual_3AM_ProductosMenosVendidos';

    -- Habilitamos el trabajo
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'Backup_Reporte_Mensual_ProductosMenosVendidos';

    PRINT 'El trabajo "Backup_Reporte_Mensual_ProductosMenosVendidos" ha sido creado exitosamente.';
END
ELSE
    PRINT 'El trabajo "Backup_Reporte_Mensual_ProductosMenosVendidos" ya existe.';
GO


-- 8) Automatizacion del backup del reporte diario de total acumulado de ventas para una localidad y fecha
-- Creamos un SQL Server Agent job para el backup diario del reporte de total acumulado de ventas para una localidad y fecha
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Backup_Reporte_Diario_TotalAcumuladoVentas')
BEGIN
    -- Creamos el job para el backup del reporte diario de total acumulado de ventas para una localidad y fecha
    EXEC msdb.dbo.sp_add_job
        @job_name = N'Backup_Reporte_Diario_TotalAcumuladoVentas',
        @description = N'Backup automático del reporte diario de total acumulado de ventas para una localidad y fecha';

    -- Agregamos un paso al trabajo para ejecutar el stored procedure que genera el reporte
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Backup_Reporte_Diario_TotalAcumuladoVentas',
        @step_name = N'Ejecutar Backup Reporte Diario Total Acumulado Ventas',
        @subsystem = N'TSQL',
        @command = N'
            -- Declaramos las variables para la fecha actual
            DECLARE @Fecha DATE = GETDATE();
            DECLARE @Localidad NVARCHAR(100) = ''NombreDeLaLocalidad''; -- Reemplazar con la localidad deseada
            
            -- Ejecutamos el stored procedure que genera el reporte
            EXEC Reportes.TotalAcumuladoVentasParaUnaLocalidadYFechaXML @Localidad, @Fecha;',
        @database_name = N'Com5600G10',
        @retry_attempts = 3,  -- Intentar hasta 3 veces si falla
        @retry_interval = 5;  -- Esperar 5 minutos entre intentos

    -- Creamos un horario para ejecutar el trabajo diariamente a las 3:00 AM
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Ejecucion_Diaria_3AM_TotalAcumuladoVentas',
        @freq_type = 4, -- Diario
        @freq_interval = 1, -- Cada 1 día
        @active_start_time = 30000; -- 3:00 AM

    -- Adjuntamos el horario al trabajo
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'Backup_Reporte_Diario_TotalAcumuladoVentas',
        @schedule_name = N'Ejecucion_Diaria_3AM_TotalAcumuladoVentas';

    -- Habilitarmos el trabajo
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'Backup_Reporte_Diario_TotalAcumuladoVentas';

    PRINT 'El trabajo "Backup_Reporte_Diario_TotalAcumuladoVentas" ha sido creado exitosamente.';
END
ELSE
    PRINT 'El trabajo "Backup_Reporte_Diario_TotalAcumuladoVentas" ya existe.';
GO










































