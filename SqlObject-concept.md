SqlObject allows developers to create a custom database object as a part of the generated application.

Contents:

1. [Create a custom object in the database](#create-a-custom-object-in-the-database)
2. [Dependencies and creation order of database objects](#dependencies-and-creation-order-of-database-objects)
3. [Creating database objects without transaction](#creating-database-objects-without-transaction)
4. [Splitting an SQL script to multiple batches](#splitting-an-sql-script-to-multiple-batches)
5. [Troubleshooting: Fixing an incorrect removal script](#troubleshooting-fixing-an-incorrect-removal-script)
6. [See also](#see-also)

## Create a custom object in the database

**SqlObject** is intended to be used when the existing
[DSL concepts for database objects](Database-objects) are not sufficient
(**SqlProcedure**, **SqlView**, **SqlTrigger**, **Unique**, **SqlIndex**, etc.).

For example, if you need to create a specific unique index that will *only* check for unique names
that start with letter 'A', you can write a custom database object in the DSL script.

```C
Module Demo
{
    Entity SomeEntity { ShortString Name; }

    SqlObject SomeSpecialUniqueIndex
        "CREATE UNIQUE INDEX IX_SomeSpecialUniqueIndex ON Demo.SomeEntity (Name) WHERE Name >= 'A' AND Name < 'B'"
        "DROP INDEX IX_SomeSpecialUniqueIndex ON Demo.SomeEntity"
    {
        SqlDependsOn Demo.SomeEntity.Name;
    }
}
```

SqlObject contains an arbitrary feature name (`SomeSpecialUniqueIndex`), a creation script, and a removal script:

* The **creation script** will be executed on deployment to create the object in the database.
* The **removal script** will persisted in the database for later use.
  * It will be executed on deployment to remove this object when it no longer exists
    in the new version of the application.
  * The removal script is also executed if the object needs to be regenerated
    (if the creation script is modified, or any dependent object). In that case, the old removal
    script is executed to remove the old version of the object, then the new creation script
    to create it again.
  * See below more info on removal scripts below.
* `SqlDependsOn` is required here to specify that the `SomeEntity.Name` column must be created in database
  *before* this object is created (see more info on dependencies below).

## Dependencies and creation order of database objects

Use any of the **SqlDependsOn...** concepts in an **SqlObject** to define other objects (entities, views, etc.) that need to be created before the **SqlObject**.

If another object (**SqlQueryable**, for example) depends on the **SqlObject**, use **SqlDependsOnSqlObject** to make sure that the **SqlObject** is created in database before the view from the **SqlQueryable**.

```C
Module Demo
{
    Entity SomeEntity { Integer I; }

    SqlObject SomeView
        "CREATE VIEW Demo.V1 AS SELECT ID, I+1 AS I1 FROM Demo.SomeEntity"
        "DROP VIEW Demo.V1"
    {
        SqlDependsOn Demo.SomeEntity;
    }

    SqlQueryable SomeEntityAdditionalInfo
        "SELECT ID, I1+1 AS I2 FROM Demo.V1"
    {
        Extends Demo.SomeEntity;
        Integer I2;
        SqlDependsOnSqlObject Demo.SomeView;
    }
}
```

## Creating database objects without transaction

Some database objects cannot be created in a transaction (**full-text search index** on SQL Server, e.g.).

By default, Rhetos will execute all SQL scripts in a transaction, unless the script starts with comment `/*DatabaseGenerator:NoTransaction*/`.

This example (from Rhetos unit tests) creates an SQL view, adding the transaction level (`@@TRANCOUNT`) as the suffix to the view name, to prove that the create script is executed without a transaction.

```C
Module Demo
{
    SqlObject WithoutTransaction
        "
            /*DatabaseGenerator:NoTransaction*/
            DECLARE @createView nvarchar(max);
            SET @createView = 'CREATE VIEW Demo.WithoutTransaction_' + CONVERT(NVARCHAR(max), @@TRANCOUNT) + ' AS SELECT a=1';
            EXEC (@createView);
        "
        "
            /*DatabaseGenerator:NoTransaction*/
            DECLARE @dropView nvarchar(max);
            SELECT @dropView = name FROM sys.objects o WHERE type = 'V' AND SCHEMA_NAME(schema_id) = 'Demo' AND name LIKE 'WithoutTransaction[_]%';
            SET @dropView = 'DROP VIEW Demo.' + @dropView;
            EXEC (@dropView);
        ";
}
```

## Splitting an SQL script to multiple batches

If an SQL script contains the `GO` statement (T-SQL), the deployment will fail with an error message **Incorrect syntax near 'GO'.**

Note that Rhetos internally just uses SqlCommand to directly execute the script.

Rhetos introduces a custom batch splitter "`{SPLIT SCRIPT}`" to be used in a situation
when a single SQL script must be split to multiple batches that are executed separately.

Example:

```C
Module Demo
{
    SqlObject TwoViews
        "
            CREATE VIEW Demo.V1 AS SELECT C = 1;
            {SPLIT SCRIPT}
            CREATE VIEW Demo.V2 AS SELECT C FROM V1;
        "
        "
            DROP VIEW Demo.V2;
            DROP VIEW Demo.V1;
        ";
}
```

## Troubleshooting: Fixing an incorrect removal script

If there is an error in SqlObject removal script (for example, if deployment fails with a database error),
it is not possible to simply fix it in the DSL script.

* When removing an old version of SqlObject from the database, Rhetos will use the *old version*
  of the SQL script, because the new removal script might be specific to the new version of the object.

For example, the following removal script will result with `Incorrect syntax` error on deployment,
when the existing object is modified or removed, because of the incorrect `DDDDROP` command.

```c
SqlObject SomeSpecialUniqueIndex
    "CREATE UNIQUE INDEX IX_SomeSpecialUniqueIndex ON Demo.SomeEntity (Name) WHERE Name >= 'A' AND Name < 'B'"
    "DDDDROP INDEX IX_SomeSpecialUniqueIndex ON Demo.SomeEntity";
```

After fixing the `DROP INDEX` command in DSL script, Rhetos will still use the old version
of the removal script (with `DDDDROP`).
The old version of the script is persisted in table Rhetos.AppliedConcept, column RemoveQuery.
If the corrupted SQL object is deployed only to your own database, you can manually fix this script in this table.
It the SQL object have already been deployed to other developers' databases or other environments,
you should write a simple data-migration scripts to fix this on every environment.

A possible solution:

```sql
/*DATAMIGRATION ... generate a new GUID here ...*/

UPDATE Rhetos.AppliedConcept
SET RemoveQuery = 'DROP INDEX IX_SomeSpecialUniqueIndex ON Demo.SomeEntity'
WHERE CreateQuery LIKE 'CREATE UNIQUE INDEX IX_SomeSpecialUniqueIndex%';
```

Note that this data-migration script doesn't need to call DataMigrationUse/Apply,
because the `Rhetos` schema contains hardcoded system tables that will exist before the script is executed.

## See also

* [Database objects](Database-objects)
