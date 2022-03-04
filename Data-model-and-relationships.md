This article shows how to implement entities,
how to define entity relationships and what backend technologies are readily available
(database table, business layer C# classes, JSON web API).

Prerequisites:

* To build and run the examples in this article, first setup the development project:
  [Creating a new WCF application with Rhetos framework](Creating-new-WCF-Rhetos-application).

Contents:

1. [Entities and properties](#entities-and-properties)
2. [One-to-many relationship (master-detail)](#one-to-many-relationship-master-detail)
3. [One-to-one relationship (extensions)](#one-to-one-relationship-extensions)
4. [Many-to-many relationship (join table)](#many-to-many-relationship-join-table)
5. [Relationships summary](#relationships-summary)
6. [See also](#see-also)

## Entities and properties

The Rhetos platform allows simple and fast development of new entities.
All you need to do is define its properties and their types.

For example, consider the following task:

> Develop an application backend with the following entities:
>
> * Person (has Name)
> * Book (has Code, Title, NumberOfPages)

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { Unique; Required; }
        ShortString Title { Required; }
        Integer NumberOfPages;
    }

    Entity Person
    {
        ShortString Name;
    }
}
```

Place this code in the *DslScripts\Books.rhe* file, and build the application.
Review the generated database objects in SQL Server Management Studio.

The `Module` concept creates a *namespace* in the generated C# code, and a *schema* in the database.

* Note that modules are not directly related to deployment packages:
  A single deployment package can contain DSL scripts with entities for many modules.
  Also, multiple deployment packages can create or extend entities in a single module.
* Choosing a module name is similar to namespaces: the name should represent a topic,
  for example Sales. It is often in plural.
  A small application will usually have only one business module with the same name
  as the application, while larger applications might have few modules.

The `Entity` concept generates the following application code:

* a table in the database, with the uniqueidentifier primary key column "ID"
* a POCO class in the C# object model (a simple property holder)
* a repository class in the C# object model, with methods containing all the business logic and data access
* an ORM mapping
* Additional Rhetos plugins can generate different application features for each entity in the system.
  For example, the [RestGenerator](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md)
  plugin generates the REST methods for reading and writing the entity's records.

Properties:

* See the [Data structure properties](Data-structure-properties) article
  for a list of simple property data types.

Simple business rules:

* You can mark any property to be `Required`, it will generate an on-save validation.
  * Note: Required properties are still created with nullable types in C# and database.
* The `Unique` concept generates a unique SQL index on the column.

## One-to-many relationship (master-detail)

"1 : N" relationship is declared by the `Reference` from the dependent entity to the other one.

For example, expand the previous task solution with the following requirements:

> * Book also has an author.
>   Book's author is a *Person*.
> * Each book can have multiple comments.
>   Each *Comment* contains just a simple text.
>   The comments are considered as part of the book:
>   they are displayed and entered with other book's properties at the same form
>   by the same user.

Solution:

```C
Module Bookstore
{
    Entity Book
    {
        ShortString Code { Unique; Required; }
        ShortString Title { Required; }
        Integer NumberOfPages;
        Reference Author Bookstore.Person;
    }

    Entity Person
    {
        ShortString Name;
    }

    Entity Comment
    {
        Reference Book { Detail; }
        LongString Text;
    }
}
```

`Reference` property represents the "N : 1" relationship in the data model,
and usually a lookup field in the user interface.

* In the database it creates a Guid column (with an "ID" suffix)
  and an associated foreign key constraint.
  * In the example above, `Reference Author` creates the foreign key column *AuthorID*
    in the *Book* table.
* In the generated C# application code it creates
  * a [navigation property](https://docs.microsoft.com/en-us/ef/ef6/fundamentals/relationships)
  for use in Entity Framework LINQ queries,
  * and a simple Guid property (with an "ID" suffix) for raw data loading and saving.

The **simplified syntax** can be used for Reference (without the referenced module and entity name,
see `Reference Book` above) if the property name is same as the referenced entity,
and the referenced entity is in the same module.

`Detail` concept can be added on a Reference property when the dependent entity is considered
**a part of** the parent entity from the business perspective.
Usually this means that the user will enter the data together on the same form.

* This will automatically add `Required` (detail cannot exist without parent),
  `CascadeDelete` and `SqlIndex` on the Reference property.
* Some other features also act differently on the part-of relationship type:
  for example the row permissions are automatically inherited from base to dependent entity.

Note: The `Detail` concept does not change the data model or the web API of the parent entity.
The parent and detail can each be loaded and saved as separate entities.
This is compliant with Rhetos principle to keep features decoupled where possible.
The parent entity could be extended by the [LinkedItems](Data-structure-properties) concept
to include details in the LINQ queries.

## One-to-one relationship (extensions)

One-to-one relationship is declared by the `Extends` concept.

For example, expand the previous task solution with the following requirements:

> * A book can be *ChildrensBook* (has a suggested age range: AgeFrom, AgeTo).
> * A book can be *ForeignBook* (has OriginalLanguage and Translator). Translator is a *Person*.
> * Note: Some books are neither of above, some books are both children's and foreign at the same time.

Solution:

```C
Entity ChildrensBook
{
    Extends Bookstore.Book;

    Integer AgeFrom;
    Integer AgeTo;
    IntegerRange AgeFrom AgeTo; // A simple validation.
}

Entity ForeignBook
{
    Extends Bookstore.Book;

    ShortString OriginalLanguage;
    Reference Translator Bookstore.Person;
}
```

`Extends` concept is used when the dependent entity is an extension of the base entity.
For example, the extension may contain a group of properties that are applied only to
some records of the base entity, so it could be wasteful to include them in the base entity's table.

* In the database it creates a foreign key from the extension table's ID column to the base table's ID column.

The extension may exist for each base record ("1 : 1" relationship) or for a subset of
base records ("0..1 : 1" relationship), there is no distinction in the data model.

Data modelling considerations:

* Note that the Extends concepts **does not change** the data model (or web API) of the **base entity**.
  Also, the extension does not contain the properties from the base entity, it only reference the base entity.
  The base entity and the extension can each be loaded and saved as **separate entities**.
* The extensions are natural pattern for implementing **additional information** to a base entity,
  that is not always saved or read at the same time or by the same user as the base entity.
* One base entity can have multiple extension entities.
  In the example above, some books can be both children's and foreign at the same time,
  and some books are neither.
* The extensions could be used to implement the **object-oriented inheritance** in the database,
  but its downside it that the database structure and constraints do not enforce that
  the base entity has *one and only one* extension.
  In most situations, the [Polymorphic](Polymorphic-concept) concept could be more suited
  for implementing the inheritance, instead of the Extends concept.

Navigation properties for LINQ queries:

* In the generated application code, the Extends concept creates the following navigation properties for use in Entity Framework LINQ queries:
  * `Base` property on the extension entity that references the base entity.
  * `Extension_<ExtensionName>` property on base entity that references the extension.
    If the extended entity is in a different module, the property name is `Extension_<ModuleName>_<EntityName>`.
* For example, the *Book* entity has *Extension_ChildrensBook* and *Extension_ForeignBook* navigation
  properties for easy navigation from book to the extensions.
  If we want to access the Translator from the Book in the C# code, we can write:
    ```cs
    var translators = repository.Bookstore.Book.Query()
        .Select(book => book.Extension_ForeignBook.Translator.Name);
    ```

Extends vs UniqueReference concept:

* The Extends concept behaves as a "part-of" relationship to the base entity,
  similar to the Detail on Reference (see the description of Detail concept above).
  This means that **from the business perspective, the extension is considered a part of the base entity**,
  its data is probably displayed and entered by user on the same form.
  Alternatively, if one-to-one relationship is needed on some entities,
  but the extended entity should not be considered as a part of the base entity
  (for example, if the row permissions should not be automatically inherited from base to dependent entity),
  than `UniqueReference` concept can be used instead of the Extends concept.
* The syntax is same, and both concepts create the same foreign key from the extended table's ID to the base table.
  The only difference in CommonConcepts DSL is that Extends concept creates automatic inheritance
  of row permissions and CascadeDelete.

## Many-to-many relationship (join table)

"N : N" relationship is usually implemented as an associative table.

For example, expand the previous task solution with the following requirements:

> * Add a list of topics. Each *Topic* has a *Name*.
> * Each book can be related to multiple topics.
>   Each topic can be assigned to multiple book (N : N relationship).

Solution:

```C
Entity Topic
{
    ShortString Name { Unique; Required; }
}

Entity BookTopic
{
    Reference Book { Detail; }
    Reference Topic { Required; }

    UniqueMultiple 'Book Topic';
}
```

Currently there is no high-level concept in Rhetos CommonConcepts that would represent a many-to-many relationship.
This kind of relationship is usually implemented with an standard
[associative entity](https://en.wikipedia.org/wiki/Associative_entity) pattern:
a separate entity that connects the two main entities.

Note that the Detail concept can also be used in the associative table for many-to-many relationship,
for example if the relationship should be considered as a logical part of one of the entities
(a book can have multiple topics, and deleting a books implies deleting the related BookTopic records).

## Relationships summary

The following DSL keywords are available for relationships between entities (and other data structures).

| | Simple relationship | "Part-of" relationship |
| --- | --- | --- |
| **1 : N** |  Reference | Reference { Detail; } |
| **0..1 : 1** | UniqueReference | Extension |

## See also

* [Rhetos DSL syntax](Rhetos-DSL-syntax)
* [Data structure properties](Data-structure-properties)
* [Bookstore](https://github.com/Rhetos/Bookstore) demo application
