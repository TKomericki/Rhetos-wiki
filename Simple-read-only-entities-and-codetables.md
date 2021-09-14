The **Hardcoded** concept is used to easily create simple read-only entities and code tables.

Table of contents:

1. [Hardcoded concept](#hardcoded-concept)
2. [Usage in the object model](#usage-in-the-object-model)
3. [Usage in the database](#usage-in-the-database)
4. [Usage in polymorphic implementation](#usage-in-polymorphic-implementation)

## Hardcoded concept

When you want a predefined set of entries for a read-only entity, a manual approach would be to define an Entity and
then write some migration scripts to insert those predefined data into the database.

To simplify this process you can use the **Hardcoded** concept:

Sample code:

```c
Hardcoded Genre
{
    ShortString Label; // Short text displayed to user.
    LongString Description;
    Bool IsFiction;

    Entry ScienceFiction
    {
        Value Label 'Science fiction';
        Value Description 'A speculative fiction with imagined elements that are inspired by natural sciences or social sciences.';
        Value IsFiction 1;
    }

    Entry Biography
    {
        Value Label 'Biography';
        Value Description 'A written narrative of a person's life.';
        Value IsFiction 0;
    }
}
```

The **Hardcoded** concept extends the Entity concept and takes care of updating the data in the database.

The **Entry** concept creates a **row in the database table** for every entry.

* The entry name (`ScienceFiction` and `Biography` in the example above) is automatically available as a `ShortString Name` property on the Hardcoded entity.
* The entry's ID property value is automatically generated based on its name.
  Optionally, a custom ID value can be provided as a parameter,
  for example `Entry ScienceFiction '3DA20360-D212-438A-B43D-EA15800BA9E9'` (since Rhetos v4.3).

The **Value** concept adds the value to the column.
It uses the CONVERT function in database to insert the string literal that represents the value of the property into the column.

## Usage in the object model

The Hardcoded concept allows you to use the predefined entries inside the object model.

Sample code:

```CS
repository.Bookstore.Book.Query().Where(x => x.GenreID == Bookstore.Genre.ScienceFiction);
```

Every Entry creates a static property on the generated POCO class that returns the ID of the defined entry.
See `Bookstore.Genre.ScienceFiction` in the example above.

## Usage in the database

It is also possible to use the hardcoded entity inside SQL without directly writing the GUID of the row so that it can be type checked.

Sample code:

```SQL
SELECT
    *
FROM
    BookStore.Book book
WHERE
    book.GenreID = BookStore.Genre_ScienceFiction()
```

Every Entry concept creates a **scalar function that returns the ID** of the defined entry.
See `BookStore.Genre_ScienceFiction()` in the example above.

## Usage in polymorphic implementation

For example, implement a shipment event "ApproveShipment" (see [Polymorphic concept](Polymorphic-concept))
that returns "Approved" as a new status.

Solution:

```C
Hardcoded ShipmentStatus
{
    Entry Preparing;
    Entry Approved;
    Entry Delivered;
}

Polymorphic ShipmentEvent
{
    DateTime EffectiveSince;
    Reference Shipment;
    Reference NewStatus Bookstore.ShipmentStatus;
}

Entity ApproveShipment
{
    DateTime EffectiveSince { CreationTime; }
    Reference Shipment;

    Is Bookstore.ShipmentEvent
    {
        Implements Bookstore.ShipmentEvent.NewStatus Bookstore.ShipmentStatus.Approved;

        // Slower alternative: Calling the database function:
        //Implements Bookstore.ShipmentEvent.NewStatus "Bookstore.ShipmentStatus_Approved()";
    }
}
```

The `Implements` concept provides an option to **directly reference the hardcoded
entry** `Bookstore.ShipmentStatus.Approved` to return the entry ID.
This will result with the optimized literal value in the generated database code.

Note that implementation of the polymorphic property can be specified with an SQL code snippet,
so it can call the database function `Bookstore.ShipmentStatus_Approved()` to return the status ID
(see the previous section). This option can be slower in situations when the function needs
to be called on large number of records.
