# Developing filters and other read methods

Most of the business rules in Rhetos applications are based on
filters and other similar read methods.

Developers write filters and queries to process the data.
The resulting datasets are then utilized to create validation rules,
compute business process state, define user permissions,
and other features.

This article explains **how to write filters** when developing a Rhetos application.

Prerequisites:

* [Entities and relationships](Data-model-and-relationships).
* Learn how to use the Rhetos Domain Object Model methods to [Read the data](Using-the-Domain-Object-Model#reading-the-data).

Contents:

1. [Filters](#filters)
   1. [ItemFilter concept](#itemfilter-concept)
   2. [Testing a filter](#testing-a-filter)
   3. [ItemFilter with related data and subquery](#itemfilter-with-related-data-and-subquery)
   4. [ComposableFilterBy concept](#composablefilterby-concept)
   5. [ComposableFilterBy with parameters](#composablefilterby-with-parameters)
   6. [Predefined filters](#predefined-filters)
2. [Other read methods](#other-read-methods)
   1. [FilterBy concept](#filterby-concept)
   2. [Query concept](#query-concept)
3. [Development guidelines and advanced topics](#development-guidelines-and-advanced-topics)
   1. [When not to write filters](#when-not-to-write-filters)
   2. [Using additional data or system components in filters](#using-additional-data-or-system-components-in-filters)
   3. [Filter name is filter parameter type](#filter-name-is-filter-parameter-type)
   4. [Combining filters and other read methods](#combining-filters-and-other-read-methods)
4. [Read next](#read-next)

## Filters

### ItemFilter concept

ItemFilter is the simplest concept for creating new filters.
You can use it on **Entity**, **Browse**, **SqlQueryable**, or any other queryable data structure
to filter the existing data with a simple lambda expression.

Consider the following example:

> 1. Write a filter that returns all books with the common misspelled word "curiousity".
>    Deny users entering incorrect book titles into the application.
> 2. Write another filter that returns books with 500 pages or longer.
>    The web application will display a list of long books to the users.

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
        Integer NumberOfPages;

        ItemFilter LongBooks 'item => item.NumberOfPages >= 500';

        ItemFilter CommonMisspelling 'book => book.Title.Contains("curiousity")';
        InvalidData CommonMisspelling 'It is not allowed to enter misspelled word "curiousity". Please use "curiosity" instead.';
    }
}
```

The **ItemFilter** has two parameters: filter name and lambda expression.

* The **lambda expression** is a C# code snippet that will be internally
  used in the Entity Framework LINQ query to load the data.
* For example, `ItemFilter LongBooks` will create a LINQ query
  similar to this one in the generated application, with the lambda expression
  directory copied into the Where method:
    ```C#
    booksQuery.Where(item => item.NumberOfPages >= 500);
    ```
* In C# lambda expressions, the argument name (`book` or `item`) can be any C# identifier.
  For convention, we usually use `item`.

The `CommonMisspelling` filter is additionally used for a [data validation](Data-validations)
that will deny the *save* operation if the user enters an invalid book name.
**Both filters** can be used by a client application (or in the object model)
to query a subset of the books.

* Note that the validation filter can be useful for reading data,
  even if there should be no "invalid" data in the system.
  For example, there might exist some old data entered before this
  data validation was developed, or before some bug was corrected
  in the validation's filter.
* Rhetos allows developers to list all data validations in the system,
  run their filters on the existing data, and report any data that
  does not comply with the current version of the validations.

### Testing a filter

The following articles show how to **test this filter**, or use it in your application:

1. You can read the filtered data from a REST web API, as described in the
   [RestGenerator documentation](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md).
   For example:
   * <http://localhost/Bookstore.Service/rest/Bookstore/Book/?filters=[{"Filter":"Bookstore.LongBooks"}]>
2. You can execute the filter directly from C# code, as described in [Using the Domain Object Model](Using-the-Domain-Object-Model#Filters).
   For example:
    ```C#
    var filterParameter = new Bookstore.LongBooks();
    var query = repository.Bookstore.Book.Query(filterParameter);
    query.ToString().Dump(); // Print the SQL query.
    query.ToSimple().ToList().Dump(); // Load and print the books.
    ```

Run the code snippet above to **review the SQL query** that will be executed on the database when filtering the data.
If you are testing the filter with REST web API, run SQL Server Profiler, to check the executed SQL query.

### ItemFilter with related data and subquery

ItemFilters are also useful when you need to query data from
**related entities**. For example:

> Write a filter that will return books that are foreign
> (if a record exists in the **extension** entity ForeignBook),
> but only if the author's name starts with X (see the referenced entity Person)
> and only if the book has at least 3 comments entered (in the **detail** entity Comment).

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
        Integer NumberOfPages;
        Reference Author Bookstore.Person;

        ItemFilter ForeignAuthorXWithComments 'item =>
            item.Author.Name.StartsWith("X")
            && item.Extension_ForeignBook.ID != null
            && _domRepository.Bookstore.Comment.Subquery.Where(c => c.BookID == item.ID).Count() >= 3';
    }

    Entity Person
    {
        ShortString Name;
    }

    Entity ForeignBook
    {
        Extends Bookstore.Book;
        ShortString OriginalLanguage;
    }

    Entity Comment
    {
        Reference Book { Detail; }
        LongString Text;
    }
}
```

* Expression `item.Author.Name` uses `Reference Author` from the book to read the `Name` from the `Entity Person`.
* Expression `item.Extension_ForeignBook.ID` references the extended `Entity ForeignBook`.
  See [Entities and relationships](Data-model-and-relationships) for more info on these features.
* Data from the detail entity `Comment` is aggregated with a **subquery**.
  Note that the `Subquery` property is used here, instead of the `Query()` method.
  Read more on subqueries in [Using the Domain Object Model](Using-the-Domain-Object-Model#subqueries).
* The filter's code snippet has access to the `_domRepository` and `_executionContext` members
  that provides the additional data (same as `var context` and `var repository` in the linked article).

Test the filter (see the section above) to review the SQL query that is executed on the database.

### ComposableFilterBy concept

The following simple example is an alternative implementation of the `ItemFilter LongBooks`
from the example above, but with the ComposableFilterBy concept.

> Write a filter "LongBooks2" that returns all books with 500 pages or longer.

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
        Integer NumberOfPages;

        ItemFilter LongBooks 'item => item.NumberOfPages >= 500';

        ComposableFilterBy LongBooks2 '(query, repository, parameter) =>
            {
                return query.Where(item => item.NumberOfPages >= 500);
            }';
    }

    Parameter LongBooks2
    {
    }
}
```

The **ComposableFilterBy** allows implementing more complex filters:

* Its function should return an IQueryable that filters the data
  provided by the **query parameter**.
  In practice this usually means that the function will end with `return query.Where(...);`.
* While ItemFilter is restricted to a single lambda expression supported
  by the Entity Framework LINQ, the ComposableFilterBy, in contrast, can contain
  an **arbitrarily complex** C# code before returning the LINQ query. For example,
  reading additional data, executing external processes and other.
* ComposableFilterBy can have parameters.
  Even if the **parameters are not used** in the example above,
  they must be declared with the "empty" `Parameter` concept.
  See the next section on filter parameters.
  * The empty `Parameter LongBooks2 { }` can be written shorter as `Parameter LongBooks2;`.

ItemFilter vs. ComposableFilterBy:

* ItemFilter concept is just a helper, internally implemented as a macro concept that **generates** the ComposableFilterBy.
  In the example above, `ItemFilter LongBooks` will internally generate `ComposableFilterBy LongBooks`
  and `Parameter LongBooks`, almost identical to the `LongBooks2` example.
* Most business rules that use filters (such as **InvalidData** and **Lock**)
  can work with both ComposableFilterBy and ItemFilter.

### ComposableFilterBy with parameters

Extend the filter from the previous example to handle the following parameters:

> For a given minimum number, return all books that have at least the given number of pages.
> Provide an additional parameter to return only the matching foreign books.

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
        Integer NumberOfPages;

        ItemFilter LongBooks 'item => item.NumberOfPages >= 500';

        ComposableFilterBy LongBooks3 '(query, repository, parameter) =>
            {
                var filtered = query.Where(item => item.NumberOfPages >= parameter.MinimumPages);
                if (parameter.ForeignBooksOnly == true)
                    filtered = filtered.Where(item => item.Extension_ForeignBook.ID != null);
                return filtered;
            }';
    }

    Parameter LongBooks3
    {
        Integer MinimumPages;
        Bool ForeignBooksOnly;
    }
}
```

**Parameter** concept creates a simple class in the object model.
The `parameter` argument in the ComposableFilterBy is an instance of that class.

The filter parameter can be included in the [REST web API](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md) request,
or provided in a C# code, see [Testing a filter](#testing-a-filter) above. For example:

```C#
var filterParameter = new Bookstore.LongBooks3
{
    MinimumPages = 100,
    ForeignBooksOnly = true
};
var query = repository.Bookstore.Book.Query(filterParameter);
query.ToString().Dump(); // Print the SQL query.
query.ToSimple().ToList().Dump(); // Load and print the books.
```

The resulting SQL query should look like this:

```SQL
SELECT
    [Extent1].[ID] AS [ID],
    [Extent1].[Code] AS [Code],
    [Extent1].[Title] AS [Title],
    [Extent1].[NumberOfPages] AS [NumberOfPages],
    [Extent1].[AuthorID] AS [AuthorID]
FROM
    [Bookstore].[Book] AS [Extent1]
    INNER JOIN [Bookstore].[ForeignBook] AS [Extent2] ON [Extent1].[ID] = [Extent2].[ID]
WHERE
    [Extent1].[NumberOfPages] >= @p__linq__0
```

Note that the SQL query will not include "INNER JOIN" to the ForeignBook,
if the parameter `ForeignBooksOnly` is null or not provided.

### Predefined filters

Every queryable data source (Entity, Browse, ...) supports the following predefined filters by default.
They behave in a same way as the ComposableFilterBy.

* A lambda expression
  * This is same as the parameter for the Where() method in LINQ queries.
* `IEnumerable<Guid>`
* Generic property filter: `FilterCriteria` and `IEnumerable<FilterCriteria>`.
  * This is internally used to process filters in the REST requests.
* `Rhetos.Dom.DefaultConcepts.FilterAll`
  * This filter just returns all the data.
    Even though it doesn't really do any processing,
    this filter is a simple helper that is sometimes used when you *need*
    to return a filter parameter, but you just want to select all data.

For usage **examples**, see "Filters" in [Using the Domain Object Model](Using-the-Domain-Object-Model#Filters).
These filters can also be included in the [REST web API](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md) request.

Additionally, the REST web API provides **paging features** to all queryable data sources
(to skip a number of records and limit the result count),
so they don't need to be specifically implemented in the filters.

## Other read methods

These read methods work in a similar way as filters: they have the same parameters,
and they return the result in the same format.
The only difference is that they **don't have an input data to be processed (filtered)**,
instead they need to provide the data on their own.

These methods do not need to return a subset from the existing data from the database
(even though they are often implemented in that way).
For example, they can generate new data or read it from an external system.

### FilterBy concept

FilterBy concept allows developers to write arbitrary C# code to provide the data.

In the following example we will write a search filter,
similar to `ComposableFilterBy LongBooks3` from the example above,
that uses C# code to process the data, instead of just a LINQ query.

> Write a search filter "ComplexSearch" that returns books, with the following parameters:
>
> * MinimumPages - The minimal number of pages a book must have.
> * ForeignBooksOnly - If true, return only the matching foreign books.
> * MaskTitles - If true, all book titles should be masked
>   by showing only the first and the last letter.

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
        Integer NumberOfPages;

        FilterBy ComplexSearch '(repository, parameter) =>
        {
            var query = repository.Bookstore.Book.Query(item => item.NumberOfPages >= parameter.MinimumPages);
            if (parameter.ForeignBooksOnly == true)
                query = query.Where(item => item.Extension_ForeignBook.ID != null);
            Book[] books = query.ToSimple().ToArray();

            if (parameter.MaskTitles == true)
                foreach (var book in books.Where(b => !string.IsNullOrEmpty(b.Title)))
                    book.Title = book.Title.First() + "***" + book.Title.Last();

            return books;
        }';
    }

    Parameter ComplexSearch
    {
        Integer MinimumPages;
        Bool ForeignBooksOnly;
        Bool MaskTitles;
    }
}
```

The **FilterBy** function must return an array of simple objects.

* In the example above this is `Book[] books`.
* Note that the `ToSimple()` is (optionally) used here as an optimization
  to remove the excess members and proxy objects from Entity Framework.
  For more info on this topic, see "Understanding the generated object model" and
  the ToSimple() examples in [Using the Domain Object Model](Using-the-Domain-Object-Model).
* The name of this concept is somewhat misleading, because FilterBy is not a true filter.
  The function in FilterBy does not receive a dataset to be filtered, instead it
  just loads the required data.

The loaded books are **processed in the C# code** to mask the titles before being returned.

* This kind of processing could not be implemented cleanly with the ComposableFilterBy concept.
* FilterBy is often used to process the data by an algorithm
  implemented in some external dll.
  For example, see FilterBy in [ComputeBookRating](https://github.com/Rhetos/Bookstore/tree/master/src/DslScripts),
  from the Bookstore demo application.

Combining multiple filters and paging:

* Since FilterBy returns an array instead of a query, the data returned by the FilterBy function
  is loaded from the database, so it would not be efficient to apply other filters (or paging)
  after the function is executed.
  See [Combining filters and other read methods](#combining-filters-and-other-read-methods) below for more info.
* If paging is required, it should be implemented manually in the FilterBy function with
  the *skip* and *limit* values provided in the function parameter.
* Alternatively, consider using the Query concept (described below), instead of FilterBy,
  if it is possible to refactor this function to return a LINQ query which can be efficiently
  filtered with additional filters or paging without loading excessive data from the database.

Similar features:

* If there are **no parameters** needed, consider using the [Computed concept](Read-only-data-structures#computed-concept)
  as a data source, instead of FilterBy.
  Also, you can add FilterBy to an existing Computed data source,
  to provide an additional option to read the data with a parameter.

### Query concept

The Query concept is similar to the FilterBy described above,
it just **returns a query** instead of a simple array.

* When reading the data from a Rhetos application, **this query can than be combined**
  with additional composable filters (ItemFilter, ComposableFilterBy,
  generic property filters, paging features, and other predefined filters).
* The Query concept is **rarely used** because of some technical limitations
  and non-standard patterns (described below).

For example:

> Provide an alternative data source for the book grid (Browse BookGrid)
> that will read the books from a WishList instead of the `Entity Book`.

Solution:

Note: this example might be implemented differently with some better design patterns.
This code just serves as an example for the Query concept.

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
        Reference Author Bookstore.Person;
    }

    // WishList contains books that are not yet entered in the entity Book.
    Entity WishList
    {
        ShortString BookTitle;
        Bool HighPriority;
    }

    Browse BookGrid Bookstore.Book
    {
        Take Code;
        Take Title;
        Take 'Author.Name';
        Take TranslatorName 'Extension_ForeignBook.Translator.Name';
        Take Description 'Extension_BookDescription.Description';
        Take NumberOfComments 'Extension_BookInfo.NumberOfComments';

        // This query is an alternative data source for BookGrid.
        // Instead of reading data from the `Bookstore.Book`, it provides the new data from WantedBooks.
        Query 'Bookstore.WantedBooks' 'parameter =>
            {
                var wishList = _domRepository.Bookstore.WishList.Query();
                if (parameter != null && parameter.HighPriorityOnly == true)
                    wishList = wishList.Where(item => item.HighPriority == true);

                var wantedBooks = wishList.Select(wish => new Common.Queryable.Bookstore_BookGrid
                {
                    // All properies must be declared here, otherwise EF will throw a NotSupportedException.
                    ID = wish.ID,
                    Code = null,
                    Title = wish.BookTitle,
                    AuthorName = "unknown",
                    TranslatorName = null,
                    Description = null,
                    NumberOfComments = null
                });
                return wantedBooks;
            }';
    }

    Parameter WantedBooks
    {
        Bool HighPriorityOnly;
    }
}
```

The Query concept defines an alternative queryable data source for this object.
It is similar to ComposableFilterBy, but it **does not receive a dataset to be filtered**,
instead it just creates a new query.

* Since it returns a query, the element type must be a queryable class
  (`Common.Queryable.Bookstore_BookGrid`), instead of a simple class
  (`Bookstore.BookGrid`). For more info on this topic, see
  [Understanding the generated object model](Using-the-Domain-Object-Model#understanding-the-generated-object-model).

The Query data source is used in a similar way as ComposableFilterBy:

* To test this solution on a Bookstore demo application use the following REST request:
  `BASE_URL/rest/Bookstore/BookGrid/?filters=[{"Filter":"Bookstore.WantedBooks"}]`
* To test it from C# with the domain object model, run the following code:
    ```C#
    var parameter = new Bookstore.WantedBooks { HighPriorityOnly = true };
    var wantedBooks = repository.Bookstore.BookGrid.Query(parameter);
    wantedBooks.ToString().Dump(); // Print the SQL query.
    wantedBooks.ToSimple().ToList().Dump(); // Load and print the books.
    ```
* Since Query concept returns a LINQ query, it can be **combined with other** composable
filters and **paging** features. See [Combining filters and other read methods](#combining-filters-and-other-read-methods) below for more info.

The Query concept is rarely used because it usually represents a workaround,
instead of a standard implementation pattern of a business feature
(as seen in the unconventional example above).
Use ComposableFilterBy instead, whenever possible.

* The Query concept also has some technical limitations. It cannot be used directly
  on an object that is already mapped to database with Entity Framework
  (results with NotSupportedException from EF).
  It can only be used on Browse, QueryableExtension, Computed and similar objects.
  If implemented on Computed data structure, the requests will not support
  generic property filters and paging.

## Development guidelines and advanced topics

### When not to write filters

If you need to use some simple filters in your application to select the data based on one or more properties' values
(for example, to allow users to search the grid for values in a date range, or search a text column by prefix)
**there is no need** to write a specific server-side filter in the DSL script.

* Rhetos REST web API automatically provides some **generic property filters**
  (see "Filters" in the [specification](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md#filters))
  and **paging features** for all queryable data sources such as Entity, Browse or SqlQueryable.
* Some examples of simple filters from the beginning of this article are not needed by the client application to filter the data;
  it can be done with the generic property filters.
  * `ItemFilter LongBooks` is just a simplified example for the educational purpose.
  * `ItemFilter CommonMisspelling` is actually required in the DSL scripts because a validation uses it.

Another anti-pattern is using ItemFilter or ComposableFilterBy to limit the dataset if
the user **does not have permissions** to see all the data.
In general, using the `_executionContext` (username or using any other context-sensitive information)
in the filter is a code smell.

* To limit the data based on the user's permissions, use [RowPermissions concept](RowPermissions-concept).

### Using additional data or system components in filters

For all filters and read methods, their code snippets can use the members of the repository class.

The most commonly used members are properties
`_domRepository` (it provides access to other data objects in the system)
and `_executionContext` (user information, database access, permissions
and some other system components).

* These members provide the same data as `var context` and `var repository`
in the examples from [Using the Domain Object Model](Using-the-Domain-Object-Model).
* See `ItemFilter ForeignAuthorXWithComments` above for the example usage of `_domRepository`.

To easily use other system components (with dependency injection),
new repository members can be added to any data structure's repository class
with the [RepositoryUses concept](Low-level-object-model-concepts).

### Filter name is filter parameter type

All filters and other read methods have a *name* that is same as
the *class* in the object model that provides the filter parameters.
For example, see [ComposableFilterBy with parameters](#composablefilterby-with-parameters)
section above.

Internally, the filter's name does not have a specific purpose in the system.
The filter is defined **purely by its parameter type**, and all filters
on a same data structure are implemented with the "overloading" pattern.
Even for filters that do not require parameters (ItemFilter),
an empty class will be created to allow filter selection by parameter type.

The extreme consequence of this principle is that any existing type
can be used as a parameter for the filter. If you are using an existing type,
then there is **no need to create a new parameter** class with a `Parameter` concept.

For example, add the following filters to the Book entity:

> 1. Given an array of titles, return all books that match those titles.
> 2. Given an author description, return all books that match the author,
>    either by author's ID, or by its name.

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
        Integer NumberOfPages;
        Reference Author Bookstore.Person;

        // Using a system type as a parameter.
        ComposableFilterBy 'System.String[]' '(query, repository, titles) =>
            {
                return query.Where(book => titles.Contains(book.Title));
            }';

        // Using an instance of an entity as a parameter.
        ComposableFilterBy 'Bookstore.Person' '(query, repository, author) =>
            {
                return query.Where(book => book.AuthorID == author.ID
                    || book.Author.Name == author.Name);
            }';
    }

    Entity Person
    {
        ShortString Name;
    }
}
```

Note that the **Parameter** concept is not declared, since both parameter types already exist in the system.

You can use these filters same as any other filter or read method in the object model or web API:

* Review the filter in the object model:
    ```C#
    repository.Bookstore.Book.Query(new[] { "abc", "def" })
        .ToString().Dump();
    repository.Bookstore.Book.Query(new Bookstore.Person { Name = "John" })
        .ToString().Dump();
    ```
* REST request example for the first filter:
  * `BASE_URL/rest/Bookstore/Book/?filters=[{"Filter":"System.String[]","Value":["abc","def"]}]`

### Combining filters and other read methods

As said before, the composable filters receive a LINQ query as an input and return a filtered query.
Other read methods can only generate new data from scratch.

* In your web request or in the C# code, you can easily combine multiple filters
such as **ItemFilter**, **ComposableFilterBy** or a generic property filter.
* In contrast, the **FilterBy** should only be used as a single filter parameter in the request.
* The **Query** filter parameter can be only be used at the beginning of the filter list.

Usage:

* To apply multiple filters in C# code, see "Filters" and "Applying-multiple-filters" sections
  in [Using the Domain Object Model](Using-the-Domain-Object-Model#Filters) article.
* See "Filter" in [RestGenerator specification](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md#filters)
  on how to apply filters in a REST request.

The following table shows examples of reading data from the REST service with some filter parameters.
The "**Processing workflow**" describes how the data is processed internally with Rhetos repository.
The "**Example URL**" is using the entities from the [Bookstore](https://github.com/Rhetos/Bookstore) demo application.

| GET request filter parameters example | Data processing workflow | Example URL |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| No filter parameter | Load() | `rest/Bookstore/Book/` |
| ItemFilter(param1) | Query() => Filter(param1) | `rest/Bookstore/Book/?filters=[{"Filter":"Bookstore.LongBooks"}]` |
| ItemFilter(param1), ItemFilter(param2) | Query() => Filter(param1) => Filter(param2) | `rest/Bookstore/Book/?filters=[{"Filter":"Bookstore.LongBooks"},{"Filter":"Bookstore.CommonMisspelling"}]` |
| FilterBy(param1) | Load(param1) | `rest/Bookstore/Book/?filters=[{"Filter":"Bookstore.ComplexSearch"}]` |
| FilterBy(param1), ItemFilter(param2) | Load(param1) => Filter(param2)<br>**ERROR**: *ItemFilter(param2) works only on a query, not on loaded array.* | `rest/Bookstore/Book/?filters=[{"Filter":"Bookstore.ComplexSearch"},{"Filter":"Bookstore.LongBooks"}]` |
| ItemFilter(param1), FilterBy(param2) | Query() => Filter(param1) => Load(param2)<br>**ERROR**: *FilterBy(param2) cannot take previous data as an input.* | `rest/Bookstore/Book/?filters=[{"Filter":"Bookstore.LongBooks"},{"Filter":"Bookstore.ComplexSearch"}]` |
| Query(param1), ItemFilter(param2) | Query(param1) => Filter(param2) |
| ItemFilter(param1), Query(param2) | Query() => Filter(param1) => Query(param2)<br>**ERROR**: *Query(param2) cannot take previous data as an input.* |
| GenericPropertyFilter(param1) | Query() => Filter(param1) | `rest/Bookstore/Book/?filters=[{"Property":"Code","Operation":"Contains","Value":"2"}]` |
| FilterBy(param1), GenericPropertyFilter(param2) | Load(param1) => Filter(param2)<br>**WARNING**: *This is inefficient because the Load method already loaded more data from database than required.* | `rest/Bookstore/Book/?filters=[{"Filter":"Bookstore.ComplexSearch"},{"Property":"Code","Operation":"Contains","Value":"2"}]` |

In the examples above, the result will be the same if you replace *ItemFilter* with a *ComposableFilterBy*.

## Read next

* [Data validations](Data-validations)
