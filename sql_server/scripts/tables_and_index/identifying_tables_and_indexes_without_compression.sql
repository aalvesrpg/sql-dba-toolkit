SELECT DISTINCT 
    C.[name] AS [Schema],
    A.[name] AS Tabela,
    NULL AS Indice,
    'ALTER TABLE [' + C.[name] + '].[' + A.[name] + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)' AS Comando
FROM 
    sys.tables                   A
    INNER JOIN sys.partitions    B   ON A.[object_id] = B.[object_id]
    INNER JOIN sys.schemas       C   ON A.[schema_id] = C.[schema_id]
WHERE 
    B.data_compression_desc = 'NONE'
    AND B.index_id = 0 -- HEAP
    AND A.[type] = 'U'
    
UNION
 
SELECT DISTINCT 
    C.[name] AS [Schema],
    B.[name] AS Tabela,
    A.[name] AS Indice,
    'ALTER INDEX [' + A.[name] + '] ON [' + C.[name] + '].[' + B.[name] + '] REBUILD PARTITION = ALL WITH ( STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, SORT_IN_TEMPDB = OFF, DATA_COMPRESSION = PAGE)'
FROM 
    sys.indexes                  A
    INNER JOIN sys.tables        B   ON A.[object_id] = B.[object_id]
    INNER JOIN sys.schemas       C   ON B.[schema_id] = C.[schema_id]
    INNER JOIN sys.partitions    D   ON A.[object_id] = D.[object_id] AND A.index_id = D.index_id
WHERE
    D.data_compression_desc =  'NONE'
    AND D.index_id <> 0
    AND A.[type] IN (1, 2) -- CLUSTERED INDEX e NONCLUSTERED INDEX
    AND B.[type] = 'U'
ORDER BY
    Tabela,
    Indice

-- other way

-- Identifying uncompressed tables
SELECT 
    OBJECT_SCHEMA_NAME(t.[object_id]) AS NomeEsquema,
    t.[name] AS NomeTabela,
    'Tabela' AS TipoObjeto
FROM sys.tables t
WHERE t.[is_compressed] = 0;

-- Identifying uncompressed indexes
SELECT 
    OBJECT_SCHEMA_NAME(t.[object_id]) AS NomeEsquema,
    t.[name] AS NomeTabela,
    i.[name] AS NomeIndice,
    'Índice' AS TipoObjeto
FROM sys.tables t
INNER JOIN sys.indexes i ON t.[object_id] = i.[object_id]
WHERE i.[type] > 0 AND i.[is_compressed] = 0;
