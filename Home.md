## Introduction

Welcome to Rhetos wiki!

Rhetos is a DSL framework that enables you to create your own *domain-specific language* to build server applications.
After an application developer describes the application in that language (DSL script), Rhetos will
use it to generate the application server, including the application's database,
business layer object model (C#) and web API (REST, SOAP, OData, etc.).

* [What is Rhetos](What-is-Rhetos), an overview of the Rhetos architecture and principles
* [Roadmap](Rhetos-platform-roadmap)

Contributions are very welcome, both in learning resources (wiki articles and code samples) or framework and plugins development. See [How to Contribute](How-to-Contribute) for more information.

## Application development with Rhetos

Tutorials:

* [Create your first Rhetos application](Create-your-first-Rhetos-application)
* How to create a data model:
  * [Data model and relationships](Data-model-and-relationships)
  * [Basic property types](Data-structure-properties)
* Add simple features to your application:
  * [Implementing simple business rules](Implementing-simple-business-rules)
  * [Read-only data structures](Read-only-data-structures)
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
* [Development environment setup](Development-Environment-Setup)
* [Rhetos DSL syntax](Rhetos-DSL-syntax)
* [List of DSL concepts in CommonConcepts package](List-of-DSL-concepts-in-CommonConcepts)
* [Creating Rhetos package](Creating-Rhetos-package)
* [Rhetos RESTful web API plugin](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md), [Set up HTTPS](Setting-up-Rhetos-for-HTTPS)
* [User authentication and authorization](User-authentication-and-authorization)
* [Data migration](Data-migration)
* [Logging](Logging)
* [Debugging](Debugging)
* [TemplaterReport](TemplaterReport)
* [Rhetos coding standard](Rhetos-coding-standard)

Support:

* Feel free to **ask questions** on the [Issues](https://github.com/Rhetos/Rhetos/issues) page by searching the existing ones or adding a new issue.
* [Release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md) -
  new features and breaking changes.

## Recommended plugins

* [CommonConcepts](https://github.com/Rhetos/Rhetos/tree/master/CommonConcepts) contains standard concepts for building applications, such as entities, validations and computations.
* [ActiveDirectorySync](https://github.com/Rhetos/ActiveDirectorySync). Rhetos supports Windows Authentication by default. This package synchronizes Rhetos user roles with Active Directory, allowing user permissions to be defined by AD user groups.
* [AspNetFormsAuth](https://github.com/Rhetos/AspNetFormsAuth), provides Forms Authentication to Rhetos applications.
* [RestGenerator](https://github.com/Rhetos/RestGenerator) automatically generates RESTful JSON web API for all entities and other readable or writable data structures that are defined in a Rhetos application. Additionally allows executing actions and downloading reports.
* [AfterDeploy](https://github.com/Rhetos/AfterDeploy), simplifies the handling of SQL scripts that need to be executed on each deployment.
* [LightDMS](https://github.com/Rhetos/LightDMS),  light document versioning system plugin for Rhetos. Supports database table storage, SQL Server filestream and Azure Blob Storage.
* [ODataGenerator](https://github.com/Rhetos/ODataGenerator) generates OData interface (Open Data Protocol) for all entities and other queryable data structures that are defined in a Rhetos application.
* [I18NFormatter](https://github.com/Rhetos/I18NFormatter), enables localization of Rhetos applications using [GetText / PO](http://en.wikipedia.org/wiki/Gettext) standard.
* [LegacyRestGenerator](https://github.com/Rhetos/LegacyRestGenerator), an old version of REST API, available for backward compatibility.
* [MvcModelGenerator](https://github.com/Rhetos/MvcModelGenerator) generates ASP.NET MVC model for all entities and other queryable data structures, for use in other web applications when accessing the Rhetos server.

See also [Installing plugin packages](Installing-plugin-packages).

## Framework development

* [How to Contribute](How-to-Contribute)
* [Release management](Release-management)
