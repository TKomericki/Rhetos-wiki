Polymorphic concept is intended for implementing the application design pattern where multiple entities share common interface for reading data (defined as a list of common properties).

Similar features:

* Polymorphic concept is similar to object-oriented concept of class inheritance, but class inheritance is not used here.
* Polymorphic concept can sometimes be used as an alternative to the Extends concept.

Contents:

1. [Basic usage](#basic-usage)
2. [Referencing or extending a polymorphic entity](#referencing-or-extending-a-polymorphic-entity)
3. [Multiple interface implementations](#multiple-interface-implementations)
4. [Property implementation with subquery](#property-implementation-with-subquery)
5. [Limit the implementation with filter (where)](#limit-the-implementation-with-filter-where)
6. [Subtype implementation using SQL query](#subtype-implementation-using-sql-query)
7. [Writing efficient queries from client application](#writing-efficient-queries-from-client-application)

## Basic usage

For example, `MoneyTransaction` data structure can have multiple forms: `BorrowMoney` and `LendMoney` (see the example below).

* In this example, `MoneyTransaction` can be seen as an *interface* that is *implemented* by the concrete subtypes `BorrowMoney` and `LendMoney`.
* `MoneyTransaction` is readable data structure, it returns **union of records** from  `BorrowMoney` and `LendMoney`.

Example:

```C
Module Demo
{
    Polymorphic MoneyTransaction
    {
        DateTime EventDate;
        Money Amount;
    }

    Entity BorrowMoney
    {
        ShortString FromWhom;
        DateTime EventDate;
        Money Amount;

        Is Demo.MoneyTransaction;
        // The EventDate and Amount are automatically mapped.
    }

    Entity LendMoney
    {
        ShortString ToWhom;
        DateTime EventDate;
        Money Amount;

        Is Demo.MoneyTransaction
        {
            Implements Demo.MoneyTransaction.Amount '-Amount';
            // The Amount in the MoneyTransaction related to the LendMoney record will have negative value.
        }
    }
}
```

Note that:

* The `MoneyTransaction.Amount` property is automatically mapped to the `BorrowMoney.Amount` property with the same name;
* In the `LendMoney` entity, the `MoneyTransaction.Amount` property is implemented by a specific SQL expression `-Amount`. See the generated SQL view `Demo.LendMoney_As_MoneyTransaction` to check the impact of that expression.

## Referencing or extending a polymorphic entity

A polymorphic data structure may be referenced or extended by other entities (Browse is also an extension).
Rhetos will check the **reference constraint** on data modifications.

```C
Entity TransactionComment
{
    Reference MoneyTransaction;
    LongString Comment;
}
```

Internally, the reference is implemented as a foreign key in database: from the `TransactionComment` table to the automatically generated `MoneyTransaction_Materialized` table.
The `MoneyTransaction_Materialized` table contains union of IDs from all MoneyTransaction subtypes: `BorrowMoney` and `LendMoney`.
The redundant IDs are automatically updated when inserting or deleting the subtype entities' records.

Additional considerations on the polymorphic materialization:

* The "materialized" table is an automatically generated Entity.
  Internally, its data is automatically maintained by generated concepts ComputedFrom and KeepSynchronized
  (see [Persisting the computed data](Persisting-the-computed-data)).
* If where are no references or extensions to the polymorphic,
  but you still want to create the materialized table,
  you can manually create it by adding the `Materialized;` keyword in the polymorphic.
* The materialized table contains only ID column by default,
  by you could manually adding an additional polymorphic property to the entity
  and map it to the source with ComputedFrom concept on each property.
* When materializing a polymorphic, there is a *restriction* to its implementations:
  **Each implementation** of the polymorphic should have a **stable ID value**.
  This is required to allow automatic update of cached data in the materialized table.
  For example, it the implementation is entity, its ID values are stable because they are
  generated when saving the records,
  but if the implementation is SqlQueryable, you should **avoid** code like `ID = NEWID()`.
  The view that implements the materialized polymorphic should return the same (and unique)
  ID values on each read if the source data has not changed.

## Multiple interface implementations

An entity may implement multiple interfaces.
It can even implement the same interface multiple times, using additional string parameter *ImplementationName* to distinguish the implementations.

For example, the `TransferMoney` entity record may represent two money transactions: subtracting from one account and adding to the other account.

```C
Entity TransferMoney
{
    DateTime EventDate;
    ShortString TransferFrom;
    ShortString TransferTo;
    Money Amount;

    Is Demo.MoneyTransaction; // Implicitly using the 'Amount' value.

    Is Demo.MoneyTransaction 'Subtract'
    {
        Implements Demo.MoneyTransaction.Amount '-Amount';
    }
}
```

See the generated SQL view `Demo.MoneyTransaction` to check that a `TransferMoney` record is included twice in the view.

## Property implementation with subquery

An SQL subquery may be used for polymorphic property implementation.

For example, one `LendMoney` instance can have multiple additions (`LendMoneyAddendum`) that will be summed as a single `TotalAddendum` implementation of `MoneyTransaction`:

```C
Entity LendMoneyAddendum
{
    Reference LendMoney;
    Money AdditionalAmount;
}

Entity LendMoney // Adding new features to the existing entity.
{
    Is Demo.MoneyTransaction 'TotalAddendum'
    {
        Implements Demo.MoneyTransaction.Amount '(SELECT -SUM(AdditionalAmount) FROM Demo.LendMoneyAddendum)';
        SqlDependsOn Demo.LendMoneyAddendum;
    }
}
```

See the generated SQL view `Demo.LendMoney_As_MoneyTransaction_TotalAddendum` to check the impact of the subquery.

`SqlDependsOn` is a dependency information that is used when creating database objects: `Demo.LendMoneyAddendum` table must be created *before* the subtype's SQL view that contains this SQL query.

## Limit the implementation with filter (where)

The `Where` concept can be used to limit the items when will be included in the polymorphic implementation. The filter is defined by an SQL expression for the SQL query *WHERE part*.

* If multiple `Where` concepts are provided in the same `Is` block, the `AND` operation will be applied between them.

This example is an alternative implementation of the `BorrowMoney` subtype (see the original implementation above).
In the following example, only items from `BorrowMoney2` that are not `Forgotten` will be included in the `MoneyTransaction`.

```C
Entity BorrowMoney2
{
    DateTime EventDate;
    ShortString FromWhom;
    Money Amount;
    Bool Forgotten;

    Is Demo.MoneyTransaction
    {
        Where 'Forgotten = 0'; // SQL snippet, the "Forgotten" column is a "bit".
    }
}
```

See the generated SQL view `Demo.BorrowMoney2_As_MoneyTransaction` to check the impact of the `Where` concept.

## Subtype implementation using SQL query

Instead of using property implementations (`Implements` keyword), a specific SQL query may be provided to implement the mapping between the subtype and the polymorphic entity.

This example is an alternative implementation of the `LendMoney` subtype (see the original implementation above).

```C
Entity LendMoney2
{
    ShortString ToWhom;
    // When using SqlImplementation, the properties are not automatically inherited from the polymorphic.
    DateTime EventDate;
    Money Amount;

    Is Demo.MoneyTransaction
    {
        SqlImplementation "SELECT lm.ID, lm.EventDate, Amount = -lm.Amount FROM Demo.LendMoney2 lm"
        {
            AutoDetectSqlDependencies;
        }
    }
}
```

`SqlImplementation` may cover more complex scenarios than per-property implementations (`Implements`),
but it lacks readability and extensibility such as adding a custom property to the subtype from another package.

## Writing efficient queries from client application

When reading a polymorphic entity, filtering by subtype can be evaluated efficiently in SQL Server if the filter is based on a subtype reference property.
For example, when reading records from `MoneyTransaction` of subtype `LendMoney` through REST API, the following filter should be used:

    http://localhost/Rhetos/rest/Demo/Perf/?filters=[{"Property":"LendMoney","Operation":"NotEqual","Value":null}]

The request above will be translated to an SQL query similar to `SELECT * FROM Demo.MoneyTransaction WHERE LendMoneyID IS NOT NULL`.
SQL Server will optimize the query's execution plan so that only `Demo.LendMoney` table will be scanned.

A similar optimization is done in database when filtering by subtype: `SELECT * FROM Demo.MoneyTransaction WHERE Subtype = 'Demo.LendMoney'`.
Unfortunately, if such filter is defined in LINQ query, it will generate a different WHERE part:
`WHERE Subtype = @p0`, and the LINQ query will cause reading both `Demo.LendMoney` and `Demo.BorrowMoney` tables.
