# Migrating from datetime to datetime2

Contents:

1. [DateTime2 and Rhetos versions](#datetime2-and-rhetos-versions)
2. [Changes in application code](#changes-in-application-code)
3. [Database update](#database-update)
4. [Optimized database update](#optimized-database-update)
   1. [Example 1: Create a migration script, and execute it manually](#example-1-create-a-migration-script-and-execute-it-manually)
   2. [Example 2: DateMigration script that automatically executes on dbupdate](#example-2-datemigration-script-that-automatically-executes-on-dbupdate)

## DateTime2 and Rhetos versions

Before Rhetos v4.3, the DateTime property concept generated *datetime* column in database.
Since v4.3, it can be configured to generate **datetime** or newer **datetime2** column type.

* For backward compatibility, Rhetos v4.3 generates *datetime* column type by default.
  The *datetime2* column type can be enabled by setting the
  [build option](Configuration-management#build-configuration)
  "CommonConcepts:UseLegacyMsSqlDateTime" to false.
  Rhetos v5.0 and later generates *datetime2* by default.
* For new applications it is recommended to use *datetime2*.

By default, Rhetos will the create *datetime2* column type with **millisecond** precision: `datetime2(3)`.

## Changes in application code

When migrating the existing application from *datetime* to *datetime2*,
review [Difference between DateTime and DateTime2 DataType](https://sqlhints.com/tag/datetime-vs-datetime2/)
and check if your application code needs to be updated.

The most common changes in the existing application code are:

1. Replace `datetime` to `datetime2` in custom SQL code. This includes .sql file, .rhe files,
   and any SQL code generators in .cs files.
2. Replace every `GETDATA()` function call with `SYSDATETIME()`.
3. There are other less common changes mentioned in the linked article above.
   For example, '-' operator in T-SQL returns time difference between two *datetime* values,
   but raises an SQL error on *datetime2* values. Use DATEDIFF function instead.

## Database update

If a Rhetos application is built with *datetime2* column type enabled,
Rhetos will automatically modify the columns in database on next database update.
Downgrade is also automatically handled.

## Optimized database update

The generic Rhetos database update process is robust, but can be slow on large databases:
It would drop old *datetime* columns, create new ones and migrates the data.

If your database has *datetime* columns with more then 1 million rows, you may consider manually
updating the column type and Rhetos metadata in the database with a migration script.

The migration script should be **reviewed and customized** if needed, before the update on a large database.
The following utility scripts **create and optionally execute the migration script**, see the instructions below.

### Example 1: Create a migration script, and execute it manually

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

See https://github.com/Rhetos/Rhetos/wiki/Migrating-from-DateTime-to-DateTime2 for more info.
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

SELECT DISTINCT
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

### Example 2: DateMigration script that automatically executes on dbupdate

This script may be customized to execute automatically on database update
(as a standard Rhetos data-migration script), but in that case it should be made more robust:

1. Limit its scope to only process the largest columns.
2. Modify the script to handle custom objects that might interfere with column type change
   (see "CUSTOM" in the script below)
3. Make sure it can be executed even on an empty database, containing only objects from
   the "Rhetos" schema (for example, check if a custom db object exists before dropping it).

```sql
/*DATAMIGRATION 735DF205-AAE8-4D08-950F-778E3AFB3393*/

/*
This script optimizes Rhetos update from datatime to datetime2 db type.

Before changing the column type, this script automatically drops any dependend objects
(for example indexes on datetime columns), and recreates them after modifying the column type.

It can be customized for any exception in the custom code:

1. To remove custom database objects that could block the update, are not needed in the database
   (see "CUSTOM DB CLEANUP BEFORE MIGRATION" below).
2. To include missing dependencies for custom database objects
   (see "CUSTOM OBJECTS ADDED TO THE DEPENDENCY LIST" below).
3. To exclude unneeded drop&create of dependent custom objects that are not affected by modification of the column type
   (see "CUSTOM OBJECTS REMOVED FROM THE DEPENDENCY LIST" below).

See https://github.com/Rhetos/Rhetos/wiki/Migrating-from-DateTime-to-DateTime2 for more info.
*/

DECLARE @sql nvarchar(max) = '';

-- CUSTOM DB CLEANUP BEFORE MIGRATION:
-- EXAMPLE: SELECT @sql = @sql + 'DROP INDEX IF EXISTS ...;' + CHAR(13) + CHAR(10);

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

SELECT DISTINCT
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

        -- CUSTOM OBJECTS ADDED TO THE DEPENDENCY LIST, IF AN OBJECT IS MISSING DEPENDENCY TO THE DATATIME PROPERTY.
        -- EXAMPLE: AND dc.CreateQuery LIKE '%' + ColumnName + '%' OR dc.CreateQuery LIKE '%__cus_Warehouse_DocumentCurrentState_StateID%')

        -- CUSTOM OBJECTS REMOVED FROM THE DEPENDENCY LIST, FOR OBJECT THAT DON'T AFFECT DATATIME PROPERTY MIGRATION.
        -- EXAMPLE: AND dc.CreateQuery NOT LIKE 'CREATE OR ALTER VIEW %'
WHERE
    dc.CreateQuery <> '';

SELECT @sql = @sql + CHAR(13) + CHAR(10) + '--=== DROP DEPENDENT CONCEPTS ===--' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10);

SELECT
    @sql = @sql + '-- ' + d.ConceptInfoKey + ':' + CHAR(13) + CHAR(10) + d.RemoveQuery + CHAR(13) + CHAR(10)
FROM
    #DependentConcepts d
ORDER BY
    d.ModificationOrder DESC;

SELECT @sql = @sql + CHAR(13) + CHAR(10) + '--=== ALTER DATETIME COLUMNS AND RHETOS METADATA ===--' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10);

SELECT
    @sql = @sql + 'ALTER TABLE [' + SchemaName + '].[' + TableName + '] ALTER COLUMN [' + ColumnName + '] datetime2(3);' + CHAR(13) + CHAR(10)
    + 'UPDATE Rhetos.AppliedConcept SET CreateQuery = REPLACE(CreateQuery, ''ADD ' + ColumnName + ' DATETIME '', ''ADD '
    + ColumnName + ' DATETIME2(3) '') WHERE ID = ''' + CONVERT(varchar(100), ID) + ''''
    + CHAR(13) + CHAR(10)
FROM
    #DateTimeProperties
ORDER BY
    SchemaName, TableName, ColumnName;

SELECT @sql = @sql + CHAR(13) + CHAR(10) + '--=== CREATE DEPENDENT CONCEPTS AGAIN ===--' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10);

SELECT
    @sql = @sql + '-- ' + d.ConceptInfoKey + ':' + CHAR(13) + CHAR(10) + d.CreateQuery + CHAR(13) + CHAR(10)
FROM
    #DependentConcepts d
ORDER BY
    d.ModificationOrder;

IF @@TRANCOUNT = 0 BEGIN RAISERROR('Run this in a transaction.', 16, 10); RETURN; END
SELECT @sql;
EXEC sp_executesql @sql;

GO
DROP TABLE #DateTimeProperties;
DROP TABLE #DependentConcepts;
```
