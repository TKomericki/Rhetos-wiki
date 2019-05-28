# Low-level object model concepts

While Rhetos encourages developers to implement most business features
**declaratively** (by simply stating the features in a DSL script),
instead of **imperatively** (by writing lines of C# code),
there will always be situations when a business feature cannot simply be mapped
to an existing concept that already implements the standard business pattern.

One of the basic principles in Rhetos framework it to allow developers
to work in a *classic way*, coding the features **directly in C#** or SQL,
by using the low-level concepts described in this article
(and in [Database objects](Database-objects) for SQL).
This is important to avoid hindering the development progress in case of any missing feature.

> A good rule of thumb is to **avoid** these low-level concepts if you are implementing a standard business pattern.
> Seeing low-level concepts in DSL scripts is a sign that we are not looking at a standard feature, but **a very specific uncommon feature**.
> For example, if the purpose if the feature is "data validation", please use the InvalidData concept instead.
>
> Breaking down the requirements to a set of **standard business features** is a good way to make your software more maintainable.
> Also consider developing a new concept if you need to implement a standard business pattern, but there is no existing concept available.

Contents:

1. [SaveMethod](#savemethod)
   1. [Understanding the generated Save method](#understanding-the-generated-save-method)
   2. [ArgumentValidation](#argumentvalidation)
   3. [Initialization](#initialization)
   4. [LoadOldItems (shared old values)](#loadolditems-shared-old-values)
   5. [OldDataLoaded](#olddataloaded)
   6. [OnSaveUpdate](#onsaveupdate)
   7. [OnSaveValidate](#onsavevalidate)
   8. [AfterSave](#aftersave)
2. [Add features to repository class](#add-features-to-repository-class)
   1. [RepositoryUses](#repositoryuses)
   2. [RepositoryMember](#repositorymember)

## SaveMethod

The SaveMethod concept allows developers to extend entity's Save method,
by **injecting a custom C# code** that will be executed when saving the records
(inserting, updating and deleting).

There are different extension points at **different positions** in the Save method,
that are intended for inserting a code with different purpose.
The following table shows order in which the code snippets are executed.

| Position in Save method | Intended purpose of the inserted C# code |
| --- | --- |
| 1. ArgumentValidation | To verify if the parameters could break the rest of the Save method's business logic. Use *OnSaveValidate* instead for standard data validations. |
| 2. Initialization | To initialize or change the data, before saving it to the database. If possible, use [DefaultValue](Implementing-simple-business-rules#automatically-generated-data) instead. |
| 3. OldDataLoaded | To initialize or change the data, before saving it to the database, if previous data state needs to be considered. See related *LoadOldItems* concept. |
| 4. OnSaveUpdate | To modify data in other dependent entities that need to be updated (recomputed) after the current Save operation. If possible, use [ComputedFrom](Persisting-the-computed-data) instead. |
| 5. OnSaveValidate | To implement a custom data validation. If possible, use *InvalidData* instead, for standard data validations, or [RowPermissions](RowPermissions-concept) for user permissions. |
| 6. AfterSave | The inserted code will be execute after validations. |

Note that the data is **saved to the database** between OldDataLoaded and OnSaveUpdate,
but the database transaction will be committed later
(at the very end of the web request) if all validations have passed.
This means that the code in OnSaveUpdate, OnSaveValidate and AfterSave can
use other features implemented in database, such as views.

In addition, SaveMethod can contain **LoadOldItems** concept,
a simple helper for reading an old version of the data that can
be reused in different business rules.
It will load the old data between Initialization and OldDataLoaded.

### Understanding the generated Save method

The **following examples** are based on features from
[Bookstore](https://github.com/Rhetos/Bookstore) demo application for the following entities:

```c
Module Bookstore
{
    Entity Book
    {
        ShortString Title { Required; }
    }

    Entity Review
    {
        Reference Book { Required; }
        Integer Score { Required; MinValue 1; MaxValue 5; }
        LongString Text;

        SaveMethod
        {
            // ... Insert the examples from this chapter here. ...
        }
    }
}
```

When writing low-level code you will need to understand the environment
**where this code will end up**. For example,
what local variables and other features are available to be used in your code snippet:

1. In the Bookstore demo application open the generated file `dist\BookstoreRhetosServer\bin\Generated\ServerDom.Repositories.cs`.
2. Find the `Save` method in `class Review_Repository`:
   * Note that it receives lists (IEnumerable) of items that will be inserted,
     updated and deleted, as the parameters: `insertedNew`, `updatedNew` and `deletedIds`.
   * You can use those variables in the code snippets to **read or change
     what will be saved**.
   * The last property `checkUserPermissions` distinguishes if the save
     method is called directly from the user (a client application) or
     indirectly from another feature in the object model.
3. In the Save method find comments with the following format: `/*DataStructureInfo WritableOrm ... Bookstore.Review*/`.
   * These comments (called "tags" in Rhetos object model) are **extensions points**
     for inserting additional code into the Save method.
   * The concepts from this article will use these tags to insert your code snippets
     to different positions in the Save method.

### ArgumentValidation

Use this concept to deny the Save operation if the provided data could break
the rest of the Save method's business logic.
Available since Rhetos v2.12.

The usage is similar to Initialization and OnSaveValidate concepts (see their examples below).

* The ArgumentValidation code snippet is expected to use `insertedNew`, `updatedNew`
  and `deletedIds` parameters to analyze the data that will be saved and
  throw `UserException` or `ClientException` if the parameters are incorrect.
* For **standard data validations** use InvalidData concept instead, or see
  OnSaveValidate low-level concept below.
  The ArgumentValidation should only be used if there are some non-standard issues
  that might arise if the validation is executed later in the Save method.

### Initialization

Use Initialization to **initialize or change the data**,
before saving it to the database and before applying other business rules.

Example task:

> Use the low-level concept "Initialization" to set the review Text,
> if not provided by the user.
> The text should be "I like it.", if the score is 3 or higher,
> or "I don't like it." otherwise.

Solution:

```c
Entity Review
{
    SaveMethod
    {
        Initialization DefaultTextFromScore
            '
                foreach (var item in insertedNew)
                    if (string.IsNullOrEmpty(item.Text) && item.Score != null)
                        item.Text = item.Score.Value >= 3
                            ? "I like it"
                            : "I don''t like it";
            ';
    }
}
```

The initialization code snippet usually uses `insertedNew`, `updatedNew` and `deletedIds`
parameters to analyze and modify the data that will be saved.

Note that this example is a just a demo for SaveMethod.
The **DefaultValue** concept would be much better approach for this example,
to avoid using low-level concepts.

### LoadOldItems (shared old values)

When updating or deleting records, LoadOldItems will load old values from the database.
The loaded values can then be used in other parts of the Save method (usually in
OldDataLoaded or OnSaveValidate), for example to compare them to the new updated values,
or to deny modification of some records.

* If **multiple** business rules require old data to be loaded,
  it will be merged and loaded in a **single database request**.
* Each property must be explicitly selected with *Take* keyword.
* Old values can include referenced objects (the reference path can have multiple steps).

The following example loads the review score and the referenced book's title.
This data will be used later in implementation of other business rules:
`OnSaveUpdate AppendTextIfScoreChanged` and `OnSaveValidate DenyChangeOfLockedTitle`
(see the chapters below).

```c
Entity Review
{
    SaveMethod
    {
        LoadOldItems
        {
            Take Score;
            Take 'Book.Title';
        }
    }
}
```

The DSL concepts above will generate two local variables in the Save method,
 `updatedOld` and `deletedOld`, that contain the old values of updated and deleted objects.
The elements in lists are anonymous structures of the following format:

```cs
new
{
    item.ID,
    Score = item.Score,
    BookTitle = item.Book.Title
}
```

After that, `updatedOld` and `deletedOld` lists can be used in the following concepts:
OldDataLoaded, OnSaveUpdate, OnSaveValidate and AfterSave.

The items in this lists are sorted to match items in `updatedNew` and `deletedIds`.

### OldDataLoaded

Use OldDataLoaded to **initialize or change the data**
before saving it to the database and before applying other business rules,
if the **previous data** state needs to be considered.
Available since Rhetos v2.12.

See *LoadOldItems* helper (above) for loading the old data values to be reused in multiple business rules.

Example task:

> Each time a reviewer changes the existing review score,
> append this information to the review text:
> "(changed from {old score} to {new score})"

Solution:

```c
Entity Review
{
    SaveMethod
    {
        LoadOldItems
        {
            Take Score;
        }

        OldDataLoaded AppendTextIfScoreChanged
            '
                var itemsWithModifiedScore = updatedOld
                    .Zip(updatedNew, (oldValue, newValue) => new { oldValue, newValue })
                    .Where(modified => modified.oldValue.Score == null && modified.newValue.Score != null
                        || modified.oldValue.Score != null && !modified.oldValue.Score.Equals(modified.newValue.Score))
                    .ToList();

                foreach (var item in itemsWithModifiedScore)
                    item.newValue.Text += string.Format(" (changed from {0} to {1})",
                        item.oldValue.Score,
                        item.newValue.Score);
            ';
    }
}
```

The OldDataLoaded code snippet usually uses `insertedNew`, `updatedNew` and `deletedIds`
parameters, along with updatedOld and deletedOld (from LoadOldItems),
to analyze and modify the data that will be saved.

### OnSaveUpdate

Use OnSaveUpdate to **modify the data in other dependent entities**
that need to be updated (recomputed) after the current Save operation.

The OnSaveUpdate code snippet is executed *after* the given records are
already saved to the database, but *before* the database transaction is committed.

In most cases, the [ComputedFrom](Persisting-the-computed-data) with KeepSynchronized concepts
should be used instead of this low-level code, since this is a standard pattern of updating the computed data.

Example task:

> Use the low-level concept "OnSaveUpdate" to update the number of reviews
> for each book.

Solution:

```c
Entity NumberOfReviews
{
    Extends Bookstore.Book;
    Integer Count;
}

Entity Review
{
    SaveMethod
    {
        OnSaveUpdate UpdateNumberOfReviews
            '
                var bookIds = insertedNew.Select(review => review.BookID.Value)
                    .Concat(updatedNew.Select(review => review.BookID.Value))
                    .Concat(deletedIds.Select(review => review.BookID.Value))
                    .Distinct().ToList();

                var numberOfReviews = _domRepository.Bookstore.Book.Query(bookIds)
                    .Select(book => new NumberOfReviews
                    {
                        ID = book.ID,
                        Count = _domRepository.Bookstore.Review.Subquery.Where(r => r.BookID == book.ID).Count()
                    })
                    .ToList();

                var oldRecordIds = _domRepository.Bookstore.NumberOfReviews.Query(bookIds).Select(n => n.ID).ToList();
                _domRepository.Bookstore.NumberOfReviews.Insert(numberOfReviews.Where(r => !oldRecordIds.Contains(r.ID)));
                _domRepository.Bookstore.NumberOfReviews.Update(numberOfReviews.Where(r => oldRecordIds.Contains(r.ID)));
            ';
    }
}
```

Note that this example is a just a demo for SaveMethod.
The **ComputedFrom** and **KeepSynchronized** concepts would be much better approach for this feature,
to avoid using low-level concepts.

### OnSaveValidate

Use OnSaveValidate to **verify the saved data**,
and decide if the Save operation should be completed or rejected.

The OnSaveValidate code snippet is executed *after* the given records are already saved to the database,
*after* dependent data is updated (recomputed), but *before* the database transaction is committed.
This means that the code snippet can use database objects such as views and stored procedures to read
and analyze the data, and other dependent computed data in the system, to decide
whether the new state is valid or not.

If the saved data is not valid, the code snippet should **throw an exception**,
which will result with automatic rollback of the database transaction.
Throw a `Rhetos.UserException` with a message to the end user, that can later be localized (translated).

Note:
Avoid using this low-level concept unless you are implementing a rare non-standard feature.
Use **InvalidData** concept instead, for standard data validations,
[Lock](Implementing-simple-business-rules#deny-data-modifications) and similar concepts to
keep the existing data from changing,
or [RowPermissions](RowPermissions-concept) for user access rights.

Example task:

> Use the low-level concept "OnSaveValidate" to deny modification of review score
> if the book title contains text "lock".

Solution:

```c
Entity Review
{
    SaveMethod
    {
        LoadOldItems
        {
            Take Score;
            Take 'Book.Title';
        }

        OnSaveValidate DenyChangeOfLockedTitle
            '
                var itemsWithModifiedScore = updatedOld
                    .Zip(updatedNew, (oldValue, newValue) => new { oldValue, newValue })
                    .Where(modified => modified.oldValue.Score == null && modified.newValue.Score != null
                        || modified.oldValue.Score != null && !modified.oldValue.Score.Equals(modified.newValue.Score))
                    .Where(modified => modified.oldValue.BookTitle.IndexOf("lock", StringComparison.InvariantCultureIgnoreCase) >= 0)
                    .FirstOrDefault();

                if (itemsWithModifiedScore != null)
                    throw new Rhetos.UserException(string.Format(
                        "It is not allowed to modify score ({0} => {1}) for the book \"{2}\" because to contains \"lock\" in the title.",
                        itemsWithModifiedScore.oldValue.Score,
                        itemsWithModifiedScore.newValue.Score,
                        itemsWithModifiedScore.oldValue.BookTitle));
            ';
    }
}
```

Note that this example is a just a demo for SaveMethod.
The [LockProperty](Implementing-simple-business-rules#deny-data-modifications) concept
would be much better approach for this feature.

### AfterSave

AfterSave is intended for features that could cause problems (performance issues, e.g.)
**if executed before data validations**.
Available since Rhetos v2.4.

The AfterSave code snippet is executed *after* the given records are already saved to the database,
*after* dependent data is updated (recomputed),
*after* the validations passes,
but *before* the database transaction is committed.

Since AfterSave is called after all the validations and related computations of this entity are executed,
there is a higher chance that the request will be successful and committed to the database.

Note that AfterSave is called **at the end of the Save method of the given entity**,
but not at the end of the web request (i.e. database transaction).

* For example, if saving one record (A) causes an automatic update of another record (B),
  then the AfterSave code of record B will be executed *before* the validations and AfterSave code of record A.
* Another example, if the Save method is called from an Action, it is still possible
  for the transaction to be discarded by the code executed in action after saving this entity.

For the reasons described above, AfterSave should not be used to send confirmation emails,
or similar external actions that cannot be undone if the current request is canceled
and the database transaction is rolled back.
That kind of features should always be implemented with a task queue and a separate process for
background processing of the committed tasks.

## Add features to repository class

### RepositoryUses

RepositoryUses adds **a member property** of a given type to the repository class,
and initializes it automatically from the **dependency injection** container.

This allows you to use different system components with dependency injection
in your C# code when implementing actions, filters, validations, SaveMethod code snippets,
and other features.

Some of the common system components are already available in `Common.ExecutionContext`
(UserInfo, AuthorizationManager, LogProvider, EntityFrameworkContext, ...).
RepositoryUses is often used to access custom classes that are
registered as plugins with dependency injection.

Example task:

> Write a filter that returns long reviews.
> The minimum length limit should be configurable in the application's configuration file.

Solution:

```c
Entity Review
{
    Reference Book { Required; }
    Integer Score { Required; MinValue 1; MaxValue 5; }
    LongString Text;

    RepositoryUses _configuration 'Rhetos.Utilities.IConfiguration, Rhetos.Utilities';

    ComposableFilterBy LongReviews '(query, repository, parameter) =>
        {
            int minLength = _configuration.GetInt("Bookstore.LongReviewsMinLength", 10).Value;
            return query.Where(r => r.Text.Length >= minLength);
        }';
}
```

In the example above, the RepositoryUses concept adds the `_configuration` member property,
to be used in the ComposableFilterBy.
It uses a default implementation of `IConfiguration` interface:
a Rhetos component that reads configuration from the "Web.config" file.

* RepositoryUses requires [AssemblyQualifiedName](https://docs.microsoft.com/en-us/dotnet/api/system.type.assemblyqualifiedname)
  of the property type, but it can sometimes be **shortened by omitting**
  Version, Culture and PublicKeyToken.
  In this example, `Rhetos.Utilities.IConfiguration` is the full class
  name or interface name (with the namespace), `Rhetos.Utilities` is the
  assembly name (this is usually the file name "Rhetos.Utilities.dll”
  without the ".dll" extension).
* Troubleshooting:
  You can test if a correct string is provided, by checking the result of
  [Type.GetType](https://docs.microsoft.com/en-us/dotnet/api/system.type.gettype?view=netframework-4.8#System_Type_GetType_System_String_)
  in a test application or a LINQPad script.
  It should return the expected type instead of *null*.
  For example:
    ```cs
    Type.GetType("Rhetos.Utilities.IConfiguration, Rhetos.Utilities")
    ```

### RepositoryMember

RepositoryUses is a low-level concept that allows you to add **an arbitrary code**
to the repository class body.
This can simplify code reuse between multiple filters, actions and other features.
Available since Rhetos v2.11.

In the following example, RepositoryMember adds a new helper method
`BetterReviews(int minScore)` to the repository.
The method is called from `FilterBy BestReviews` to read all reviews with score 4 or higher.

```c
Entity Review
{
    Reference Book { Required; }
    Integer Score { Required; MinValue 1; MaxValue 5; }
    LongString Text;

    RepositoryMember BetterReviews
        'public IQueryable<Common.Queryable.Bookstore_Review> BetterReviews(int minScore)
        {
            return this.Query().Where(r => r.Score >= minScore);
        }';

    FilterBy BestReviews '(repository, parameter) =>
        {
            return BetterReviews(4).ToSimple().ToArray();
        }';
}
```
