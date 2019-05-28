Allows developers to create a custom database object as a part of the generated application.
**SqlObject** is intended to be used as a workaround when existing DSL concepts for [database objects](Database-objects) (**Unique**, **SqlIndex**, **SqlView**, **SqlTrigger**, etc) are not sufficient.

Implemented in Rhetos package: *CommonConcepts*.

## Features

* Set custom SQL script to create and remove the object in the database.
* Define creation order of dependent database objects.
* Create database objects without transaction (full-text search index, e.g.).

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

## See also

* [Database objects](Database-objects)
