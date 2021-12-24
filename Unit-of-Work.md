# Unit of work and database transactions

Unit of work represents one or more operations grouped together so that they are
either all executed successfully, or all canceled.

A **unit of work** in Rhetos applications represents one **database transaction**,
and its lifetime matches one **scope** from dependency injection container.

1. [Web applications](#web-applications)
2. [Unit tests, LINQPad scripts and playground apps](#unit-tests-linqpad-scripts-and-playground-apps)
3. [Manual control over unit of work](#manual-control-over-unit-of-work)
4. [Cancelling unit of work without closing it](#cancelling-unit-of-work-without-closing-it)

## Web applications

In a typical Rhetos web application, **each web request** is executed in a single separate unit of work.
This meaning that all operations that are taking place within a single web request
are executed atomically: either all changes are committed to the database, or all is rolled back.

When developing a **custom controller**, you should manually commit the unit of work
by using `IRhetosComponent<IUnitOfWork>`, and calling its method `CommitAndClose()`
at the end of a web method, if completed successfully.

The same effect can be achieved by adding `ApiCommitOnSuccessFilter` filter attribute on the controller;
the filter class is available in `Rhetos.RestGenerator` package.

## Unit tests, LINQPad scripts and playground apps

One unit of work matches one scope from dependency injection container.

Rhetos unit tests and LINQPad scripts already create the **scope** to access Rhetos components
and execute various operations, see `using (var scope = ...` in existing code.
All components resolved from that scope will use the same unit of work, i.e. the same database transaction.
The transaction will be committed (`scope.CommitAndClose()`) or rolled back (by default)
when the scope is disposed at the end of the using block.

## Manual control over unit of work

In some cases, it may be required to manually create a unit of work, unrelated to the current web request.

Example scenarios:

* Running a batch of operations that is not atomic. If some operations fail, other operations should
  be completed and the report returned to the client with a list of failed operations.
* Running a simulated operation and retuning its result to the client, but not committing the results to the database.

Rhetos v5:

```cs
// Resolve `Rhetos.IUnitOfWorkFactory unitOfWorkFactory` from dependency injection (usually as a constructor parameter).
// The `scope` here represents the new unit of work.

using (var scope = unitOfWorkFactory.CreateScope())
{
    var repository = scope.Resolve<Common.DomRepository>();

    // Execute some operations withing the unit of work, for example enter a log record to the database.
    repository.Common.AddToLog.Execute(new Common.AddToLog { Action = LogActionName, TableName = "", ItemId = id2 });

    // Commit the unit of work transaction, otherwise it will be rolled back by default.
    scope.CommitAndClose();
}
```

Rhetos v4:

```cs
// This example depends on global Autofac DI container that is registered in Global.asax.cs in a Rhetos web app.
// The `scope` here represents the new unit of work.

var container = (Autofac.IContainer)Autofac.Integration.Wcf.AutofacServiceHostFactory.Container;
using (var scope = new Rhetos.TransactionScopeContainer(container))
{
    var repository = scope.Resolve<Common.DomRepository>();

    // Execute some operations withing the unit of work, for example enter a log record to the database.
    repository.Common.AddToLog.Execute(new Common.AddToLog { Action = LogActionName, TableName = "", ItemId = id2 });

    // Commit the unit of work transaction, otherwise it will be rolled back by default.
    scope.CommitChanges();
}
```

## Cancelling unit of work without closing it

In some rare scenarios, it can be useful to mark the unit of work for cancellation,
without closing it immediately.
This can be achieved with `IPersistenceTransaction` by calling its method `DiscardOnDispose()`.
The transaction will be rolled back when the web request ends.

Note that this approach could make the application's behavior more difficult to understand.
Instead, it is recommended to manually create and control a new unit of work,
see [Manual control over unit of work](#manual-control-over-unit-of-work) above.
