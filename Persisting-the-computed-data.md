Rhetos provides a powerful mechanism for persisting the computed data. It allows low-risk changes in design of the application regarding what data will be computed "on request" (for example in a database view or a C# method), and what data will be precomputed, cached in a database table, and automatically updated (synchronized) if needed.

1. [Understanding the computed data](#understanding-the-computed-data)
2. [ComputedFrom concept](#computedfrom-concept)
   1. [Example 1](#example-1)
   2. [Example 2](#example-2)
3. [Automatically updating cached data](#automatically-updating-cached-data)
4. [Automatic recompute on deployment](#automatic-recompute-on-deployment)
   1. [Forcing recompute on deployment](#forcing-recompute-on-deployment)
   2. [Suppressing recompute on deployment](#suppressing-recompute-on-deployment)
5. [Legacy features](#legacy-features)
6. [See also](#see-also)

## Understanding the computed data

When designing the application's data model, try to separate the business data
in two distinct categories:

1. Data that is directly entered by user.
2. Data that is computed by the system.

It would be cleaner to separate this data into distinct entities,
even though Rhetos supports working with mixed data when needed.
For example it is possible to have an entity with some properties entered by user
and some properties automatically computed.

An extreme case would be a property that is both automatically computed and entered by the user,
depending on some condition.
We strongly recommend against it, since this kind of code and data is difficult to maintain in general:
In such systems the bugs are difficult to fix and the data corrupted by a bug is difficult to reconstruct.

The computed data usually comes in two forms:

1. **Computed on-the-fly**, on each read request. For example, implemented as a database view.
2. **Persisted**. For example, precomputed and cached in a database table, and automatically synchronized.

A decision between these two options can be changes easily, and should be mostly
based on the performance considerations.
A good rule-of-thumb is to write every computation to work on-the-fly,
then persist it if needed for better performance.
The basic code that computes the data should be written in a same way for both of this options,
whether it is a simple database view or a complex algorithm implemented in C#.

The following sections describe how to persist the computed data and keep control over it.

## ComputedFrom concept

> Note: This section needs improvement to clarify the mentioned concepts and examples,
> and conform to instructions in [Writing tutorial articles](Writing-tutorial-articles)

Persisting the computed data is done by developing the data source that computes the data
(usually an SqlQueryable), and saving the result into the database table (Entity).

Rhetos contains concepts that help automate the implementation.
**ComputedFrom** concept defines that some data on an entity is computed form
the given data source.

The following examples are taken from [Bookstore](https://github.com/Rhetos/Bookstore)
demo application, available on GitHub.

### Example 1

```C
Module Bookstore
{
    // ComputeBookInfo computes some information about the book by using SQL query.
    // The result is persisted (as a cache) in Entity BookInfo, and updated automatically.

    SqlQueryable ComputeBookInfo
        "
            SELECT
                b.ID,
                NumberOfComments = COUNT(bc.ID)
            FROM
                Bookstore.Book b
                LEFT JOIN Bookstore.Comment bc ON bc.BookID = b.ID
            GROUP BY
                b.ID
        "
    {
        Extends Bookstore.Book;
        Integer NumberOfComments;

        ChangesOnLinkedItems Bookstore.Comment.Book;
    }

    Entity BookInfo
    {
        ComputedFrom Bookstore.ComputeBookInfo
        {
            AllProperties;
            KeepSynchronized;
        }
    }
}
```

### Example 2

```C
Module Bookstore
{
    // ComputeBookRating computes some information about the book by using C# implementation
    // from an external DLL. The result is persisted (as a cache) in Entity BookRating,
    // and updated automatically.

    Computed ComputeBookRating
        'repository =>
        {
            var allBooksIds = repository.Bookstore.Book.Query().Select(b => b.ID).ToArray();
            return this.Load(allBooksIds).ToArray();
        }'
    {
        Extends Bookstore.Book;
        Decimal Rating;

        FilterBy 'IEnumerable<Guid>' '(repository, booksIds) =>
            {
                // Collecting the input data from the database:
                var ratingInput = repository.Bookstore.Book.Query(booksIds)
                    .Select(b =>
                        new Bookstore.Algorithms.RatingInput
                        {
                            BookId = b.ID,
                            Title = b.Title,
                            IsForeign = b.Extension_ForeignBook.ID != null
                        });

                // Calling the algorithm implemented in the external class "RatingSystem":
                var ratingSystem = new Bookstore.Algorithms.RatingSystem();
                var ratings = ratingSystem.ComputeRating(ratingInput);

                // Mapping the results to the "ComputeBookRating" output:
                return ratings
                    .Select(rating => new ComputeBookRating { ID = rating.BookId, Rating = rating.Value })
                    .ToArray();
            }';

        ChangesOnBaseItem;
        ChangesOnChangedItems Bookstore.ForeignBook 'IEnumerable<Guid>'
            'changedItems => changedItems.Select(fb => fb.ID)';
    }

    // One class per assembly is enough for external reference.
    ExternalReference 'Bookstore.Algorithms.RatingSystem, Bookstore.Algorithms';

    Entity BookRating
    {
        ComputedFrom Bookstore.ComputeBookRating
        {
            AllProperties;
            KeepSynchronized;
        }
    }
}
```

## Automatically updating cached data

**KeepSynchronized** concept enables automatic updates of the cache table when the source data is changed.
This feature requires **ChangesOnChangedItems** (or any related concept) defined on the source
to specify when to update the cached data, and which records need updating.

* **ChangesOnBaseItem** `<ComputationSource>` - If the computation is an extension of a base entity: When a base record is saved, the related cache record should be recomputed.
* **ChangesOnLinkedItems** `<ComputationSource> <ReferenceProperty>` - If the computation is an aggregation of a detail entity: When a detail record is saved, the related parent's cache record should be recomputed.
  * For example, if you are computing additional data about a document and that data depends on a detail entity (for example, the number of items, or the total amount) then the parameter "ReferenceProperty" should be the full name of the reference property from the detail entity.
* **ChangesOnReferenced** `<ComputationSource> <path to referenced entity>` - If the computation depends on a referenced entity: When a referenced entity record is saved, all cache records that reference it should be recomputed. Instead of a simple property, it is possible to specify a path across multiple references, separated by a dot, including the `Base` and `Extension_...` navigation properties.
* **ChangesOnChangedItems** `<ComputationSource> <entity> <filter name> <filter snippet>` - Programmable concept for defining dependency for computed items.
  * The "filter snippet" is a lambda expression that for an array modified dependent items returns filter parameter "what cached items need to be recomputed": `DependentEntity[] changedItems => filter parameter`.
  * The filter has to be applicable to both source and cache data structure. FilterAll, System.Guid[] and FilterCriteria are commonly used filters, supported by all entities.
  * Examples:
    * If *any* change of the dependent entity should result with recomputing *all* cache records, it can be declared this way: `ChangesOnChangedItems Test.Item 'FilterAll' changedItems => new FilterAll()';`
    * ChangesOnBaseItem generates:
      `ChangesOnChangedItems Test.Item 'Guid[]' 'changedItems => changedItems.Select(item => item.ID).ToArray()';`
    * ChangesOnLinkedItems generates:
      `ChangesOnChangedItems Test.Item 'Guid[]' 'changedItems => changedItems.Where(item => item.ParentID != null).Select(item => item.ParentID.Value).Distinct().ToArray()';`
    * ChangesOnReferenced generates something similar to:
      `ChangesOnChangedItems Test.Item 'FilterCriteria' 'changedItems => new FilterCriteria("path to referenced entity", "In", changedItems.Select(item => item.ID))';`
* **KeyProperties** - A list of properties that are used as a key when comparing the data from source to the cache. By default, the data is matched by ID.

Some usage examples are available in unit testing script [Computations.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/Computations.rhe).

## Automatic recompute on deployment

"Recompute" in Rhetos refers to the process of updating (also inserting and deleting) the persisted data in a table to match the new data provided by the source.

On each Rhetos database update (running *rhetos.exe dbupdate* or *DeployPackages.exe*),
for each computation that is marked with **KeepSynchronized**,
Rhetos checks if a sources for the computed data has been modified.
It if detects that the source has changed, it will automatically update (recompute) the persisted data.

This mechanism does not detect all possible changes, for example it *will* detect a change
in a SqlQueryable code snippet (if it is a source for a ComputeFrom),
but it *will not* detect a change in another SQL view that is indirectly used in this computation.

Note: you can check if the persisted data was recomputed during deployment
in `Logs\RhetosCli.log` or `Logs\DeployPackages.log`, under "KeepSynchronizedRecomputeOnDeploy" log entries.

### Forcing recompute on deployment

If you have made a change in computation, but the Rhetos did not detect it and did not run the *recompute* automatically,
there are two options to update the persisted data by yourself.

1. Create a [data-migration](Data-migration) script that updates the entry in the
   `Common.KeepSynchronizedMetadata` table that corresponds to the target entity
   by setting the `Context` value to 'RECOMPUTE' (this is an arbitrary string, chosen for readability).
   Rhetos keeps information on computation source context in this table. Updating the entry
   will result with a decision that the computation was modified in this release.
    * This is a **preferred solution**. Since this data-migration script is created along
      with the change in computation source, the *recompute* will be executed exactly once
      on each deployment environment, exactly *when* the change of the computation source is deployed.
2. Manually execute the Recompute method with LINQPad (see [example](Using-the-Domain-Object-Model)) after the deployment.
    * This will need to be done manually on each deployment environment (including other developers' PCs).

### Suppressing recompute on deployment

Automatically recomputing data on deployment may be undesirable in some situations because of performance issues,
while we still want to use `KeepSynchronized` for standard user's actions in the application.

Suppressing is specially interesting when an application contains some very large tables, and suppressing
unnecessary recomputes will significantly **improve deployment speed**.
A developer should suppress recomputing **on very large tables** if:

1. If Rhetos detects a change in computation source and will trigger recompute, but we know that the change does not affect the computation result, and there is no need to recompute all the data.
2. We need to recompute all the data, but we do not want to do it within deployment, to make sure that the deployment is finished in a reasonable amount of time.
    * The persisted data can be updated later manually, possibly in smaller batches, and executed over night.

There are different ways to do it:

1. The `/SkipRecompute` command-line switch for rhetos.exe and DeployPackages.exe.
   * Skip all computations for the current deployment.
2. Adding `SkipRecomputeOnDeploy` concept to the `ComputedFrom`. (v2.11+)
   * Skip this specific computation in all deployments.
3. Adding a data-migration script (described above) that updates the computation's `Context` to 'NORECOMPUTE'.
   * Skip this specific computation in the next deployment.
   * This option is usually chosen when a computation source has changed insignificantly, without affecting the result (see the case "1" above).

Note that when a recompute on deployment is skipped, Rhetos will not try recompute it again
on **next deployment**, unless there are some a new changes in source code that require
recomputing the data again.

## Legacy features

The **Persisted** concept is a helper that generates an `Entity` with a `ComputedFrom` on it.

1. One reason why the `ComputedFrom` concept if favored over the `Persisted` is [Composition over inheritance](https://en.wikipedia.org/wiki/Composition_over_inheritance) principle.
   `ComputedFrom` allows for more flexibility (multiple source, e.g.) and is not in conflict with other features that could also use inheritance.
2. `Persisted` currently suffers from a deployment performance issue ([#117](https://github.com/Rhetos/Rhetos/issues/117)).

## See also

* [Bookstore](https://github.com/Rhetos/Bookstore) demo application
