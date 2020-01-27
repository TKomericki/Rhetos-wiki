# Low-level database development

These concepts can be used to implement high-performance optimizations
that require features directly implemented in database.

> A good rule of thumb is to *avoid* these low-level concepts if you are implementing a standard business pattern.
> Seeing low-level concepts in DSL scripts is a sign that we are not looking at a standard feature, but **a very specific uncommon feature**.
> For example, if the purpose of the feature is "data validation", please use the InvalidData concept instead.
>
> Breaking down the requirements to a set of **standard business features** is a good way to make your software more maintainable.
> Also consider developing a new concept if you need to implement a standard business pattern, but there is no existing concept available.

The SQL script that creates a database object can be written in-line
(inside the .rhe script) or written in a separate file (see SqlProcedure example below).

Contents:

1. [How to (and how not to) modify the database](#how-to-and-how-not-to-modify-the-database)
2. [SqlProcedure](#sqlprocedure)
3. [SqlTrigger](#sqltrigger)
4. [SqlFunction](#sqlfunction)
5. [SqlView](#sqlview)
6. [SqlIndex](#sqlindex)
7. [SqlDefault](#sqldefault)
8. [SqlObject](#sqlobject)
9. [Dependencies between database objects](#dependencies-between-database-objects)
10. [See also](#see-also)

## How to (and how not to) modify the database

If you need to create or modify some database objects directly, the low-level concepts
from this article will allow you to do it in a DSL script,
**controlled by Rhetos**, as a part of the Rhetos deployment.
It is not recommended to modify database directly, without Rhetos:

* If you modify the database directly, outside of Rhetos deployment process,
  there is a risk that some future deployment might fail.
  * For example: if you remove an index, directly on the database,
    that Rhetos has previously created, and in the next version of the application
    the index is removed from the DSL script, Rhetos will try to remove it from the
    database on the next deployment. That will fail with an SqlException because
    the index does not exist.
  * Note that when upgrading the database, Rhetos does not compare the DSL model to the current database structure.
    Instead, it compared the DSL model to the metadata (from table Rhetos.AppliedConcepts)
    that contains information of what database objects has Rhetos previously created.
* These low-level database concepts allow developers to have a full control over
  database structure, while still providing Rhetos with control over what has been deployed.

If you need to add new database objects, outside of Rhetos deployment process,
you can do it directly in some other database schema that is not controlled by Rhetos.
For example, use `dbo` schema for you own SQL procedures that cannot be deployed with a Rhetos deployment,
or create a new schema for such objects.

## SqlProcedure

**SqlProcedure** *&lt;Module&gt;.&lt;Name&gt; &lt;ProcedureArguments&gt; &lt;ProcedureSource&gt;*

Example:

```c
Module Demo
{
    Entity Person { ShortString Name; }

    SqlProcedure ComputePersonInfo
        "@NamePattern NVARCHAR(256), @LimitResultCount INT"
        "
            SELECT TOP (@LimitResultCount)
                p.ID, Name, NameLength = LEN(p.Name), PersonID = p.ID
            FROM
                Demo.Person p
            WHERE
                p.Name LIKE '%' + @NamePattern + '%'
            ORDER BY
                p.Name
        ";
}
```

If you need to execute the stored procedure, and provide the resulting dataset in your Rhetos application,
you can use `Computed` data structure to provide the data in the application as a standard data source
(available in object model and REST Web API).
The Computed object should implement a `FilterBy` method with C# code that executes the stored procedure
with a given parameters.

For example:

```c
Module Demo
{
    Parameter PersonFilter
    {
        ShortString NamePattern;
        Integer LimitResultCount;
    }

    Computed PersonInfo 'repository => { throw new Rhetos.UserException("Use filter \"Demo.PersonFilter\" to read the data."); }'
    {
        ShortString Name;
        Integer NameLength;
        Guid PersonID;

        FilterBy PersonFilter
            '(repository, parameter) =>
            {
                // Always separate parameters to prevent SQL injection.
                string sql = "EXEC Demo.ComputePersonInfo @p0, @p1";
                var sqlParams = new object[] { parameter.NamePattern, parameter.LimitResultCount };

                var result = _executionContext.EntityFrameworkContext.Database
                    .SqlQuery<Demo.PersonInfo>(sql, sqlParams)
                    .ToArray();
                return result;
            }';
    }
}
```

## SqlTrigger

**SqlTrigger** *&lt;DataStructure&gt;.&lt;Name&gt; &lt;Events&gt; &lt;TriggerSource&gt;*

```C
SqlTrigger MailOutbox.TEMP_ToSend "AFTER INSERT"
    "SET NOCOUNT ON;
    INSERT INTO Demo.MailOutboxToSend(ID)
    SELECT
        i.ID
    FROM
        INSERTED i
    WHERE
        i.ToAddress IS NOT NULL
        OR i.ToAddress <> *";
```

## SqlFunction

**SqlFunction** *&lt;Module&gt;.&lt;Name&gt; &lt;Arguments&gt; &lt;RETURNS ... AS ... FunctionSource&gt;*

```C
SqlFunction udf_PeriodOverlap
    "@A_From datetime, @A_To datetime, @B_From datetime, @B_To datetime"
    "
        RETURNS TABLE
        AS
        RETURN
        SELECT
            ...
        FROM
            ...
    ";
```

## SqlView

**SqlView** *&lt;Module&gt;.&lt;Name&gt; &lt;ViewSource&gt;*

```C
SqlView ActiveEmployees <SQL\ActiveEmployees.sql>;
```

File "ActiveEmployees.sql" in the "SQL" subfolder

```SQL
SELECT
    ...
FROM
    ...
```

## SqlIndex

**SqlIndex** (with **Clustered**)

```C
Entity TTPayersDocumentIdentification
{
    Reference TTPayer{ Required; }
    Bool IsPowerOfAttorney;
    SqlIndex TTPayer { Clustered; }
}

Entity Log
{
    ...
    Guid ItemId { SqlIndex; }
}
```

**SqlIndexMultiple** (with **Clustered**)

```C
Entity RightToArea
{
    Reference Principal { Detail; }
    Reference County;
    Reference CityMunicipality;
    Reference Settlement;
    SqlIndexMultiple 'Principal Settlement CityMunicipality County' { Clustered; }
}
```

## SqlDefault

**SqlDefault** -
  Creates a default constraint on the specified column in the table. This concepts intended for internal system use.
  It cannot be used for setting the default value when saving an entity through the Rhetos server,
  because the server always sends the NULL value for property without set values.

```C
Entity Log
{
    DateTime Created { SqlDefault <Log.Created default.sql>; Required; }
    ...
}
```

File "Log.Created default.sql"

```SQL
getdate()
```

## SqlObject

**SqlObject** *&lt;Module&gt;.&lt;Name&gt; &lt;CreateSQL&gt; &lt;RemoveSQL&gt;* -
  Use this to create other database objects that are not supported by the other concepts, for example: full-text search index.

See the full documentation at [SqlObject concept](SqlObject-concept).

```C
Module Demo
{
    Entity Pivot10000
    {
        Integer Num;
    }

    SqlObject IX_Pivot10000
        "CREATE UNIQUE NONCLUSTERED INDEX IX_Pivot10000 ON Demo.Pivot10000 (Num)"
        "DROP INDEX Demo.Pivot10000.IX_Pivot10000"
    {
        SqlDependsOn Demo.Pivot10000;
    }
}
```

## Dependencies between database objects

To assure correct order when creating database objects, Rhetos must be informed on the dependencies between the objects.

Automatic dependency detection is not perfect but works well in practice:

**AutodetectSqlDependencies** for a Module

* Automatically detects and generates dependencies (SqlDependsOn) for SqlQueryable, SqlView, SqlFunction, SqlProcedure, SqlTrigger and LegacyEntity view. It may be applied to any of those objects or to a whole module.
* Acts globally for all objects in the module.

```C
Module Demo
{
    AutoDetectSqlDependencies;
    ...
```

**AutodetectSqlDependencies** for a data structure or an SQL object

* Acts locally for an SQL object.

```C
    SqlView HelloView 'SELECT * FROM Demo.Hello'
    {
        AutoDetectSqlDependencies;
    }
```

Other concepts for defining dependencies are rarely used, when **AutoDetectSqlDependencies** is not applicable (see below)

* `SqlDependsOn` - Declare that the concept's database implementation depends on another module, entity or a property.
* `SqlDependsOnView`
* `SqlDependsOnFunction`
* `SqlDependsOnSqlObject` - The `AutoDetectSqlDependencies` does not detect a dependency on an `SqlObject`. Use this concept to manually declare the dependency.
* `SqlDependsOnIndex`
* `SqlDependsOnID` - Dependency on ID property. Use this instead of `SqlDependsOn entity` to avoid having dependencies to all properties of the entity.
* Note: `AutoDetectSqlDependencies` can impact the deployment time in some rare scenarios: This concept detects coarse dependencies, on the level of tables and views, not on the level of columns. The `SqlDependsOn*` concepts can be used to set dependency to the specific columns. For example, if a view depends on a whole table, instead of only certain columns, adding a new column to the table would result with Rhetos re-creating the view. This is usually not a problem, unless some other database objects directly depend on that view, that are time-expensive to drop and re-create.

## See also

* [SqlObject concept](SqlObject-concept)
