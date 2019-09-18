The Hardcoded concept is used to easily create simple read-only entities and code tables.

Table of contents:

1. [Hardcoded concept](#hardcoded-concept)
2. [Usage in the object model](#usage-in-the-object-model)
3. [Usage in the database](#usage-in-the-database)

## Hardcoded concept

When you want a predefined set of entries for a read-only entity, what you have to do first is to define an Entity and
then write some migration scripts to insert those predefined data into the database.
To simplify this process you can use the Hardcoded concept.

Sample code:

```C
Hardcoded Genre
{
    LongString ShortDescription;
    Bool Fiction;

    Entry Fantasy
    {
        Value ShortDescription 'Fantasy is a genre of speculative fiction set in a fictional universe';
        Value Fiction 1;
    }

    Entry Crime
    {
        Value ShortDescription 'Suspense and mystery are key elements that are nearly ubiquitous to the genre';
        Value Fiction 0;
    }
}
```

The Hardcoded concept extends the Entity concept and takes care of updating the data in the database.
The Entry concept creates a row in the databse for every entry.
The Value concept adds the value to the column.
It uses the CONVERT function to insert the string literal that rapresents the value of the property into the column.

## Usage in the object model

The Hardoced concept allows you to use the predefined entries inside the object model.

Sample code:

```C
repository.Bookstore.Book.Query().Where(x => x.GenreID == Bookstore.Genre.Crime);
```

Every Entry creates a static property on the generated POCO class that returns the ID of the defined entry.

## Usage in the database

It is also possible to use the hardcoded entity inside SQL without directly writing the uuid of the row so that it can be type checked.

Sample code:

```C
SELECT
    *
FROM
    BookStore.Book book
WHERE
    book.GenreID = BookStore.Genre_Fantasy()
```

Every Entry concept creates a scalar function that returns the ID of the defined entry.
