# Migrating from datetime to datetime2

Before Rhetos v4.3, the DateTime property concept generated *datetime* column in database.
Since v4.3, it can be configured to generate **datetime** or newer **datetime2** column type.

* For backward compatibility, Rhetos v4.3 generates *datetime* column type by default.
  The *datetime2* column type can be enabled by setting the
  [build option](https://github.com/Rhetos/Rhetos/wiki/Configuration-management#build-configuration)
  "CommonConcepts:UseLegacyMsSqlDateTime" to false.
  Rhetos v5.0 and later generates *datetime2* by default.
* For new applications it is recommended to use *datetime2*.

Rhetos will create *datetime2* column type with millisecond precision by default: `datetime2(3)`.

## Changes in application code

Before migrating the existing application to *datetime2*,
see [Difference between DateTime and DateTime2 DataType](https://sqlhints.com/tag/datetime-vs-datetime2/)
and check if your application code needs to be updated.

For example, '-' operator in T-SQL returns time difference between two *datetime* values, but
raises an SQL error on *datetime2* values. Use DATEDIFF function instead.

## Database update

If a Rhetos application is built with *datetime2* column type enabled,
Rhetos will automatically modify the columns in database on next database update.
Downgrade is also automatically handled.

## Optimized database update

The generic Rhetos database update process is robust, but can be slow on large databases:
It would drop old *datetime* columns, create new ones and migrates the data.

If your database has *datetime* columns with more then 1 million rows, you may consider manually
updating the column type and Rhetos metadata in the database with a migration script.

The migration script should be **manually** reviewed and executed, before the update on a large database.
The following utility scripts **creates the migration script, see the instructions below.**

This script might be customized to execute automatically on database update
(as a standard Rhetos data-migration script), but in that case it should be made more robust,
by limiting its scope to only the few largest columns, and making sure it can be executed
even on an empty database.

```sql
/*
Instructions:

1. This utility script creates a migration script for DateTime columns. The migration script
   should be generated, reviewed and executed manually just before upgrading the database.
2. Before running this scripts, prepare the output string formatting in SSMS:
   - Tools => Options => Query Results => SQL Server => Results to Test => Output format: "Tab delimited", Maximum number of characters: "1000000".
   - Reopen the SQL script in SSMS (the above settings are not applied to currently open scripts).
   - Query => Results To => Results to Text.
3. *Review* the generated migration script for any issues and *edit* it manually if needed.
*/
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
    + 'UPDATE Rhetos.AppliedConcept SET CreateQuery = REPLACE(CreateQuery, ''ADD ' + ColumnName + ' DATETIME '', ''ADD '
    + ColumnName + ' DATETIME2(3) '') WHERE ID = ''' + CONVERT(varchar(100), ID) + ''''
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
