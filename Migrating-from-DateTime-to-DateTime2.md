# Migrating from DateTime to DateTime2

Since Rhetos 4.3, the DateTime property concept can generate *DateTime2* column in database,
instead of old *DateTime* column type.
This behavior is configurable and disabled by default in Rhetos 4.3, for backward compatibility.

The DateTime2 column type can be enabled by setting the [build option](https://github.com/Rhetos/Rhetos/wiki/Configuration-management#build-configuration)
"CommonConcepts:UseLegacyMsSqlDateTime" to false.

**If the application is built with this option, Rhetos will automatically modify the column type on next database upgrade.**

## Optimized database upgrade

The standard Rhetos database upgrade process is robust, but can be slow on large databases.

If your database has datetime columns with more then 1 million rows, you may consider manually
updating the column type and Rhetos metadata in the database with a migration script.

The migration script should be manually reviewed and executed before the upgrade on a large database.
The following scripts will **create** the migration script, see **instructions** below.

It could be modified to run on upgrade and automatically execute the generated script
(as a standard Rhetos data-migration script), but in that case it should be made more robust
by limiting its scope to only the few largest columns and modified to check if each column
currently existing in the database.

```sql
--======================================================================================
/*
Instructions:

1. This script creates a migration script for DateTime columns. The migration script should be generated, reviewed and executed just before upgrading the database.
2. Before running this scripts, prepare the output string formatting in SSMS:
   - Tools => Options => Query Results => SQL Server => Results to Test => Output format: "Tab delimited", Maximum number of characters: "1000000".
   - Reopen the SQL script in SSMS (the above settings are not applyed to currently open scripts).
   - Query => Results To => Results to Text.
3. *Review* the generated migration script for any issues and *edit* it manually if needed.
*/
--======================================================================================

SET NOCOUNT ON;

SELECT
    ID,
    CreateQuery,
    PARSENAME(REPLACE(ConceptInfoKey, 'PropertyInfo ', ''), 3) AS SchemaName,
    PARSENAME(REPLACE(ConceptInfoKey, 'PropertyInfo ', ''), 2) AS TableName,
    PARSENAME(REPLACE(ConceptInfoKey, 'PropertyInfo ', ''), 1) AS ColumnName
INTO
    #DateTimeProperties
FROM
    Rhetos.AppliedConcept c
WHERE
    c.InfoType LIKE 'Rhetos.Dsl.DefaultConcepts.DateTimePropertyInfo%'
    AND c.CreateQuery LIKE 'ALTER TABLE % ADD % DATETIME %';

--===============================================================================

SELECT
    DateTimeColumn = c.CreateQuery,
    dc.ConceptInfoKey,
    dc.CreateQuery,
    dc.RemoveQuery,
    dc.ModificationOrder
INTO
    #DependentConcepts
FROM
    #DateTimeProperties c
    -- Indirect dependencies should not be an issue. The objects we are interested in here can be expected to have a direct dependency.
    LEFT JOIN Rhetos.AppliedConceptDependsOn d ON d.DependsOnID = c.ID
    -- Dependent objects need to be removed before ALTER COLUMN.
    LEFT JOIN Rhetos.AppliedConcept dc ON dc.ID = d.DependentID
        -- Views, functions, stored procedures and triggers will not cause issues on alter column, they don't need to be removed.
        AND dc.CreateQuery NOT LIKE 'CREATE VIEW %'
        AND dc.CreateQuery NOT LIKE 'CREATE FUNCTION %'
        AND dc.CreateQuery NOT LIKE 'CREATE PROCEDURE %'
        AND dc.CreateQuery NOT LIKE 'CREATE TRIGGER %'
WHERE
    dc.CreateQuery <> '';

--===============================================================================

SELECT 'BEGIN TRAN';

SELECT '--=== DROP DEPENDENT CONCEPTS ===--';

SELECT
    '-- ' + d.ConceptInfoKey + ':' + CHAR(13) + CHAR(10) + d.RemoveQuery
FROM
    #DependentConcepts d
ORDER BY
    d.ModificationOrder DESC;

SELECT '--=== ALTER DATETIME COLUMNS AND RHETOS METADATA ===--';

SELECT
    'ALTER TABLE [' + SchemaName + '].[' + TableName + '] ALTER COLUMN [' + ColumnName + '] datetime2(3);' + CHAR(13) + CHAR(10)
    + 'UPDATE Rhetos.AppliedConcept SET CreateQuery = REPLACE(CreateQuery, ''ADD ' + ColumnName + ' DATETIME '', ''ADD ' + ColumnName + ' DATETIME2(3) '') WHERE ID = ''' + CONVERT(varchar(100), ID) + ''''
FROM
    #DateTimeProperties
ORDER BY
    SchemaName, TableName, ColumnName;

SELECT '--=== CREATE DEPENDENT CONCEPTS AGAIN ===--'

SELECT
    '-- ' + d.ConceptInfoKey + ':' + CHAR(13) + CHAR(10) + d.CreateQuery
FROM
    #DependentConcepts d
ORDER BY
    d.ModificationOrder;

SELECT 'GO';

GO
DROP TABLE #DateTimeProperties;
DROP TABLE #DependentConcepts;
```
