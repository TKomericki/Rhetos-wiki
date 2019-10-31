When upgrading from **Rhetos v0.9** to **Rhetos v1.0**, the ORM framework is changed from *NHibernate* to *Entity Framework*.
The following text describes the breaking changes that require modifications in your application's DSL scripts and C# code.

How to use this document:

1. Apply all instructions from the first 4 tutorial sections to your application. Most of those changes will result with compile-time errors if not applied properly, so the migration process should be straightforward.
2. Some incompatibilities between NH and EF will result with **run-time errors** when executing LINQ queries.
  This means that whole application will have to be tested in order to validate that the migration is successful.
  The [Troubleshooting](#troubleshooting) section will help with fixing those errors:
  **search for the error message** and follow the instructions.

Table of contents:

1. [Querying data](#querying-data)
2. [Hard-to-Detect incompatibilities](#hard-to-detect-incompatibilities)
3. [Direct use of NHibernate](#direct-use-of-nhibernate)
4. [Using repositories](#using-repositories)
5. [Troubleshooting](#troubleshooting)

## Querying data

* Simple instances of a data structure class do not have navigation properties, such as references, Base, Extends_, and similar.
  The navigation properties are available in LINQ queries only. Simple instances are typically used in FilterBy and Computed, or created with the "new" operator.
* `IQueryable<{module}.{entity}>` => `IQueryable<Common.Queryable.{module}_{entity}>`
* Use `repository.Load(filter)` or `repository.Query(filter).ToSimple()` to avoid memory/cpu overhead of EF proxy objects when loading data.
* **Computed** concept is no longer queryable and it doesn't automatically implement `IEnumerable<Guid>` filter. Both features resulted with poor performance.
* Calling `AsQueryable()` on a list or an array of items:
    - To query data from database: `listOfItems.AsQuerayble()` => `entityRepository.QueryPersisted(listOfItems)`
    - To query loaded data, without using navigation properties: `listOfItems.AsQueryable()` => `entityRepository.QueryLoaded(listOfItems)`
    - Additionally, to use lazy evaluation of navigation properties (such as references) in the loaded data, add `LazyLoadReferences` to the data structure in the .rhe script.
* `Guid.Parse("...")` => `new Guid("...")`
* `SqlLike` => `Like`
* `item.FullTextSearch(...)` => `DatabaseExtensionFunctions.FullTextSearch(item.ID, ...)`
* Enable the following configuration option in *web.config*: `<add key="EntityFramework.UseDatabaseNullSemantics" value="True" />`. This will instruct the Entity Framework to generate [simpler](https://msdn.microsoft.com/en-us/library/dn221475%28v=vs.113%29.aspx) SQL queries, similar to NHibernate's, that will lessen the risk of backward-compatibility issues and performance issues.

## Hard-to-Detect incompatibilities

* Using `updatedOld.Zip(updated` in **OnSaveUpdate** or **OnSaveValidate** concept
  (or other concepts that inject code at OnSave1Tag or OnSave2Tag)
  will result with nondeterministic behavior. The `updated` variable at that moment contains a LINQ query,
  not an array, so the order or elements might not match the `updatedOld` array.
    - => Use `updatedNew` instead of `updated` in OnSaveUpdate and OnSaveValidate.
    - Search regex: `updatedOld\s+\.Zip\(updated\b`.
    - The same problem occurs on `inserted`, but the order of its elements is rarely used.

## Direct use of NHibernate

* `_executionContext.NHibernateSession.Clear()`
    - => `context.EntityFrameworkContext.ClearCache()` or `container.Resolve<IPersistenceCache>.ClearCache()`
* `_executionContext.NHibernateSession.Evict(item)`
    - => `context.EntityFrameworkContext.ClearCache(item)` or `container.Resolve<IPersistenceCache>.ClearCache(item)`
* `_executionContext.NHibernateSession.Query<{module}.{entity}>()`
    - => `_executionContext.EntityFrameworkContext.{module}_{entity}`
* SQL command using NHibernateSession:
    - `context.NHibernateSession.CreateSQLQuery(sql).ExecuteUpdate();`
    - => `context.SqlExecuter.ExecuteSql(sql)`
* SQL query using NHibernateSession:
    - `var sql = "SELECT * FROM mod.ent(:dateTime)"; return _executionContext.NHibernateSession.CreateSQLQuery(sql).AddEntity(typeof(mod.ent)).SetTimestamp("dateTime", parameter).List<mod.end>();`
    - => `context.SqlExecuter.ExecuteReader(...)`
    - or => `var sql = "SELECT * FROM {2}.{3}(@p0)"; return _executionContext.EntityFrameworkContext.Database.SqlQuery<{0}.{1}>(sql, parameter).ToList();`

## Using repositories

* `Implements` concept is now limited to scalar properties. In order to use navigation properties in the interface, use `ImplementsQueryable`.
* `IWritableRepository` interface is removed (a new one exists with a generic parameter)
    - => If referencing *ServerDom.dll*, use the entity's repository `Insert/Update/Delete/Save` functions directly. Otherwise, use the `GenericRepository`.
    - Add `using Rhetos.Dom.DefaultConcepts;` for extension methods.
* `IFilterRepository` interface is removed.
    - => If referencing *ServerDom.dll*, use the entity's repository `Filter` function directly. Otherwise, use the `GenericRepository`.
    - Add `using Rhetos.Dom.DefaultConcepts;` for extension methods.
* Avoid `GenericRepository` for querying when using navigation properties.
    -  `GenericRepository<Module.Entity>.Query(...)` => `repository.Module.Entity.Query(...)`.
* Renamed repository functions:
    - `All()` => `Load()`. It will always return materialized items (a list or an array).
    - `Read(...)` => `Load(...)`. It will always return materialized items (a list or an array).
    - `ReadOrQuery(...)` => `Read(...)`
    - `Load<FilterType>()` => `Load(null, typeof(FilterType))`
    - `Query<FilterType>()` => `Query(null, typeof(FilterType))`
    - `Read<FilterType>()` => `Read(null, typeof(FilterType))`

## Troubleshooting

* Error: `'moduleX.entityX' does not contain a definition for 'propertyX'`
    - In resulting query of a ComposableFilterBy or a QueryableExtension:
        + Use `new Common.Queryable.module_entity` instead of `new module.entity`.
    - Else:
        + Error `'...' does not contain a definition for '... ReferenceProperty'`
            * On assignment use `ReferencePropertyID = item.ID` instead of `ReferenceProperty = item`
            * On read use `ReferencePropertyID` or a LINQ query.
        + Error `... does not contain a definition for 'Base'` => when creating a new extension class instance in FilterBy or in Computed, set the ID property (`ID = item.ID`), not the Base property (`Base = item`).
        + Use `entityRepository.QueryLoaded(items).Select(item => item.Reference.Name)` instead of `items.Select(item => item.Reference.Name)`.
* `'..._Repository' does not contain a definition for 'Insert'` => `using Rhetos.Dom.DefaultConcepts;`
* `'..._Repository' does not contain a definition for 'Update'` => `using Rhetos.Dom.DefaultConcepts;`
* `'..._Repository' does not contain a definition for 'Delete'` => `using Rhetos.Dom.DefaultConcepts;`
* `The entity types 'x' and 'y' cannot share table 'z' because they are not in the same type hierarchy or do not have a valid one to one foreign key relationship with matching primary keys between them.`
    - If any of the structures is a LegacyEntity with an explicitly set table as a source view (LegacyEntity name 'tableX' 'tableX'), change it to a LegacyEntity with autogenerated view (LegacyEntity name 'tableX').
* Joining multiple queries throws exception ``NotSupportedException: LINQ to Entities does not recognize the method 'System.Linq.IQueryable`1[Common.Queryable.....] Query()' method``
    - => Separately create the queries `var query = repository.module.entity.query();` before joining them.
* Error `System.NullReferenceException: Object reference not set to an instance of an object.` on reference property.
    - Problem is cause when lazy loading references after modifying data in database, or after calling ClearCache() => Use query to avoid lazy loading references.
* Error `InvalidOperationException: The '...' property on '...' could not be set to a 'System.Int32' value. You must set this property to a non-null value of type 'System.Boolean'. `
    - => Instead of selecting 1 or 0 in the SQL query, select `CONVERT(BIT, 1)` or `CONVERT(BIT, 0)`. Check the column type of the generated view; it should be `bit` instead of `int`
* Error `Unable to cast the type '...' to type 'Rhetos.Dom.DefaultConcepts.IEntity'. LINQ to Entities only supports casting EDM primitive or enumeration types.`
    - => Instead of using generic function type for GenericRepository or IQueryableRepository, use IEntity.
* Error ``LINQ to Entities does not recognize the method 'System.Linq.IQueryable`1[...] Query()' method, and this method cannot be translated into a store expression.``
    - => store the subquery in a separate variable, for example:
        + `{`
        + `    var subquery = repository.Common.PrincipalPermission.Query();`
        + `    return repository.Common.Principal.Query().Where(p => subquery.Select(pp => pp.PrincipalID).Contains(p.ID)).Dump("subquery variable");`
        + `}`
    - or => Use `entityRepository.Subquery` property for the subquery, instead of `entityRepository.Query()` function.
* Error `Unable to create a constant value of type '...'. Only primitive types or enumeration types are supported in this context.`
    - `Where(item => item.Reference == other)` => `Where(item => item.ReferenceID == other.ID)`
    - `Where(item => someList.Contains(item.Reference))` => `Where(item => someQuery.Contains(item.Reference))`.
* Error `'Rhetos.Persistence.IPersistenceTransaction' does not contain a definition for 'ClearCache'`
    - `PersistenceTransaction.ClearCache()` => `EntityFrameworkContext.ClearCache()`
    - Or => `context.EntityFrameworkContext.ClearCache()`
    - Or => `container.Resolve<IPersistenceCache>.ClearCache()`
* Error `There is already an open DataReader associated with this Command which must be closed first.` This can happen if you execute a query while iterating over the results from another query. Suggested solutions:
    - A) Load all the needed data in a single LINQ query. This will also improve performance.
    - B) Modify the loop to run on the loaded data instead of the LINQ query. For example: `foreach (var item in repository.SomeEntity.Query())` => `foreach (var item in repository.SomeEntity.Query().ToList())`. For better performance use `Query().ToSimple().ToList()`, if possible.
    - C) Use `ComposableFilterBy` instead of `ItemFilter` to allow more complex query implementation.
* Error `Only parameterless constructors and initializers are supported in LINQ to Entities.`
    - Remove the constructor with a parameter from the LINQ query. For example: `item => item.Created < new DateTime(DateTime.Today.Year, 1, 1)` => `{ var thisYear = new DateTime(DateTime.Today.Year, 1, 1); return item => item.Created < thisYear; }`
* Error `NotSupportedException: The specified type member 'Base' is not supported in LINQ to Entities. Only initializers, entity members, and entity navigation properties are supported.`
    - => Add the `Base` property to the LINQ query for the extension, if missing. For example: `query.Select(item => new Common.Queryable.SomeExtension { ID = item.ID, Base = item, ... }`.
* Error `NotSupportedException: LINQ to Entities does not recognize the method 'Boolean ExecuteValidationMethod`
    - Instead of `ItemFilter` use `FilterBy`, if lazy loading of references is not necessary.
    - or `ComposableFilterBy`, if evaluation of references is required execute the unsupported method on the loaded data:
        + `(items, repository, parameter) => items.ToList().Where(item => OmegaCommonConcepts.Plugin.Utility.ExecuteValidationMethod("{0}", "{1}", item, repository)).AsQueryable()`
* Error ExtComposableFilterBy threw exception: ``System.InvalidCastException: Unable to cast object of type 'System.Data.Entity.Infrastructure.DbQuery`1[...]' to type 'System.Linq.IQueryable`1[Common.Queryable....]'.``
    - => Funkcija koja implementira composable filter mora imati parametre tipa `IQueryable<Common.Queryable.module_entity>` umjesto `IQueryable<module.entity>`.
* `LINQ to Entities does not recognize the method 'System.TimeSpan Subtract(System.DateTime)' method`
 or `LINQ to Entities does not recognize the method 'System.TimeSpan Add(System.DateTime)' method`
 or `LINQ to Entities does not recognize the method 'System.DateTime AddDays(Double)' method`
    - => Use `AddDays` method of `System.Data.Entity.DbFunctions` class.
* `The specified cast from a materialized 'System.Int64' type to a nullable 'System.Int32' type is not valid.`
    - => EntityFramework will not automatically convert the data when loading a `bigint` column from database into an `int` property. Use CAST(.. AS INT) in the SQL query to match database column and C# property type.
* Using your own method in LINQ query results with NotSupportedException: `LINQ to Entities does not recognize the method '...'`.
    - A) Use an alternative method that is supported in LINQ to EntityFramework (see the examples above).
      See [Rhetos DatabaseExtensionFunctions](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/Plugins/Rhetos.Dom.DefaultConcepts.Interfaces/DatabaseExtensionFunctions.cs) and [System.Data.Entity.DbFunctions](https://msdn.microsoft.com/en-us/library/system.data.entity.dbfunctions%28v=vs.113%29.aspx) for some available methods.
    - B) Load the queried data before using the method. For example: `query.Select(item => MyFunction(item))` => `query.ToList().Select(item => MyFunction(item))`.
      Note than loading all items may degrade performance. Use `ToSimple()` or load a subset of records/properties if possible.
