## Introduction

Welcome to Rhetos wiki!

Rhetos is a DSL framework that enables you to create your own *domain-specific programming language*.
After an application developer describes the application in that language (DSL script),
Rhetos will generate the application's source code, database model, web API and other components.

Rhetos extends the modern .NET technology stack with advanced programming paradigms:
declarative programming, metaprogramming and AOP.

* [What is Rhetos](What-is-Rhetos), an overview of the Rhetos architecture and principles
* [Roadmap](Rhetos-platform-roadmap)

Contributions are very welcome, both in learning resources (wiki articles and code samples)
or framework and plugins development.
See [How to Contribute](How-to-Contribute) for more information.

## Application development with Rhetos

Tutorials:

* [Creating a new application with Rhetos framework](Creating-a-new-application-with-Rhetos-framework)
* How to create a data model:
  * [Data model and relationships](Data-model-and-relationships)
  * [Basic property types](Data-structure-properties)
* Add simple features to your application:
  * [Implementing simple business rules](Implementing-simple-business-rules)
  * [Read-only data structures](Read-only-data-structures)
  * [Simple read-only entities and code tables (Hardcoded)](simple-read-only-entities-and-codetables)
* Develop new features:
  * [Using the Domain Object Model](Using-the-Domain-Object-Model)
  * [Filters and other read methods](Filters-and-other-read-methods)
  * [Data validations](Data-validations)
  * Implement new server commands: [Action concept](Action-concept)
  * Extend Rhetos DSL with you own keywords: [Rhetos concept development](Rhetos-concept-development)
  * [Low-level database development](Database-objects)
  * [Low-level object model concepts](Low-level-object-model-concepts)
* Business processes:
  * [Persisting the computed data](Persisting-the-computed-data)
  * Implementing entity inheritance and common interfaces: [Polymorphic concept](Polymorphic-concept)
  * [Temporal data and change history](Temporal-data-and-change-history)
  * Row permissions business rules: [RowPermissions concept](RowPermissions-concept)

Sample application:

* [Bookstore](https://github.com/Rhetos/Bookstore)

Fundamentals:

* [Prerequisites](Prerequisites)
* [Rhetos DSL syntax](Rhetos-DSL-syntax)
* [List of DSL concepts in CommonConcepts package](List-of-DSL-concepts-in-CommonConcepts)
* [Rhetos CLI](Rhetos-CLI)
* [Configuration management](Configuration-management)
* [Creating a Rhetos package](Creating-a-Rhetos-package)
* [Rhetos RESTful web API plugin](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md), [Set up HTTPS](Setting-up-Rhetos-for-HTTPS)
* [User authentication and authorization](User-authentication-and-authorization)
* [Data migration](Data-migration)
* [Logging](Logging)
* [Debugging](Debugging)
* [Unit of work and database transactions](Unit-of-work)
* [Rhetos coding standard](Rhetos-coding-standard)

Support:

* Feel free to **ask questions** on the [Issues](https://github.com/Rhetos/Rhetos/issues) page by searching the existing ones or adding a new issue.
* [Release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md) -
  new features and breaking changes.
* [How to upgrade your application to a new version of Rhetos](Upgrade-Rhetos-version)

## Recommended plugin packages

* [CommonConcepts](https://github.com/Rhetos/Rhetos/tree/master/CommonConcepts) contains standard concepts for building applications, such as entities, validations and computations.
* [RestGenerator](https://github.com/Rhetos/RestGenerator) automatically generates RESTful JSON web API for all entities and other readable or writable data structures that are defined in a Rhetos application. Additionally allows executing actions and downloading reports.
* [FloydExtensions](https://github.com/Rhetos/FloydExtensions), generates TypeScript model interfaces from DSL model and provides the structure metadata.
* [LogArchive](https://github.com/Rhetos/LogArchive), provides simple archive storage for the Common.Log table to improve the application's performance.
  The archive is integrated into existing auditing features, and automatically available to the log readers.
* [ActiveDirectorySync](https://github.com/Rhetos/ActiveDirectorySync). For applications that use Windows authentication, this package synchronizes Rhetos user roles with Active Directory, allowing user permissions to be defined by configuring AD user groups.
* [AfterDeploy](https://github.com/Rhetos/AfterDeploy), simplifies the handling of SQL scripts that need to be executed on each deployment.
* [LightDMS](https://github.com/Rhetos/LightDMS),  light document versioning system plugin for Rhetos. Supports database table storage, SQL Server filestream and Azure Blob Storage.
* [ODataGenerator](https://github.com/Rhetos/ODataGenerator) generates OData interface (Open Data Protocol) for all entities and other queryable data structures that are defined in a Rhetos application.
* [MvcModelGenerator](https://github.com/Rhetos/MvcModelGenerator) generates ASP.NET MVC model for all entities and other queryable data structures, for use in other web applications when accessing the Rhetos application.
* [Jobs](https://github.com/Rhetos/Jobs), provides an implementation of asynchronous execution of background jobs.
  It contains two packages: Rhetos.Jobs.Abstractions, that provides interfaces for asynchronous operations,
  and Rhetos.Jobs.Hangfire, an implementation option using Hangfire library.
* [Events](https://github.com/Rhetos/HttpNotifications), provides an infrastructure for decoupling
  a feature that emits an event (save operation, for example) and a feature that processes it (a business rule or a notification).
  The event handlers are executed synchronously, but they may generate asynchronous tasks
  or background jobs if needed, depending on the implementation.
* [HttpNotifications](https://github.com/Rhetos/HttpNotifications), sends HTTP POST notifications to subscriber URL for any configurable event.

Plugin packages for older versions of Rhetos or backward compatibility support:

* [AspNetFormsAuth](https://github.com/Rhetos/AspNetFormsAuth), provides Forms Authentication to Rhetos apps.
  Since Rhetos v5, authentication is managed by ASP.NET Core, so Rhetos does not need to handle user authentication.
* [I18NFormatter](https://github.com/Rhetos/I18NFormatter), enables localization of Rhetos apps
  using [GetText / PO](http://en.wikipedia.org/wiki/Gettext) standard.
  Since Rhetos v5, it is recommended to let ASP.NET Core manage the localization instead,
  see [an example](https://github.com/Rhetos/Rhetos.Samples.AspNet/#adding-localization) with OrchardCore localization library.
* [LegacyRestGenerator](https://github.com/Rhetos/LegacyRestGenerator), an old version of REST API, available for backward compatibility.

See also [Installing plugin packages](Installing-plugin-packages).

## Framework development

* [How to Contribute](How-to-Contribute)
* [Release management](Release-management)
