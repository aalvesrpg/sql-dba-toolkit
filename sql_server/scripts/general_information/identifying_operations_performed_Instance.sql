DECLARE @ds_arquivo_trace VARCHAR(255) = (SELECT SUBSTRING([path], 0, LEN([path])-CHARINDEX('\', REVERSE([path]))+1) + '\Log.trc' FROM sys.traces WHERE is_default = 1)
 
SELECT
    A.HostName,
    A.ApplicationName,
    A.NTUserName,
    A.NTDomainName,
    A.LoginName,
    A.SPID,
    A.EventClass,
    B.name,
    A.EventSubClass,
    A.TextData,
    A.StartTime,
    A.DatabaseName,
    A.ObjectID,
    A.ObjectName,
    A.TargetLoginName,
    A.TargetUserName
FROM
    [fn_trace_gettable](@ds_arquivo_trace, DEFAULT) A
    JOIN master.sys.trace_events B ON A.EventClass = B.trace_event_id
WHERE
    A.EventClass IN ( 164, 46, 47, 108, 110, 152 ) 
    AND A.StartTime >= GETDATE()-7
    AND A.LoginName NOT IN ( 'NT AUTHORITY\NETWORK SERVICE' )
    AND A.LoginName NOT LIKE '%SQLTELEMETRY$%'
    AND A.DatabaseName <> 'tempdb'
    AND NOT (B.name LIKE 'Object:%' AND A.ObjectName IS NULL )
    AND A.ObjectName <> 'telemetry_xevents'
    AND NOT (A.ApplicationName LIKE 'Red Gate%' OR A.ApplicationName LIKE '%Intellisense%' OR A.ApplicationName = 'DacFx Deploy')
ORDER BY
    StartTime DESC;

-- OR

SELECT
    [EventTime],
    [DatabaseName],
    [ObjectName],
    [EventType],
    [TSQLCommand]
FROM
(
    SELECT
        [DatabaseName] = DB_NAME(dest.[database_id]),
        dest.[object_name],
        dest.[type_desc],
        dest.[event_time],
        dest.[statement],
        [TSQLCommand] = 
            CASE 
                WHEN dest.[type] = 'RF' THEN 'REVERT'
                ELSE dest.[statement]
            END,
        [EventType] = 
            CASE 
                WHEN dest.[type] = 'RF' THEN 'REVERT'
                WHEN dest.[type] = 'SP' THEN 'Stored Procedure'
                WHEN dest.[type] = 'TR' THEN 'Trigger'
                WHEN dest.[type] = 'V' THEN 'View'
                WHEN dest.[type] = 'P' THEN 'SQL Stored Procedure'
                WHEN dest.[type] = 'FN' THEN 'SQL Scalar Function'
                WHEN dest.[type] = 'TF' THEN 'SQL Table Function'
                WHEN dest.[type] = 'U' THEN 'Table'
                WHEN dest.[type] = 'AF' THEN 'Aggregate Function'
                ELSE 'Unknown'
            END
    FROM sys.dm_ddl_log_events dest
) AS DDLLog
ORDER BY [EventTime] DESC;