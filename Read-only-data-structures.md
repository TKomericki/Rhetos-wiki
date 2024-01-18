# Read-only data structures

This article covers the basic DSL concepts that encapsulate loading or querying the data.

There are different types of data structures (objects with properties) in Rhetos.
Entity is one of them, it is mapped to a database table.
Browse and SqlQueryable are common examples of read-only data structures.
SqlQueryable is mapped to a database view.
Browse is internally represented as a single LINQ query.

Note: Even though the following concepts use different technologies to read the data
(simple relations, SQL query or C# function), they are all represented and accessed
in the same uniform way in the object mode.
Any of those can be easily extended with other custom loaders or filters
that use C# code or LINQ queries to read the data with specific parameters.

Prerequisites:

* The examples in this article are based on examples from the **previous tutorial article**:
  [Data model and relationships](Data-model-and-relationships).

Contents:

1. [Browse concept](#browse-concept)
2. [SqlQueryable concept](#sqlqueryable-concept)
3. [External SQL scripts](#external-sql-scripts)
4. [Using the computed data in Browse](#using-the-computed-data-in-browse)
5. [Computed concept](#computed-concept)

## Browse concept

The Browse concept is used for simple data queries,
when we only need to select some properties from an entity and from other data structures
related to the base entity (directly or indirectly).

For example:

> Write a data source that returns a list of books
> (see the previous tutorial [article](Data-model-and-relationships))
> for the grid that is displayed to the user in the web application.
> The grid should contain the following columns:
>
> * Code
> * Title
> * Author's name
> * Translator's name

Solution:

```C
Browse BookGrid Bookstore.Book
{
    Take Code;
    Take Title;
    Take 'Author.Name';
    Take TranslatorName 'Extension_ForeignBook.Translator.Name';
}
```

The **Browse** concept will create a readable data structure named `BookGrid`,
that returns the selected properties from the `Book`.

The **Take** concept selects the properties, starting from the base entity (`Bookstore.Book`).

* `Code` and `Title` are taken directly from the Book.

Instead of a simple property, it is possible to **specify a path** across the references,
separated by a dot.
In addition to the Reference properties, the path can contain other generated navigation properties:
`Base` (navigation from extension to base), `Extension_<extension name>` (navigation from base to an
extension) and `ID` (as Guid property).

* Author's name is taken from the referenced entity by the path `Author.Name`.
  This property will be automatically named by simple concatenation: "AuthorName".
* Translator's name is declared with a similar path.
  The property's name is manually set to `TranslatorName`.
  Note that an extended entity ForeignBook (see the [Extends](Data-model-and-relationships) concept)
  creates the navigation property `Extension_ForeignBook`, from the base entity "Book" to the extension.

The Browse data structure is registered as an extension of its base entity.
It also includes the ID property from the base entity (`Book`).

Technical notes:

* In the application's object model and in the web API, Browse data structure
  is used for reading data in the same way as entity or any other data structure type.
  A client application does not know what kind of the data source is behind
  <https://localhost:5000/rest/Bookstore/BookGrid/>.
* The Browse concept is internally represented as a single LINQ query in the generated application.
  You can find the generated LINQ query in the file
  `src\Bookstore.Service\obj\Rhetos\Source\Repositories\BookstoreRepositories.cs`
  by searching for "Extension_ForeignBook.Translator.Name".

Because of its simplicity and extensibility, Browse is a preferred concept to
use when possible. Use other concepts in this article only if the requirement
cannot be solved with Browse.

1. Simplicity: Pure declarative code; less room for bugs.
2. Extensibility: For example, a custom DSL script can extend an existing Browse
   with new properties for a specific customer.
   In contrast, if a core feature is implemented with an SQL query,
   or a manually written C# code, then a custom package cannot easily extend the core feature,
   it will usually override it and create an issue if the core feature is modified in the future.

## SqlQueryable concept

Most commonly used way of extending an entity with the computed data
is the `SqlQueryable` concept, using an SQL query to define the computation.

It is also often used to provide the data for grid and lookup components
in the user interface, if a simple `Browse` will not suffice.

Task:

> Allow the client application to get the total number of comment for a given book.

Solution:

```C
SqlQueryable BookInfo
    "
        SELECT
            b.ID,
            NumberOfComments = COUNT(c.ID)
        FROM
            Bookstore.Book b
            LEFT JOIN Bookstore.Comment c ON c.BookID = b.ID
        GROUP BY
            b.ID
    "
{
    Extends Bookstore.Book;
    Integer NumberOfComments;

    AutodetectSqlDependencies;
}
```

The **SqlQueryable** concept creates a view in the database,
a class in the object model mapped to the view, and a web API.
In the object model and in the web API, SqlQueryable is used in a same way as Browse or Entity.

The example above shows a typical usage of the **Extends** concept in the computed data.

* It is not required, but is very useful to mark this data structure as an extension of the Book
  (more info [here](Data-model-and-relationships#one-to-one-relationship-extensions)).
* Because of the Extends concept, it is important for the SQL query to return the `ID` of the book,
  so that the computed data can be connected to the base entity.
* The Extends concept creates an relation between the entities in the object model.
  This extension can be accessed from the base entity using the property `book.Extension_BookInfo`.

The **AutodetectSqlDependencies** statement will result with automatic detection
of the dependencies by analyzing the SQL query.
This view depends on the Book and Comment entities.
That information is needed for Rhetos to know in what order these database objects should be created:
The Book table must be created before BookInfo view because the view depends on the table.
See [Dependencies between database objects](Database-objects#dependencies-between-database-objects)
for more information on this topic.

## External SQL scripts

Task:

> Extract the SQL snippet of `SqlQueryable BookInfo` from the DSL script to a separate SQL script.

Solution:

Any string parameter can be placed in an external file and referenced from the DSL scripts
(see [string literals](Rhetos-DSL-syntax#String-literals)):

```C
SqlQueryable BookInfo <SQL\BookInfo.sql>
{
    Extends Bookstore.Book;
    Integer NumberOfComments;

    AutodetectSqlDependencies;
}
```

Create a file "BookInfo.sql" in the folder `DslScripts\SQL\`, with the following content:

```SQL
SELECT
    b.ID,
    NumberOfComments = COUNT(c.ID)
FROM
    Bookstore.Book b
    LEFT JOIN Bookstore.Comment c ON c.BookID = b.ID
GROUP BY
    b.ID
```

"SQL" subfolder is used here as a convention to improve code structure.

Note that writing an SQL script in a separate file is **preferred for longer SQL scripts**,
because the .sql file can be developed and tested at the source,
*without* copying and pasting between SSMS and the DSL script.

* In VS Code editor, you can use the "mssql" extension to edit this SQL script
  with IntelliSense enabled or execute it from the editor.

For more info see "String literals" in [Rhetos DSL syntax](Rhetos-DSL-syntax).

## Using the computed data in Browse

Browse does not allow computations inside it, but is useful for its simplicity and extensibility
(especially if your solution needs to be customizable for certain customers without modifying the core features).
This is why sometimes the Browse is used to provide data for a client grid even
if it needs to contain some data that is computed on-the-fly.

Task:

> Add the NumberOfComments property from BookInfo to the BookGrid.

Solution:

```C
Browse BookGrid Bookstore.Book
{
    Take Code;
    Take Title;
    Take 'Author.Name';
    Take TranslatorName 'Extension_ForeignBook.Translator.Name';
    Take NumberOfComments 'Extension_BookInfo.NumberOfComments';
}
```

`SqlQueryable BookInfo` is an extension of the Book (see `Extends` concept above),
therefore it is easily accessible in the LINQ query from the Book
by using the navigation property `Extension_BookInfo`.

## Computed concept

The Computed concept allows developer to create a data source that is implemented with a C# code.
It is usually used for data processing when an SQL query is not an efficient solution,
and the algorithm is often implemented in an external DLL.

Task:

> An application should provide the expected ratings for all books,
> based on some basic information on the books.
> The rating algorithm is the following:
> If the title contains text "super", add 100 point.
> If it contains "great", add 50 point. If the book is foreign, add 20%.

Solution:

```C
Module Bookstore
{
    Computed ExpectedBookRating 'repository =>
        {
            var books = repository.Bookstore.Book.Query()
                .Select(b =>
                    new
                    {
                        b.ID,
                        b.Title,
                        IsForeign = b.Extension_ForeignBook.ID != null
                    })
                .ToList();

            var ratings = new List<ExpectedBookRating>();
            foreach (var book in books)
            {
                decimal rating = 0;

                if (book.Title?.IndexOf("super", StringComparison.InvariantCultureIgnoreCase) >= 0)
                    rating += 100;

                if (book.Title?.IndexOf("great", StringComparison.InvariantCultureIgnoreCase) >= 0)
                    rating += 50;

                if (book.IsForeign)
                    rating *= 1.2m;

                ratings.Add(new ExpectedBookRating { ID = book.ID, Rating = rating });
            }

            return ratings.ToArray();
        }'
    {
        Extends Bookstore.Book;
        Decimal Rating;
    }
}
```

The **Computed** concept create classes in object model similar to Browse or SqlQueryable,
but its data is not mapped to database (or Entity Framework).

In the object model and in the web API, Computed is used in a same way as other data structures
(Browse, SqlQueryable or Entity) for reading the data.
For example, <https://localhost:5000/rest/Bookstore/ExpectedBookRating/> will return the list of book ratings.

In the example above, the C# code snippet uses the generated object model
to query the books from the database with `repository.Bookstore.Book.Query()`.
For more info on this topic see [Using the Domain Object Model](Using-the-Domain-Object-Model).

The Computed concept can also be useful if you need to read the data
from other systems and provide it as a Rhetos data structure. For example:

```C
Module Bookstore
{
    Computed ExternalCustomer 'repository =>
        {
            // Gets a list of users from another web API and returns it as a Rhetos data structure.
            var httpClient = new System.Net.Http.HttpClient();
            var usersJson = httpClient.GetStringAsync("https://jsonplaceholder.typicode.com/users").Result;
            var users = Newtonsoft.Json.JsonConvert.DeserializeObject<List<System.Dynamic.ExpandoObject>>(usersJson);
            var names = users.Select((dynamic user) => user.name);
            return names.Select(name => new ExternalCustomer { Name = name }).ToArray();
        }'
    {
        ShortString Name;
    }

    // For older Rhetos apps built with DeployPackages, add the required assembly references:
    ExternalReference 'Newtonsoft.Json.JsonConvert, Newtonsoft.Json';
    ExternalReference 'System.Net.Http.HttpClient, System.Net.Http, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a';
}
```
