December 19 - merge conflict test. this file will have confilct with another
this is a change to the SP
This is a better change to save to master
This is the second line added to this file for a second test
This line is added for merge test in gitHub on December 18, 2017

-- Possible Bad NC Indexes (writes > reads)
SELECT OBJECT_NAME(s.[object_id]) AS [Table Name],
i.name AS [Index Name], i.index_id,
user_updates AS [Total Writes],
user_seeks + user_scans + user_lookups AS [Total Reads],
user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND s.database_id = DB_ID()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1
ORDER BY [Difference] DESC, [Total Writes] DESC,
[Total Reads] ASC OPTION (RECOMPILE);

-- Look for indexes with high numbers of writes
-- and zero or a very low numbers of reads
-- Consider your complete workload
-- Investigate further before dropping an index

-- Missing Indexes current database by Index Advantage
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)
AS [index_advantage],
migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks,
migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID() -- Remove this to see for entire instance
ORDER BY index_advantage DESC OPTION (RECOMPILE);

-- Look at last user seek time, number of user seeks
-- to help determine source and importance
-- SQL Server is overly eager to add included columns, so beware
-- Do not just blindly add indexes that show up from this query!!!



-- Index Read/Write stats for a single table
SELECT OBJECT_NAME(s.[object_id]) AS [TableName],
i.name AS [IndexName], i.index_id,
SUM(user_seeks) AS [User Seeks], SUM(user_scans) AS [User Scans],
SUM(user_lookups)AS [User Lookups],
SUM(user_seeks + user_scans + user_lookups)AS [Total Reads],
SUM(user_updates) AS [Total Writes]
FROM sys.dm_db_index_usage_stats AS s
INNER JOIN sys.indexes AS i
ON s.[object_id] = i.[object_id]
AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND s.database_id = DB_ID()
AND OBJECT_NAME(s.[object_id]) = N'ACCOUNT'
GROUP BY OBJECT_NAME(s.[object_id]), i.name, i.index_id
ORDER BY [Total Writes] DESC, [Total Reads] DESC OPTION (RECOMPILE);


-- Missing indexes for a single table
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)
AS index_advantage, migs.last_user_seek,
mid.statement AS 'Database.Schema.Table',
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks,
migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
-- Specify one database, schema,table
WHERE [statement] = N'[Prod_ERM501].[dbo].[TRANSACTION_HISTORY]'
ORDER BY index_advantage DESC OPTION (RECOMPILE);

-- Look at existing indexes
--(does not show included columns or filtered indexes)
EXEC sp_helpindex N'dbo.ActivityEvent';

-- See how big the table is
EXEC sp_spaceused N'dbo.ActivityEvent';
