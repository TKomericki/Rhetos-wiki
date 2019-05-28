The **Domain Object Model** (DOM) is a set of C# classes that implement
the application's business logic and control the application's data.

Rhetos generates the object model from the application's DSL model
(from the *.rhe* scripts) and compiles it to *ServerDom* dlls.

This article helps developers to understand the generated classes and methods,
because they will be used in C# code snippets when implementing new business features,
such as filters, validations, computations and server actions.

Prerequisites:

* To follow the examples in this tutorial article, you need a working Rhetos application.
  You can use any existing application or create a new one from [Create your first Rhetos application](Create-your-first-Rhetos-application).
* Some examples use the entities from the [Bookstore](https://github.com/Rhetos/Bookstore) demo application.
  You can review the bookstore data model in its [DSL scripts](https://github.com/Rhetos/Bookstore/tree/master/src/DslScripts).
  For example, see the `Entity Book` in the *Book.rhe* file.

Contents:

1. [How to execute the examples](#how-to-execute-the-examples)
   1. [Option A: LINQPad](#option-a-linqpad)
   2. [Option B: Creating a "playground" console app](#option-b-creating-a-playground-console-app)
2. [Understanding the generated object model](#understanding-the-generated-object-model)
3. [Reading the data](#reading-the-data)
   1. [Load data](#load-data)
   2. [Query data](#query-data)
   3. [Understanding Entity Framework queries](#understanding-entity-framework-queries)
   4. [Filters](#filters)
   5. [Applying multiple filters](#applying-multiple-filters)
   6. [Subqueries](#subqueries)
   7. [Overview of the read methods](#overview-of-the-read-methods)
4. [Modifying the data](#modifying-the-data)
   1. [Save data](#save-data)
   2. [Sketch a code snippet when developing a new Action](#sketch-a-code-snippet-when-developing-a-new-action)
   3. [Execute action](#execute-action)
   4. [Execute action with parameters](#execute-action-with-parameters)
   5. [Execute recompute (ComputedFrom)](#execute-recompute-computedfrom)
5. [Analyze the DSL model](#analyze-the-dsl-model)
6. [Helpers for writing code snippets](#helpers-for-writing-code-snippets)
   1. [ComposableFilterBy code snippet](#composablefilterby-code-snippet)
   2. [ItemFilter code snippet](#itemfilter-code-snippet)
   3. [FilterBy code snippet](#filterby-code-snippet)
   4. [Action code snippet](#action-code-snippet)

## How to execute the examples

The examples from this article can be executed with the [LINQPad](https://www.linqpad.net/) script `Rhetos Server DOM.linq`,
already available in your application's Rhetos server folder,
or create a "playground" console app in Visual Studio with ConsoleDump NuGet plugin.

* **LINQPad** - Simple to setup, nicer output format. Free, but IntelliSense (autocomplete) requires buying a license.
* **"Playground" console app** in Visual Studio - 10 minutes setup (see below), IntelliSense included.

In both cases, to run any example from this article, copy the code snippet from each example into the marked position in the Main method. You can delete the rest of the script below the `var repository` line.

```C#
void Main()
{
    ConsoleLogger.MinLevel = EventType.Info; // Use "Trace" for more detailed log.
    var rhetosServerPath = Path.GetDirectoryName(Util.CurrentQueryPath);
    Directory.SetCurrentDirectory(rhetosServerPath);
    // Set commitChanges parameter to COMMIT or ROLLBACK the data changes.
    using (var container = new RhetosTestContainer(commitChanges: false))
    {
        var context = container.Resolve<Common.ExecutionContext>();
        var repository = context.Repository;

        // <<<< Copy-paste the example code here >>>>
    }
}
```

Note that this code contains `commitChanges: false`. This means that all **changes in the database will be rolled back** at the end of the script.

### Option A: LINQPad

1. Download the latest version of LINQPad from <https://www.linqpad.net/>.
2. Open the LINQPad script `Rhetos Server DOM.linq` from your application's Rhetos server folder.
3. Run it with F5. It should print a few tables and end with "Done.".

Notes:

* The examples use the LINQPad's method `Dump()` to print the results in a grid.
* LINQPad keeps the Rhetos server's process **active between executions**. This improves performance, but you will need to stop the LINQPad process ("Cancel All Thread and Reset" menu option) before calling **DeployPackages.exe**, to **unlock the dll files**.

### Option B: Creating a "playground" console app

1. In Visual Studio create a new project from template "Console App (.NET Framework)".
   * Select .NET framework 4.5.1 (same as Rhetos)
   * If you are creating a Bookstore demo application, set the following:
     * Location: create the `test` subfolder in your "Bookstore" project folder (`...\Bookstore\test\`),
     * Name: "Bookstore.Playground"
     * disable the checkboxes "Create directory for solution" and "Create new Git repository".
2. Project => Add reference... => Browse... => Select all dlls from the Rhetos server's bin folder
  (for example `Bookstore\dist\BookstoreRhetosServer\bin`), **except the two** Microsoft.*.dll files
  => Add => OK.
3. Repeat the previous step for this two Rhetos server subfolders: `bin\Generated` and `bin\Plugins`.
4. Project => Manage NuGet Packages... => Browse => search "ConsoleDump"
  => select the ConsoleDump package => Install => OK.
5. Copy the content of the `Main` method, from the *Rhetos Server DOM.linq* script
  in the Rhetos server folder, into the Main method of your Playground project.
6. Replace the line `var rhetosServerPath = Path.GetDirectoryName(Util.CurrentQueryPath);`
  with `var rhetosServerPath = @"<relative or absolute path to the Rhetos server folder>";`, for example
  `var rhetosServerPath = @"..\..\..\..\dist\BookstoreRhetosServer";`.
7. Fix the compiler errors by adding the suggested "using" statement for each error.
  The resulting using statements should look like this:
    ```C#
    using ConsoleDump;
    using Rhetos.Configuration.Autofac;
    using Rhetos.Dom.DefaultConcepts;
    using Rhetos.Logging;
    using Rhetos.Utilities;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    ```
8. Run the application with **Ctrl+F5**. It should print a few tables and end with "Done.".
9. Troubleshooting:
   * If you get an error `DirectoryNotFoundException: Could not find a part of the path ...`, check how the reported path relates to the `var rhetosServerPath` line in the Main method (see steps above). Correct the rhetosServerPath to match the Rhetos server folder.

Notes:

* The examples use the ConsoleDump's method `Dump()` to print the results in a table format.
* For the end result, see the example of the created playground app for the Bookstore demo application
at <https://github.com/Rhetos/Bookstore/tree/master/test/Bookstore.Playground>.

## Understanding the generated object model

When you run *DeployPackages.exe*, it will read DSL scripts and generated the web application. Most of the application's business features are implemented in the three generated source files: "ServerDom.Model.cs", "ServerDom.Orm.cs" and "ServerDom.Repositories.cs". You can find them in the Rhetos server subfolder `bin\Generated\` (for example, `Bookstore\dist\BookstoreRhetosServer\bin\Generated\`).

Now we will review the generated files and notice some classes and methods that we will use later in this tutorial article. In this example, we will look for features related to the [Entity Book](https://github.com/Rhetos/Bookstore/blob/master/src/DslScripts/Book.rhe) from the Bookstore demo application. You can use any other entity from your application.

Fore each entity, three classes are generated:

1. **Simple "POCO" class**
   * Find "class Book" in ServerDom.Model.cs.
   * Its namespace is Bookstore, so the full name of the class is Bookstore.Book.
   * This class contains simple properties of this entity, without any business features or data access logic. The base class adds an ID property.
   * Note that the Reference property Author is represented here as a "Guid? AuthorID". This class contains just raw data without references to other objects. It looks the same as the table columns in the database.
   * Also note that all properties in Rhetos are nullable.
2. **Queryable class with navigation properties**
   * Find "class Bookstore_Book" in ServerDom.Model.cs.
   * This class inherits the simple Book class and adds
     [navigation properties](https://docs.microsoft.com/en-us/ef/ef6/fundamentals/relationships) for use in **Entity Framework LINQ queries** (see `public virtual` properties that reference other entities).
   * This class is mapped to the database table or view by Entity Framework.
     The class name has the module name as a prefix, because Entity Framework 6 does not support multiple namespaces in the same data model.
   * The properties contains some wrapper code to handle some edge cases with EF that are not compatible with Rhetos features (deletes the references when detaching an object). We hope to remove it in future releases.
   * Note that the navigation properties are not created only for Reference properties. They can also include some other related Entities and other object types that are extensions or details to this entity.
3. **Repository class with business features**
   * Find "class Book_Repository" in ServerDom.Repositories.cs.
   * This class contains most of the business features and the data access logic.
   * Find the Query() method. It returns the Entity Framework query for this entity.
   * Find the Save(...) method and see it's arguments. It handles inserting, updating and deleting of records.
     This is usually the largest method in this class, because many business rules
     are applied on save.
     * It contains different validations (that throw an exception for invalid data), initialization of values (such as AutoCode), updates any dependent caches values and similar.
     * Note that all the feature that we write in the DSL script work as small code generators. Each concept (keyword) has one or more code-generator plugins triggered that will insert some code snippet in this object model. For example, ShortString property will insert few lines of code at the beginning of the Save method (before comment tag `/*DataStructureInfo WritableOrm ArgumentValidation ...*/`) that check if the given string value is under 256 characters limit. All Rhetos concepts work as code generators that insert some C# or SQL code snippets, and this is how the application is generated.

## Reading the data

### Load data

**Load** method for entity reads data from the database.

```C#
var allBooks = repository.Bookstore.Book.Load();
allBooks.Dump();

var someBooks = repository.Bookstore.Book.Load(book => book.Title.StartsWith("The"));
someBooks.Dump();
```

The **Load** method does not return a LINQ query.
It returns array of simple objects (as IEnumerable), loaded from the database,
without references to other objects.
For example, loaded books contain simple `AuthorID` Guid property,
but not `Author` property that would reference the entity Person.

The Load method can have a **filter** as a parameter.
More information on using filters is available in the chapters below.

### Query data

**Query** method returns Entity Framework LINQ query.

```C#
var query = repository.Bookstore.Book.Query();

var query2 = query
    .Where(b => b.Title.StartsWith("B"))
    .Select(b => new { b.Title, b.Author.Name });

// Entity Framework overrides ToString to return the generated SQL query.
query2.ToString().Dump("Generated SQL query");

// ToList will force Entity Framework to load the data from the database.
var items = query2.ToList();
items.Dump();
```

The **Query** method does not load the data from the database
(in contrast to the Load method).
It returns a LINQ query of the queryable class with navigation properties,
that can be used to include the data from other related objects (reference, extensions and similar).

* For example, the class in the query contains both `AuthorID` Guid property and the `Author` property that references the entity Person.
* The data will be loaded from the database when a `ToList()` method is executed on the query, or any other method that requires the data (First(), Any(), ...).

The Query method can have a **filter** as a parameter, same as the Load method.

**ToSimple** is a Rhetos method that removes ORM navigation properties from the query:

```C#
// Query data from the `Common.Claim` table:

var query = repository.Common.Claim.Query()
    .Where(c => c.ClaimResource.StartsWith("Common.") && c.ClaimRight == "New");

query.ToString().Dump("Claims query SQL");
query.ToList().Dump("Claims query items"); // With navigation properties.

query.ToSimple().ToString().Dump("Claims ToSimple SQL"); // Same as above.
query.ToSimple().ToList().Dump("Claims ToSimple items"); // Without navigation properties.
```

* On an entity repository, `Load()` returns the equivalent result to `Query().ToSimple().ToArray()`.

### Understanding Entity Framework queries

To better understand how to write efficient LINQ queries,
the following example demonstrates how Entity Framework evaluates the LINQ queries,
and shows the difference between loading and querying the data.
Notice the difference in the three lines that read the data:

```C#
var query = repository.Bookstore.Book.Query();

query.Select(book => book.Title).Take(3).ToList().Dump();
query.Select(book => book.Title).ToList().Take(3).Dump();
query.ToList().Select(book => book.Title).Take(3).Dump();
```

The script resulted with the following SQL queries executed on the database (recorded with SQL Profiler).

```SQL
SELECT TOP (3)
    [c].[Title] AS [Title]
    FROM [Bookstore].[Book] AS [c]

SELECT
    [Extent1].[Title] AS [Title]
    FROM [Bookstore].[Book] AS [Extent1]

SELECT
    [Extent1].[ID] AS [ID],
    [Extent1].[Code] AS [Code],
    [Extent1].[Title] AS [Title],
    [Extent1].[NumberOfPages] AS [NumberOfPages],
    [Extent1].[AuthorID] AS [AuthorID]
    FROM [Bookstore].[Book] AS [Extent1]
```

* The first query is the most efficient, because it contains both Select and the Take method converted to the database query.
* The second query was loaded before limiting the record count. It could result with loading a million unnecessary records from the database.
* The third query loaded all column values from the database, even though only Title is needed.

### Filters

Both Load and Query methods support a filter parameter.
There are different kinds of filters that can be used here.

1. Using the **specific filters** implemented in the DSL script (concepts **FilterBy**, **ComposableFilterBy**, **ItemFilter** or **Query**).

    ```C#
    var filterParameter = new Bookstore.CommonMisspelling();
    repository.Bookstore.Book.Load(filterParameter).Dump();

    // ToString will report the generated SQL query.
    repository.Bookstore.Book.Query(filterParameter).ToString().Dump();
    ```

2. **Lambda** expression.

    ```C#
    repository.Bookstore.Book.Load(book => book.Title.StartsWith("The"));
    ```

3. Predefined filter - **Get by ID**.

    ```C#
    Guid id = new Guid("c9860617-7e3e-4158-9d57-bbf4dd1f986e");
    repository.Bookstore.Book.Load(new[] { id }).Single().Dump();
    ```

4. Predefined filter - **Generic property filter**
(for available operations see [filters](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md#filters) documentation from the RestGenerator)

    ```C#
    // Generic property filter:
    var filter1 = new FilterCriteria("Title", "StartsWith", "B");
    repository.Bookstore.Book.Query(filter1).Dump();

    // IEnumerable of generic filters:
    var filter2 = new FilterCriteria("Title", "Contains", "ABC");
    var manyFilters = new[] { filter1, filter2 };
    var filtered = repository.Bookstore.Book.Query(manyFilters);
    filtered.ToString().Dump(); // The SQL query contains both filters.
    filtered.ToSimple().Dump();
    ```

Note that the examples above will work on both **Load** and **Query** methods.

### Applying multiple filters

You can use the repository's `Filter` method to add a filter to the existing LINQ query.

The following example applies three filters when loading the Book records.
The result is the intersection of the result sets for each filter (AND).

```C#
var filter1 = new FilterCriteria("Title", "StartsWith", "The"); // Generic property filter.
var filter2 = new Bookstore.CommonMisspelling(); // ItemFilter in a DSL script.
var filter3 = new Guid[] { // Predefined IEnumerable<Guid> filter.
    new Guid("9b1dd9c7-6e78-4ea0-a24c-9e812a8c15d5"),
    new Guid("57b50538-c599-4629-8941-d2d996822c61") };

var query = repository.Bookstore.Book.Query(filter1);
query = repository.Bookstore.Book.Filter(query, filter2);
query = repository.Bookstore.Book.Filter(query, filter3);
query.ToString().Dump();
```

The code above will result with the following SQL query.
Not that all the filter are included in a single database request.

```SQL
SELECT
    [Extent1].[ID] AS [ID],
    [Extent1].[Code] AS [Code],
    [Extent1].[Title] AS [Title],
    [Extent1].[NumberOfPages] AS [NumberOfPages],
    [Extent1].[AuthorID] AS [AuthorID]
FROM
    [Bookstore].[Book] AS [Extent1]
WHERE
    ([Extent1].[Title] LIKE N'A' + '%')
    AND ([Extent1].[Title] LIKE N'%curiousity%')
    AND ([Extent1].[ID] IN (
            cast('9b1dd9c7-6e78-4ea0-a24c-9e812a8c15d5' as uniqueidentifier),
            cast('57b50538-c599-4629-8941-d2d996822c61' as uniqueidentifier)))
```

### Subqueries

The query in the following example is expected to return the books that have at least one comment,
but there is an issue with the query interpretation.

```C#
var booksWithComments = repository.Bookstore.Book.Query()
    .Where(book => repository.Bookstore.Comment.Query()
        .Any(comment => comment.BookID == book.ID));

booksWithComments.Select(book => book.Title).Dump();
```

The code above will result with **NotSupportedException**:
"LINQ to Entities does not recognize the method ... Query() ...". The Entity Framework 6.1 does not support usage of custom methods (`Comment.Query()`) for a subquery.

There are two approaches to solve this with the subquery:

**Option A)** Separate the inner query to a variable. For example:

```C#
var comments = repository.Bookstore.Comment.Query();
var booksWithComments = repository.Bookstore.Book.Query()
    .Where(book => comments
        .Any(comment => comment.BookID == book.ID));
```

**Option B)** Use the `Subquery` property to avoid the limitation:

```C#
var booksWithComments = repository.Bookstore.Book.Query()
    .Where(book => repository.Bookstore.Comment.Subquery
        .Any(comment => comment.BookID == book.ID));
```

Note that in both solutions above, this code will execute a *single* SQL query in the database:

```SQL
SELECT
    [Extent1].[ID] AS [ID],
    [Extent1].[Code] AS [Code],
    [Extent1].[Title] AS [Title],
    [Extent1].[NumberOfPages] AS [NumberOfPages],
    [Extent1].[AuthorID] AS [AuthorID]
FROM
    [Bookstore].[Book] AS [Extent1]
WHERE
    EXISTS (SELECT
        1 AS [C1]
        FROM [Bookstore].[Comment] AS [Extent2]
        WHERE [Extent2].[BookID] = [Extent1].[ID]
    )
```

### Overview of the read methods

The repository class for Entity, SqlQueryable or Browse, contains the following methods for reading and filtering the data:

| | Get a list or an array of simple items<br>Returns `IEnumerable<SimpleClass>` | Get a LINQ query<br>Returns `IQueryable<QueryableClass>` |
| --- | --- | --- |
| **All items** | `var items = rep.Load()` | `var query = rep.Query()` |
| **Single filter or initialization** | `var items = rep.Load(filterParameter)` | `var query = rep.Query(filterParameter)` |
| **Apply multiple filters** | `items = rep.Filter(items, filterParameter)`<br>Note: this is inefficient because the data from the first filter is already loaded from the database. | `query = rep.Filter(query, filterParameter)` |

The following table shows what repository methods are generated by which DSL concept:

| DSL Concept | Available repository methods |
| --- | --- |
**Entity**<br>(includes some predefined filters) | `rep.Load()`<br>`rep.Query()`<br>`=> ComposableFilterBy IEnumerable<Guid>`<br>`=> ComposableFilterBy lambda`<br>`=> ComposableFilterBy FilterCriteria`<br>`=> ComposableFilterBy …` |
**FilterBy** filterParameter | `rep.Load(filterParameter)` |
**ComposableFilterBy** filterParameter | `rep.Load(filterParameter)`<br>`rep.Query(filterParameter)`<br>`rep.Filter(query, filterParameter)` |
**ItemFilter** filterParameter | `=> ComposableFilterBy filterParameter` |
**Query** filterParameter | `rep.Load(filterParameter)`<br>`rep.Query(filterParameter)` |

## Modifying the data

**Note:**
If you want to check the modified data in the database after running the following examples,
you need to change `commitChanges: false` to `true` in the testing script or the playground console app.
By default, if commitChanges is false, all the changes **will be rolled back** at the end of the script.

### Save data

Entity's repository class has a `Save(...)` method, that receives a list of records to insert, update and delete. There are also simple extension methods available for those operations (`Insert`, `Update`, `Delete`) that will internally call the Save method.

This example uses the table `Common.Principal`, that is available in the CommonConcept package.

```C#
// Insert a record in the `Common.Principal` table:
var testUser = new Common.Principal { Name = "Test123", ID = Guid.NewGuid() };
repository.Common.Principal.Insert(testUser);

// Update the existing record:
Guid id = testUser.ID;
var loadedUser = repository.Common.Principal.Load(new[] { id }).Single();
loadedUser.Name = loadedUser.Name + "xyz";
repository.Common.Principal.Update(loadedUser);

// Delete:
repository.Common.Principal.Delete(testUser);

// Print logged events for the `Common.Principal`:
repository.Common.LogReader.Query()
    .Where(log => log.TableName == "Common.Principal" && log.ItemId == testUser.ID)
    .ToList()
    .Dump("Common.Principal log");

// Output:
// TableName        | Action | Description                       | ...
// Common.Principal | Insert |                                   | ...
// Common.Principal | Update | < PREVIOUS Name = "Test123" />    | ...
// Common.Principal | Delete | < PREVIOUS Name = "Test123xyz" /> | ...
```

Note that in Entity Framework applications, saving the modified data to the database
is usually done with the Flush method, or implicitly at the end of the request.

In Rhetos, any modified data must by explicitly saved to the database with the `Update` method
(see the example above).

The Save method works with simple objects, without navigation properties.
The queryable objects could be provided as a parameter,
but the additional navigation properties will be ignored.

### Sketch a code snippet when developing a new Action

[Action](Action-concept) concept in Rhetos represents a custom server-side command that returns no data.

For example, in LINQPad or the playground app,
write a code for the Bookstore demo application that **inserts five books**.

```C#
for (int i = 0; i < 5; i++)
{
    var newBook = new Bookstore.Book { Code = "+++", Title = "New book" };
    repository.Bookstore.Book.Insert(newBook);
}
```

Write an [Action](Action-concept) concept in DSL scripts that inserts five books,
copy the code snippet above into the concept implementation.

```C
Module Bookstore
{
    Action Insert5Books
        '(parameter, repository, userInfo) =>
        {
            for (int i = 0; i < 5; i++)
            {
                var newBook = new Bookstore.Book { Code = "+++", Title = "New book" };
                repository.Bookstore.Book.Insert(newBook);
            }
        }';
}
```

### Execute action

This example uses the [Action](Action-concept) created in the previous example.
Don't forget to run `DeployPackages.exe` after implementing Action in the DSL script.

In LINQPad or in the playground console app, execute the Insert5Books action.

```C#
// Null argument is send because this action has no parameters.
repository.Bookstore.Insert5Books.Execute(null);
```

To check the results in the database, make sure that you have `commitChanges: true`.

### Execute action with parameters

For example:

> Write an action that inserts books, with the following parameters:
> The number of books that should be generated,
> and the title for the generated book.
> Add numbers to the generated titles starting from 1.

Solution:

```C
Action InsertManyBooks
    '(parameter, repository, userInfo) =>
    {
        for (int i = 0; i < parameter.NumberOfBooks; i++)
        {
            string newTitle = parameter.TitlePrefix + " - " + (i + 1);
            var newBook = new Bookstore.Book { Code = "+++", Title = newTitle };
            repository.Bookstore.Book.Insert(newBook);
        }
    }'
{
    Integer NumberOfBooks;
    ShortString TitlePrefix;
}
```

To test the action, execute it in LINQPad or in the playground console app:

```C#
var actionParameter = new Bookstore.InsertManyBooks
{
    NumberOfBooks = 7,
    TitlePrefix = "A Song of Ice and Fire"
};
repository.Bookstore.InsertManyBooks.Execute(actionParameter);
```

### Execute recompute (ComputedFrom)

"Recompute" refers to the process of updating the persisted computed data,
see [Persisting the computed data](Persisting-the-computed-data).

This example requires **CommonConceptsTest** plugin to be deployed on Rhetos server.
It is available in Rhetos source subfolder `CommonConcepts\CommonConceptsTest`.

```C#
// Recomputing data in the `TestComputedFrom.PersistComplex` table
// to match the data from the `TestComputedFrom.Source` data structure:

// The recompute method's name is "RecomputeFrom" + data source name.
repository.TestComputedFrom.PersistComplex.RecomputeFromSource();
```

Modify `ConsoleLogger.MinLevel = EventType.Info` to `EventType.Trace`, to see the steps of the recompute analysis: Initialize new items, Load old items, Diff, Save.

## Analyze the DSL model

This example uses the methods of the `IDslModel` interface for performance-efficient search on the DSL model: `FindByType`, `FindByKey` and `FindByReference`.

```C#
var dslModel = container.Resolve<IDslModel>();

// List all entities:
var entities = dslModel.FindByType<EntityInfo>().Select(entity => entity.Module.Name + "." + entity.Name);
entities.Dump("Entities");

// Find a specific entity by concept's key:
// Entity inherits DataStructure, and the concept's key always contains the base concept's type name.
var principalEntity = (DataStructureInfo)dslModel.FindByKey("DataStructureInfo Common.Principal");
principalEntity.GetUserDescription().Dump("Common.Principal entity");

// Find all ShortString properties that match `property => property.DataStructure == principalEntity`
var properties = dslModel.FindByReference<ShortStringPropertyInfo>(property => property.DataStructure, principalEntity);
properties.Select(p => p.GetUserDescription()).Dump("Common.Principal ShortString properties");
```

## Helpers for writing code snippets

The scripts in the following chapters will help you with development and testing of code snippets for filters and actions. The code snippet can then be copied to the *.rhe* script.

### ComposableFilterBy code snippet

```C#
// This ComposableFilterBy will filter the records by prefix from the 'Common.Claim' table.

// The filter has parameter: `ShortString Prefix;`
var parameter = new
{
    Prefix = "Common.Prin"
};

var query = repository.Common.Claim.Query();

IQueryable<Common.Queryable.Common_Claim> filteredQuery =
    // Uncomment the first line of the code snippet when copying to .rhe script.
    // The ComposableFilterBy's code snippet BEGIN
    //(query, repository, parameter) =>
        query.Where(item => item.ClaimResource.StartsWith(parameter.Prefix))
    // The ComposableFilterBy's code snippet END
    ;
filteredQuery.ToSimple().Dump("ComposableFilterBy query");
```

After developing and testing the ComposableFilterBy's code snippet, use it to put the filter (`DemoFilter`) in the *.rhe* script:

```C
Module Common
{
    Entity Claim
    {
        ComposableFilterBy DemoFilter '(query, repository, parameter) =>
            query.Where(item => item.ClaimResource.StartsWith(parameter.Prefix))';
    }

    Parameter DemoFilter
    {
        ShortString Prefix;
    }
}
```

### ItemFilter code snippet

```C#
// This ItemFilter will return the records with prefix "Common.Prin" from the 'Common.Claim' table.

repository.Common.Claim.Query(
    // The ItemFilter's code snippet BEGIN
    item => item.ClaimResource.StartsWith("Common.Prin")
    // The ItemFilter's code snippet END
).ToSimple().Dump("ItemFilter query");
```

### FilterBy code snippet

```C#
// This FilterBy will filter the records by prefix from the 'Common.Claim' table.

// The filter has parameter: `ShortString Prefix;`
var parameter = new
{
    Prefix = "Common.Prin"
};

var query = repository.Common.Claim.Query();

Common.Claim[] filteredItems =
    // Uncomment the first line of the code snippet when copying to .rhe script.
    // The FilterBy's code snippet BEGIN
    //(repository, parameter) =>
        repository.Common.Claim.Query()
            .Where(item => item.ClaimResource.StartsWith(parameter.Prefix))
            .ToSimple().ToArray()
    // The FilterBy's code snippet END
    ;
filteredItems.Dump("FilterBy items");
```

### Action code snippet

```C#
// This Action will insert a new record to the `Common.Claim` table:

// The action has parameters: `ShortString Resource;` and `ShortString Right;`.
var parameter = new
{
    Resource = "TestResource", // ShortString property of the action.
    Right = "TestRight" // ShortString property of the action.
};

var userInfo = context.UserInfo;

// Uncomment the first line of the code snippet when copying to .rhe script.
// The Action's code snippet BEGIN
// (parameter, repository, userInfo) =>
{
    repository.Common.Claim.Insert(new Common.Claim
    {
        ClaimResource = parameter.Resource,
        ClaimRight = parameter.Right,
        Active = true
    });
}
// The Action's code snippet END
```
