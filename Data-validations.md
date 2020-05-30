# Data validations

This article explains **how to write data validations** when developing a Rhetos application.

The basic principle is to implement the validations as separate stand-alone business rules.
The validation can be executed when saving new data (returning an error response),
but also we should be able to *efficiently* execute it on
the existing database to reevaluate the current state of the previously entered data.

Prerequisites:

* [Filters and other read methods](Filters-and-other-read-methods)

Contents:

1. [Property value constraints](#property-value-constraints)
2. [InvalidData concept](#invaliddata-concept)
3. [Understanding data validations in Rhetos](#understanding-data-validations-in-rhetos)
   1. [The principles behind InvalidData](#the-principles-behind-invaliddata)
   2. [What is and what is not a data validation](#what-is-and-what-is-not-a-data-validation)
4. [Additional validation examples](#additional-validation-examples)
   1. [Validation with subquery](#validation-with-subquery)
   2. [Validation with multiple statements](#validation-with-multiple-statements)
5. [Error response and metadata](#error-response-and-metadata)
   1. [MarkProperty and ErrorMetadata concepts](#markproperty-and-errormetadata-concepts)
   2. [MessageParametersItem concept](#messageparametersitem-concept)
   3. [MessageParametersConstant concept](#messageparametersconstant-concept)
   4. [MessageFunction concept](#messagefunction-concept)

## Property value constraints

The *simplest* data validations (for example a maximum allowed value or a regular expression pattern match)
can be just declared in the DSL script directly on the property.

See the available concepts and examples in section
[Property value constraints](Implementing-simple-business-rules#property-value-constraints):
Required, Unique, MaxValue, MaxLength, RegExMatch, etc.

## InvalidData concept

To implement a **data validation** on an entity,
when simple property constraints are not enough,
you need to:

1. Create a [filter](Filters-and-other-read-methods) on the entity that returns the invalid records.
2. Create a validation rule for that filter (InvalidData), with the message for the user.
   The validation will return the error message if the user tries to enter the invalid data.

Example task:

> The following entities describe books and a business event of disposing a damaged book
> that can no longer be sold. Add the following validations for book disposal:
>
> 1. When disposing a book which title contains "important",
>    the explanation should be at least 50 character long.
> 2. A book with rating above 100 should never be disposed.

```c
Module Bookstore
{
    Entity Book
    {
        ShortString Code { AutoCode; }
        ShortString Title { Required; }
    }

    Entity Disposal
    {
        Reference Book { Required; }
        LongString Explanation { Required; }
        DateTime EffectiveSince { CreationTime; }
    }

    Entity BookRating
    {
        Extends Bookstore.Book;
        Decimal Rating; // ComputedFrom Bookstore.ComputeBookRating
    }
}
```

Solution:

```c
Entity Disposal
{
    Reference Book { Required; }
    LongString Explanation { Required; }
    DateTime EffectiveSince { CreationTime; }

    ItemFilter ImportantBookExplanation 'item => item.Book.Title.Contains("important") && item.Explanation.Length < 50';
    InvalidData ImportantBookExplanation 'When disposing an important book, the explanation should be at least 50 characters long.';

    ItemFilter HighRating 'item => item.Book.Extension_BookRating.Rating > 100';
    InvalidData HighRating 'You are not allowed to dispose a book with rating above 100.';
}
```

Note that you can use navigation properties in the **ItemFilter** to read data
from the referenced objects and extensions.
See the examples in the following sections for using subqueries and more complex data analysis.

* The `item` refers to a records of the Disposal entity, but this code is not executed for each instance separately.
  Instead it is part of the EF LINQ query, converted to SQL query, and can be executed on multiple records in a single query.
* Only queryable filters can be source for InvalidData: ItemFilter and ComposableFilterBy.
  See more in [Filters and other read methods](Filters-and-other-read-methods).

The **InvalidData concept** will generate additional code in the Save method of the Disposal entity:

* This code will check the records that are being inserted or updated:
  If any of the records passes the given filter,
  the code will throw a UserException with the given message for the end user,
  and the database transaction will be rolled back.
* Note that the validation is executed **after the data is saved to the database**,
  *after* any related computed data is updated,
  but *before* the transaction is committed.
  This allows us to use related objects and computed data to validate if the resulting state is correct.
  The validation filter may also use database views to analyze the data.

The example above is also available in [Bookstore](https://github.com/Rhetos/Bookstore) demo application.

## Understanding data validations in Rhetos

### The principles behind InvalidData

Some of the functional programming principles are applied to data validations in Rhetos,
by separating the two parts: a filter and a validation rule.
This separation is important to promote code decoupling:
Each validation is a separate object (feature) in the system.

* The filter can be used and tested as a stand-alone objects without the validation.
  For example it can be applied to read the exiting records from the database
  after creating a new validation.
* Separate validation objects reduce risk of future development issues when the application
  ends up with large methods that contain intermingled code for multiple different features.
* It is possible to use metaprogramming to extend your application and apply
  certain features to all or some validations.
  * For example, a developer can **enumerate all validations** in the system,
    execute their filters on the existing data in the database,
    collect all incorrect records and send it as a report once per day.
  * Validations could be extended with additional features such as
    suppressing validation when saving and executing it later on
    some approval process step.
* It is easy to integrate core system (application as a product)
  with **customer-specific plugins**,
  to allow any plugin to add new validations to existing core entities.

A validation is written as a filter on **set of records**, not on each instance separately.
This often means that it can be executed efficiently on a large number of items at once,
even on all existing data in the database.
This can be useful when maintaining an enterprise application, for example:

* Verifying the existing database after fixing a bug or adding new validations.
* Testing the data after initial migration from a previous system,
  for a new client implementation.

### What is and what is not a data validation

The term "data validations" in this article describes a business rule that checks
**whether a certain data is valid or not**.

The validation *should not depend* on the operation context, on the user's role and permissions
or the previous data values that were overwritten.
The validation should just analyze the new state of the data and decide if it is correct as it is.
There are alternative concepts available for other features that are **not
data validations** in this strict sense:

* See [Row permissions](RowPermissions-concept) and [Basic permissions](Basic-permissions),
  if the read or write operation depends on the user that executes it.
* See [Deny data modifications](Implementing-simple-business-rules#deny-data-modifications)
  section for *Lock*, *DenyUserEdit* and related concepts.
* If you need to implement a very specific business rule for which there is no
  standard concept available
  (for example to deny deleting certain records while allowing updates),
  it would be best to create [your own concept](Rhetos-concept-development)
  based on the implementation of a similar one.
  A more pragmatic option is to directly insert an arbitrary C# code into the entity's
  Save method with [Low-level object model concepts](Low-level-object-model-concepts).

## Additional validation examples

This section contains examples of more complex validation filters.

Any ItemFilter and ComposableFilterBy can be used for definition of invalid items with InvalidData.
See [Filters and other read methods](Filters-and-other-read-methods) for more info.

Hint: If a validation gets too complicated,
you can always implement the complex part in a separate computed object
(for example, SqlQueryable as an extension of some base entity),
and simply reference it in the ItemFilter.

### Validation with subquery

Example task:

> The disposal explanation should not contain uncertain word, such as "maybe".
> Add an entity that will contains a list of uncertain words,
> and deny entering explanations that contain those words.
>
> (see the Disposal entity in the previous example)

Solution:

```c
Entity Disposal
{
    ...

    ItemFilter UncertainExplanations 'disposal => _domRepository.Bookstore.UncertainWord.Subquery
        .Any(uncertain => disposal.Explanation.Contains(uncertain.Word))';
    InvalidData UncertainExplanations 'The explanation contains uncertain words.';
}
```

### Validation with multiple statements

Here is an implementation of the same example as above,
but using a ComposableFilterBy instead of the ItemFilter.
This allows multiple C# statements in the filter implementation.

```c
Entity Disposal
{
    ...

    ComposableFilterBy UncertainExplanations2 '(query, repository, parameter) =>
        {
            var uncertainWords = _domRepository.Bookstore.UncertainWord.Query().Select(uncertain => uncertain.Word);
            return query.Where(disposal => uncertainWords.Any(word => disposal.Explanation.Contains(word)));
        }';
    InvalidData UncertainExplanations2 'The explanation contains uncertain words. (v2)';
}

Parameter UncertainExplanations2;
```

ComposableFilterBy requires the corresponding Parameter in DSL script, but it should be empty
since the validation provides no parameters when executed.

## Error response and metadata

Test the validations from the previous sections by directly executing the save method
in the generated [object model](Using-the-Domain-Object-Model), or by saving with a REST request
(see [Test and review](Creating-new-WCF-Rhetos-application#test-and-review-the-application) section).

For example:

> Create a book in the database, with word "important" in the title.
> Execute POST web request to insert the disposal for this book:
> Use the ID of the inserted book, but don't enter the Explanation property.

Execute the following web requests (replace "BASE_URL"):

```text
POST: BASE_URL/rest/Bookstore/Book/
HEADER: Content-Type: application/json; charset=utf-8
BODY: { "ID":"712c2146-a6fc-4550-a8ec-ee15df2a4b85", "Title":"An important book" }
```

```text
POST: BASE_URL/rest/Bookstore/Disposal/
HEADER: Content-Type: application/json; charset=utf-8
BODY: { "BookID":"712c2146-a6fc-4550-a8ec-ee15df2a4b85" }
```

The first web request should return HTTP 200 OK, but the second response is HTTP 400 Bad Request:

```json
{
    "SystemMessage": "DataStructure:Bookstore.Disposal,ID:f0e94dcd-9d01-4bc0-8c7c-168805623a73,Property:Explanation",
    "UserMessage": "It is not allowed to enter Bookstore.Disposal because the required property Explanation is not set."
}
```

Note that the response contains **UserMessage**, a text that should be displayed to the end user,
and **SystemMessage** with error metadata.

* The error metadata is a key-value list that contains information about the error,
  primarily intended for better user experience in the client application.
* In the example above, the metadata contain key-value pair `Property:Explanation`.
  This information could be used by the client application to **display the error next to the
  field** that caused the error.

When testing this validation in the object model directly, the error will be returned as
a UserException with the same user message, but with separated message parameters.

```cs
repository.Bookstore.Disposal.Insert(
    new Bookstore.Disposal { BookID = new Guid("712c2146-a6fc-4550-a8ec-ee15df2a4b85") });
/*
Throws Rhetos.UserException:
Message = "It is not allowed to enter {0} because the required property {1} is not set."
MessageParameters = new[] { "Bookstore.Disposal", "Explanation" }
*/
```

* The error message (UserMessage) can be translated to different languages with a
  localization plugin. This is why the parameters are internally handled separately.
  By default, the REST response combines the parameters into a single text,
  but with a Rhetos plugin (like [I18NFormatter](https://github.com/Rhetos/I18NFormatter), e.g.)
  they can be localized, or kept separated in the REST response for some other localization utility.

### MarkProperty and ErrorMetadata concepts

In the example above, the error response for the **Required** property validation
returned the error metadata with information that the error was cause by the value
in property Explanation.

**InvalidData** validation does not know by default which property to report
to the client application in the error metadata.

* If the error is related to the single property, and you want to inform the client application,
  you can use **MarkProperty** to add that information to the validation.
* In a similar way, use **ErrorMetadata** concept to add any custom metadata information
  to the error response.
  This metadata may be used in frontend to display the error message in a certain way.

Continuing the examples from the previous sections (see `InvalidData ImportantBookExplanation`):

> Use the REST Web API to insert a new Disposal with a short explanation for the Book
> that has word "important" in the title.

Execute the following web requests (replace "BASE_URL"):

```text
POST: BASE_URL/rest/Bookstore/Disposal/
HEADER: Content-Type: application/json; charset=utf-8
BODY: { "BookID":"712c2146-a6fc-4550-a8ec-ee15df2a4b85", "Explanation":"damaged" }
```

The web response does not contain property information in the error metadata:

```json
{
    "SystemMessage":"DataStructure:Bookstore.Disposal,ID:943d3850-3596-4f42-a2a1-68023bca4502,Validation:ImportantBookExplanation",
    "UserMessage":"When disposing an important book, the explanation should be at least 50 characters long."
}
```

Task:

> For the existing validation `InvalidData ImportantBookExplanation`,
> add metadata information that the error is related to the property "Explanation",
> and a custom information that the error severity is low.

Solution:

```c
InvalidData ImportantBookExplanation 'When disposing an important book, the explanation should be at least 50 characters long.'
{
    MarkProperty Bookstore.Disposal.Explanation;
    ErrorMetadata 'Severity' 'Low';
}
```

Execute the POST request again.
The resulting web response is again HTTP 400 Bad Request,
but the `Severity` and `Property` metadata is visible.

```json
{
    "SystemMessage":"DataStructure:Bookstore.Disposal,ID:943d3850-3596-4f42-a2a1-68023bca4502,Validation:ImportantBookExplanation,Property:Explanation,Severity:Low",
    "UserMessage":"When disposing an important book, the explanation should be at least 50 characters long."
}
```

### MessageParametersItem concept

Task:

> The validation `ItemFilter UncertainExplanations`,
> in the example from a section above,
> has error message provided as a fixed string:
>
> ```c
> ItemFilter UncertainExplanations 'disposal => _domRepository.Bookstore.UncertainWord.Subquery
    > .Any(uncertain => disposal.Explanation.Contains(uncertain.Word))';
> InvalidData UncertainExplanations 'The explanation contains uncertain words.';
> ```
>
> Change the error message to show the *uncertain word* that caused the error,
> the book title, and the invalid Explanation trimmed to the first 10 characters.

Solution:

```c
ItemFilter UncertainExplanations 'disposal => _domRepository.Bookstore.UncertainWord.Subquery
    .Any(uncertain => disposal.Explanation.Contains(uncertain.Word))';
InvalidData UncertainExplanations 'The explanation "{0}{1}" should not contain word "{2}". Book: {3}.'
{
    MessageParametersItem 'item => new
        {
            item.ID,
            P0 = item.Explanation.Substring(0, 10),
            P1 = item.Explanation.Length > 10 ? "..." : "",
            P2 = _domRepository.Bookstore.UncertainWord.Subquery
                .Where(uncertain => item.Explanation.Contains(uncertain.Word))
                .Select(uncertain => uncertain.Word).FirstOrDefault(),
            P3 = item.Book.Title
        }';
}
```

For example, saving a new disposal with an Explanation "Maybe it was damaged",
with "maybe" in the UncertainWord list,
would result with an error message:
`The explanation "Maybe it w..." should not contain word "maybe". Book: Some book title.`

The **MessageParametersItem** concept extends the validation's error message with custom parameter values.
The values are implemented with a lambda expression:

* The lambda expression must follow the *convention* to return `item.ID`,
  and for each message argument `{x}` to return a corresponding property `{Px}`.
* The `item` represents the invalid record.
* MessageParametersItem can use navigation properties (to read references and extensions),
  and even `_domRepository` and `_executionContext` members.

### MessageParametersConstant concept

**MessageParametersConstant** has subset of the features of MessageParametersItem.
It works in a similar way, but it can only provide constant values.

It cannot be used to include custom data in the error message,
it's only purpose is to **simplify message translation** to different languages
by separating different parameters from the error message, thus allowing us
to translate only one message to different languages that can be reused on
multiple entities and validations with different parameters.

Example:

```c
ItemFilter ExplanationTooLong 'item => item.Explanation.Length > 500';
InvalidData ExplanationTooLong 'The {0} cannot be longer then {1} characters.'
{
    MessageParametersConstant '"Explanation", 500';
}
```

### MessageFunction concept

MessageParametersConstant allows **full control over validation's error message and metadata**.
It is implemented as a lambda expression the returns the error message and metadata
for a given list of invalid record IDs.

Example:

```c
ItemFilter ExplanationSpecialCharacters 'item => item.Explanation.Contains("#") || item.Explanation.Contains("$")';
InvalidData ExplanationSpecialCharacters 'The explanation should not contain special characters.'
{
    // Full control over validation's error message and metadata:
    MessageFunction 'ids => this.Query(ids)
        .Select(item => new { item.ID, BookTitle = item.Book.Title })
        .ToList()
        .Select(item => new InvalidDataMessage
        {
            ID = item.ID,
            Message = "The explanation for \"{0}\" contains character \"#\" or \"$\".",
            MessageParameters = new object[] { item.BookTitle },
            Metadata = metadata
        })';
}
```

* The `ids` parameter is the list of IDs from the invalid records that caused the error.
* For each ID, the lambda expression must return the `InvalidDataMessage` instance with
  the given ID, and the information about the error.
* The `Message` in MessageFunction will override the message text from the InvalidData statement above.
