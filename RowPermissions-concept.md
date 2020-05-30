Row permissions are intended for implementing business requirements that can be formed in rules of the following format:

> Some employees are allowed to access (read or write) some subset of the entity's records.

* Note that row permissions are **not intended** for limiting access to specific **actions**, or **filtering** out some records in one part of the application while allowing the user to access the same records in another part of the application.
* For a simpler model of user permissions, see [Basic-permissions](Basic-permissions).

Row permissions are based on filters that are applied when reading and writing entity's records:

* The user will be **denied read or write command** if the involved records do not pass the given row permissions filter.
* A client may **explicitly apply** the row permissions filter (`Common.RowPermissionsReadItems`) when reading data from the Rhetos server, in order to avoid any access-denied errors.
* Row permissions are **ignored** inside a server-side functions (inside an **Action** or a **FilterBy**, e.g.). To explicitly verify user's permissions in a sever action, see "Manually verifying row permissions" below.

Contents:

1. [Simple row permission rules](#simple-row-permission-rules)
2. [Combining multiple rules](#combining-multiple-rules)
3. [Inheriting row permissions](#inheriting-row-permissions)
   1. [Solution 1](#solution-1)
   2. [Solution 2](#solution-2)
   3. [Optimizing inherited row permissions](#optimizing-inherited-row-permissions)
4. [Client code - Reading data with row permissions](#client-code---reading-data-with-row-permissions)
   1. [Reading all documents (access denied)](#reading-all-documents-access-denied)
   2. [Reading the user's documents](#reading-the-users-documents)
5. [Server code - Manually verifying row permissions](#server-code---manually-verifying-row-permissions)
6. [See also](#see-also)

## Simple row permission rules

Example requirements:

* Each *employee* belongs to a *division*.
* An employee may read and write (insert/update/delete) the *documents* from his division.

Solution:

```C
Module DemoRowPermissions1
{
    Entity Division
    {
        ShortString Name;
    }

    Entity Employee
    {
        ShortString UserName;
        Reference Division;
    }

    Entity Document
    {
        ShortString Title;
        DateTime Created { CreationTime; }
        Reference Division;

        RowPermissions
        {
            Allow WithinDivision 'context =>
                {
                    Guid myDivisionId = context.Repository.DemoRowPermissions1.Employee.Query()
                        .Where(e => e.UserName == context.UserInfo.UserName)
                        .Select(e => e.Division.ID)
                        .SingleOrDefault();
                    return item => item.Division.ID == myDivisionId;
                }';
        }
    }
}
```

*This solution is implemented in Rhetos unit tests, see `RowPermissionsDemo.rhe` and `RowPermissionsDemo.cs` in the Rhetos source repository.*

`RowPermissions` is the root concept for row permission rules on a data structure.
It allows combining multiple rules and inheriting rules from one data structure to another.

`Allow` (both read and write), `Deny` (both read and write), `AllowRead`, `DenyRead`, `AllowWrite` and `DenyWrite` concepts inside `RowPermissions` represent the rules that allow or deny current user access to selected records.

Each rule has the following parameters:

1. **Rule name**
2. **Filter expression function**
    * This is a function that returns the filter expression: the resulting expression for each record (`item`) returns whether the rule applies to the record or not.
    * The function typically first collects the data that will be used to filter the records, such as a list of business permission that are applied to the current user.
    * The parameter `context` can be used to retrieve the current user's name (`context.UserInfo.UserName`) or access data repositories (`context.Repository.SomeModule.SomeEntity.Query()`, replacing SomeModule and SomeEntity with the actual names).
    * The resulting expression will be translated to an SQL query (WHERE part), therefore it should be made as simple as possible, in order to allow efficient ORM translation.
    * This function is formatted as a lambda expression of type: `Func<Common.ExecutionContext, Expression<Func<TEntity, bool>>>`.

## Combining multiple rules

Example requirements:

* Each *employee* belongs to a *division*.
* An employee may read and write (insert/update/delete) the *documents* from his division.
* Each division belongs to a *region*.
* An employee may be a *region supervisor*. A region supervisor may read (but not write) all the documents from all the divisions inside that region.
* The documents from *previous years* are read-only.

Solution:

```C
Module DemoRowPermissions2
{
    Entity Region
    {
        ShortString Name;
    }

    Entity Division
    {
        ShortString Name;
        Reference Region;
    }

    Entity Employee
    {
        ShortString UserName;
        Reference Division;
    }

    Entity RegionSupervisor
    {
        Reference Employee;
        Reference Region;
    }

    Entity Document
    {
        ShortString Title;
        DateTime Created { CreationTime; }
        Reference Division;

        RowPermissions
        {
            Allow WithinDivision 'context =>
                {
                    Guid myDivisionId = context.Repository.DemoRowPermissions2.Employee.Query()
                        .Where(e => e.UserName == context.UserInfo.UserName)
                        .Select(e => e.Division.ID)
                        .SingleOrDefault();
                    return item => item.Division.ID == myDivisionId;
                }';

            AllowRead SupervisedRegions 'context =>
                {
                    List<Guid> myRegionIds = context.Repository
                        .DemoRowPermissions2.RegionSupervisor.Query()
                        .Where(rs => rs.Employee.UserName == context.UserInfo.UserName)
                        .Select(rs => rs.Region.ID)
                        .ToList();

                    if (myRegionIds.Count == 0)
                        return item => false; // Minor optimization.

                    return item => myRegionIds.Contains(item.Division.Region.ID);
                }';

            DenyWrite PreviousYears 'context =>
                {
                    return item => item.Created < new DateTime(DateTime.Today.Year, 1, 1);
                }';
        }
    }
}
```

*This solution is implemented in Rhetos unit tests, see `RowPermissionsDemo.rhe` and `RowPermissionsDemo.cs` in the Rhetos source repository.*

The rules are combined into a single filter (check the generated SQL query in the SQL Profiler), based on the following principles:

* When the `RowPermissions` concept is added to an entity, everything is denied by default.
* Multiple `Allow*` rules are combined as a union of allowed data.
* `Deny*` rules have priority over `Allow*` rules.

Note that the `SupervisedRegions` rule implements an additional **optimization** that will simplify the final row permissions filter. The following filter expressions will be optimized when checking the row permissions:

* If the resulting filter expression is `item => false` (no items selected), the rule will be ignore when generating the final SQL query.
* Similarly, if an `Allow*` rule returns filter expression `item => true` (all items are selected), the other `Allow*` rules will be ignored, and the final SQL query will not contain any rule-specific filtering.

## Inheriting row permissions

Example requirements:

* Row permissions for a `Document` should also be applied (*inherited*) to all of the document's **extensions**, including the **Browse** data structures, and to all of the document's **detail** entities.
* In addition to the inherited row permissions, a `DocumentApproval` record should be read-only for everyone except the employee that approved it.

### Solution 1

Add this script to the previous example's solution.

```C
Module DemoRowPermissions2
{
    AutoInheritRowPermissions;

    Browse DocumentBrowse DemoRowPermissions2.Document
    {
        Take 'Title';
        Take 'Division.Name';
    }

    Entity DocumentComment
    {
        Reference Document { Detail; }
        ShortString Comment;
    }

    Entity DocumentApproval
    {
        Extends DemoRowPermissions2.Document;
        Reference ApprovedBy DemoRowPermissions2.Employee;
        ShortString Note;

        RowPermissions
        {
            // This rule is joined with the inherited rules from DemoRowPermissions2.Document.
            DenyWrite ApprovedByCurrentUser 'context =>
                {
                    var myEmployeeId = context.Repository.DemoRowPermissions2.Employee.Query()
                        .Where(e => e.UserName == context.UserInfo.UserName)
                        .Select(e => e.ID)
                        .SingleOrDefault();
                    return item => item.ApprovedBy.ID != myEmployeeId;
                }';
        }
    }
}
```

*This solution is implemented in Rhetos unit tests, see `RowPermissionsDemo.rhe` and `RowPermissionsDemo.cs` in the Rhetos source repository.*

By using `AutoInheritRowPermissions`, the row permissions from `Document` entity are copied to the following related entities:

* extensions of the entity (`DocumentApproval`, see **Extends**).
* browse data structures (`DocumentBrowse`, **Browse** is also an extension).
* details of the entity (`DocumentComment`, see **Detail** reference).

### Solution 2

Instead of using `AutoInheritRowPermissions` (see the previous solution), row permissions inheritance may be explicitly set for selected entities.

```C
Module DemoRowPermissions2
{
    // NOT USING AutoInheritRowPermissions;

    Browse DocumentBrowse DemoRowPermissions2.Document
    {
        Take 'Title';
        Take 'Division.Name';

        RowPermissions { InheritFromBase; }
    }

    Entity DocumentComment
    {
        Reference Document { Detail; }
        ShortString Comment;

        RowPermissions { InheritFrom DemoRowPermissions2.DocumentComment.Document; }
    }

    Entity DocumentApproval
    {
        Extends DemoRowPermissions2.Document;
        Reference ApprovedBy DemoRowPermissions2.Employee;
        ShortString Note;

        RowPermissions
        {
            InheritFromBase;

            // This rule is joined with the inherited rules from DemoRowPermissions2.Document.
            DenyWrite ApprovedByCurrentUser 'context =>
                {
                    var myEmployeeId = context.Repository.DemoRowPermissions2.Employee.Query()
                        .Where(e => e.UserName == context.UserInfo.UserName)
                        .Select(e => e.ID)
                        .SingleOrDefault();
                    return item => item.ApprovedBy.ID != myEmployeeId;
                }';
        }
    }
}
```

* **InheritFromBase** can be used on a **Browse** data structures and on entities with **Extends** concept.
* **InheritFrom** concept's parameter is the full name of `DocumentComment` entity's
  reference property (`Reference Document`) that references the "parent" entity with row permissions that will be inherited.

### Optimizing inherited row permissions

Consider the following example:
`DocumentInfo` is an extension of the `Document` entity,
and inherits the row permissions from the `Document`.

```C
SqlQueryable DocumentInfo
    "SELECT
        ID,
        Title2 = Title + '_2',
        Division2ID = DivisionID
    FROM
        DemoRowPermissions2.Document"
{
    Extends DemoRowPermissions2.Document;
    ShortString Title2;
    Reference Division2 DemoRowPermissions2.Division
    {
        SamePropertyValue 'Base.Division';

        // Old syntax, before Rhetos v2.11:
        // SamePropertyValue 'Base' DemoRowPermissions2.Document.Division;
    }

    RowPermissions { InheritFromBase; }

    AutodetectSqlDependencies;
}
```

When querying the `DocumentInfo` with row permissions, the generated SQL query
should `JOIN` the `DocumentInfo` view to the `Document` table,
and use the `Document.DivisionID` column to check the row permissions as seen before.

Since `DocumentInfo` view contains the `Division2ID` column,
this column could be used directly and there is no need to join the `Document` table.
This optimization can be achieved in Rhetos by using the **SamePropertyValue** concept;
it will inform the engine that the inherited property can be used without
referencing the base entity in the SQL query.

While this concept is useful on **SqlQueryable**, there is no use of putting **SamePropertyValue**
inside **Browse** since **Browse** does not generate SQL view that might be used instead of the base table.
Also note that this is a minor optimization in most cases,
and there is no need to use the **SamePropertyValue** concept unless there are performance issues.

## Client code - Reading data with row permissions

*The following examples use the test data from Rhetos unit tests.
To prepare the data, open the `CommonConceptsTest.sln` solution in the Rhetos source
and run the tests in the `RowPermissionsDemo` class.*

### Reading all documents (access denied)

Use REST API to read all documents, including those that a current user should no access:

    http://localhost/Rhetos/rest/DemoRowPermissions1/Document/

Sever response should contain an error:

    "UserMessage": "Insufficient permissions to access some or all of the data requested."

### Reading the user's documents

Add the `Common.RowPermissionsReadItems` filter to read only documents that a user is allowed to read:

    http://localhost/Rhetos/rest/DemoRowPermissions1/Document/?filters=[{"Filter":"Common.RowPermissionsReadItems"}]

This web request will return only the records that the current user has permission to read;
it will never fail with "Insufficient permissions" error.

Note that if multiple filters are given, the RowPermissionsReadItems filter should
be listed last for performance reasons. If the filter is applied last,
it will guarantee that the returned records all pass the filter,
and the server will skip the permissions verification of the returned records.

## Server code - Manually verifying row permissions

Row permissions are automatically checked for client's read and write requests.
Row permissions are ignored inside a server-side functions that use the repository classes directly
to read and write data (for example, inside an **Action** or a report).
To explicitly verify the current user's permissions inside the server code,
use one of the following methods:

1. Use `IProcessingEngine` to execute server commands to read/write data.
   The processing engine will check the current user's permissions, including row permission.
2. Directly use row permissions filters (`Common.RowPermissionsReadItems` and `Common.RowPermissionsWriteItems`)
   on an entity with row permissions, to verify the data before writing it to the database or sending it to the user.

## See also

* [User authentication and authorization](User-authentication-and-authorization)
