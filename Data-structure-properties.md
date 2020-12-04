See the [Data model and relationships](Data-model-and-relationships) tutorial for examples and explanation of using properties
on entities and other data structures.

## Simple property data types

The following concepts are available in CommonConcepts DSL:

| DSL keyword | C# type | SQL Server column | Notes |
| --- | --- | --- | --- |
| **ShortString** | string | nvarchar(256) | Intended for short single-line text.
| **LongString** | string | nvarchar(max) | Intended for longer multi-line text. 1GB limit in practice on .NET. |
| **Integer** | int? | integer |
| **Decimal** | decimal? | decimal(28,10) | Intended for any decimal numbers where fixed-point arithmetic is needed. Percentages. Note: Floating-point arithmetic is rare in enterprise business applications. |
| **Money** | decimal? | money | SQL constraint for 2 decimal precision. |
| **Bool** | bool? | bit |
| **Date** | DateTime? | date |
| **DateTime** | DateTime? | datetime2(3) or datetime | Datetime2 is available since Rhetos v4.3. See details [below](#datetime-property-configuration).
| **Guid** | Guid? | uniqueidentifier |
| **Binary** | byte[] | varbinary(max) |

Note that **any new property type** can be created and implemented as a reusable Rhetos plugin, or simply as an internal part of a specific business application.

## Reference property

**Reference** property represents the "N : 1" relation in the data model, and often a lookup field in the user interface.

* In the generated C# code it creates
  * a [navigation property](https://docs.microsoft.com/en-us/ef/ef6/fundamentals/relationships)
  for use in Entity Framework LINQ queries,
  * and a simple Guid property (with an "ID" suffix) for raw data loading and saving.
* In the database it creates a Guid column (with an "ID" suffix)
  and an associated foreign key constraint.

See the [Data model and relationships](Data-model-and-relationships) tutorial,
section "One-to-many relation", for examples and explanation of the **Reference** concept.

## LinkedItems property

**LinkedItems** property adds a property that contains a list of detail items (records from another entity that references this entity).

Note: This is a navigation property for use in Entity Framework LINQ queries. This concepts does not change the database structure or the generated web API.

## DateTime property configuration

Before Rhetos v4.3, the DateTime property concept always generated *datetime* column in database.
Since v4.3, the database column type can be configured in
[build options](https://github.com/Rhetos/Rhetos/wiki/Configuration-management#build-configuration):

* "CommonConcepts:UseLegacyMsSqlDateTime" (boolean) -
  Generate old *datetime* type instead of  *datetime2* column type.
  Default is *true* for Rhetos v4.3+ (for backward compatibility), and *false* for Rhetos v5.0+.
* "CommonConcepts:DateTimePrecision" (integer, default 3) -
  Number of decimal places for seconds.
  It is recommended to use precision 3 (millisecond precision) to avoid round-trip issues with front end
  (for example, JavaScript usually works with time in milliseconds).
  For specific high-precision measurement, a new DSL property concept could be created.
  Also note that SYSDATETIME() in SQL Server typically does not provide higher accuracy then 1 ms.
