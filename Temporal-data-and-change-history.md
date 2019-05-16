Use the `History` concept to manage temporal data in an entity.
The the concept is used on an entity, the last version of each record is written in the main table,
while older versions are archived in the `_Changes` table.
The *ActiveSince* property is automatically added to the entity,
each version of the record is effective from that time.

Contents:

1. [Add temporal data management to an existing entity](#add-temporal-data-management-to-an-existing-entity)
2. [Modify the data of an entity with history](#modify-the-data-of-an-entity-with-history)

## Add temporal data management to an existing entity

To add the *temporal data management* features to an existing entity, simply add the **History** keyword.

You can choose which properties have history management enabled, add the **History** to each property,
or use **AllProperties** macro that automatically includes all properties.

Example:

```c
Module Demo
{
    Entity Contract
    {
        History { AllProperties; }

        ShortString Code { AutoCode; }
        ShortString Partner { Required; }
        Money Amount;

        Deactivatable;
    }
}
```

The `History` concept works in a backward-compatible way.
This means that any other feature that used the `Demo.Contract`,
before it became a temporal entity, can still work identically in the same way as before.

* The basic table for the entity `Demo.Contract` remains, with the existing features unchanged.
* The rows in table `Demo.Contract` represent the **currently active version** for each contract.

The `History` concept adds the following new features:

| | |
| --- | ---|
| DateTime **ActiveSince** | A new property is added to the entity; it records "since when" is the current value effective. |
| Entity **Contract_Changes** | A new database table is created `Demo.Contract_Changes`, that contains **previous versions** for the items. It has all properties from `Demo.Contract`, and additionally a column `EntityID` that references `Demo.Contract`. `ID` in the `Demo.Contract_Changes` is just an internal ID of a history record, and `EntityID` contains the ID value from `Demo.Contract`. |
| SqlQueryable **Contract_History** | View `Demo.Contract_History` is created that contains **all versions** of the Contract items. It is a union of `Contract` and `Contract_Changes`. |
| DateTime **ActiveUntil** | View `Demo.Contract_History` additionally has a computed property `ActiveUntil` that returns `ActiveSince` value from the next version of the record. |
| **Contract_AtTime** | An inline table-valued function `Demo.Contract_AtTime` is created, with a `DATETIME` parameter, that returns versions of all records that where active at the given time. It is not exposed in the object model or REST service. |

**Deactivatable** concept is not required on a history entity,
and these two concepts are not directly related, but are often used together.
Deleting a record for entity with History will automatically delete all the history records.
This is why we usually only allow users to deactivate a records, instead of deleting it.

## Modify the data of an entity with history

The entity `Demo.Contract` represents the latest version of the contact.

**Insert and delete** operations will insert a new contract or delete a contract
along with it's history records.

**Updating** a record in the `Demo.Contract` can have different consequences,
based on the given value of `ActiveSince` property:

1. If ActiveSince **is null**, this means that the new version
   of the contract data is effective since now. The old data from `Demo.Contract` will
   be moved to `Demo.Contract_Changes` table, and the new data will be saved
   to the `Demo.Contract` table.
   * This is a *backward-compatible* usage. The rest of the system does not need
     to be aware that this entity has history enabled.
2. If ActiveSince **has the value set**, then the
   new contract data is effective since that data. In this case the system will either
   1. insert a new history record in Contract_Changes table,
   2. update an existing history record, if the ActiveSince matches some existing record,
   3. or update the latest version in Contract table, if the ActiveSince matches the latest record.

> In practice this means that if you load the latest record, change some properties,
but leave the **ActiveSince unchanged**, and save it back, this will **not result with
a new entry** in the contract's history.
It will just update the latest entry, because the saved record has the same
ActiveSince value, which means it is not active "since now", instead it is
interpreted as a modification of the historical data.

The following code shows an example of data modifications on the `Contract` entity.
This example uses [object model](Using-the-Domain-Object-Model) directly,
but using the REST Web API would give the same result.

```cs
var c = new Demo.Contract { Code = "+++", Partner = "X", ActiveSince = null };
repository.Demo.Contract.Insert(c);

// Create a new version of the contract:
System.Threading.Thread.Sleep(1000);
c = repository.Demo.Contract.Load(item => item.ID == c.ID).Single(); // Read the latest version.
c.Partner = "XY";
c.ActiveSince = null; // We need to set ActiveSince to null or DateTime.Now, to create a new version!
repository.Demo.Contract.Update(c);

// Update an existing version of the contract:
System.Threading.Thread.Sleep(1000);
c = repository.Demo.Contract.Load(item => item.ID == c.ID).Single(); // Read the latest version.
c.Partner = "XYZ";
c.Amount = 123;
repository.Demo.Contract.Update(c);

repository.Demo.Contract_History.Load().Dump();
```

Result:

| ID | EntityID | Code | Partner | Amount | ActiveSince | ActiveUntil |
| --- | --- | --- | --- | --- | --- | --- |
| 10ff... | e7bc... | 001 | X | null | 16.5.2019 13:19:14 | 16.5.2019 13:19:15 |
| e7bc... | e7bc... | 001 | XYZ | 123.00 | 16.5.2019 13:19:15 | null |

Note that there were 3 versions saved ("X", "XY" and "XYZ"),
but are only 2 version in the database ("X" and "XYZ").
This happened because the version with "XYZ" had the same ActiveSince value
as the "XY", which means that we were updating an *existing* historical record.
