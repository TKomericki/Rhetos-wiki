Rhetos is a DSL platform for Enterprise Application Development.

* It enables developers to create a **Domain-Specific Programming Language** and use it to write their applications.
* There are libraries available with ready-to-use implementations of many standard business and design patterns or technology integrations.

Rhetos works as a compiler that **generates the business application** from the source written in the DSL scripts.

* The generated application is a standard business applications based on Microsoft .NET technology stack.
* It is focused on the back-end development: It generates the business logic layer (C# object model), the database and the web API (such as REST, SOAP and OData).
* The database is not generated from scratch on each deployment, it is upgraded instead, carefully protecting the existing data.
* Rhetos application generator could be used for application scaffolding, but its real strength is utilized when using DSL scripts as the *source* and never manually modifying the generated code.

![Rhetos 4tier](images/Rhetos-4tier.png)

Rhetos comes with the *CommonConcepts* DSL package, a programming language extension that contains many ready-to-use features for building applications.

[Syntax highlighting](Prerequisites#Configure-your-text-editor-for-DSL-scripts-rhe) is available for Visual Studio Code, SublimeText3 and Notepad++.

## Why was Rhetos created

Enterprise business applications can be hard to develop and maintain because they typically contain a very large number of features that work together.

1. Rhetos allows fast development of standard business patterns in the application, by simply **declaring the features**.
2. Rhetos framework puts emphasis on principles that increase maintainability of the complex applications.

The basic principles:

* **Standardization** of business and technology patterns implementation
  * Write high-quality implementations of standard patterns and reuse them.
* **Declarative programming** helps reduce the difference between the requirements and the code, and separate business logic from technology details.
  * Try to develop most of the application's business logic by simply declaring the features.
  * Reduce the amount of the imperative code in order to decrease code coupling and increase long-term maintainability.
  * Developers are encouraged to recognize business and technology patterns, and create DSL concepts to simplify the use of those patterns in the business application development.
>   Rhetos DSL concepts are able to encapsulate a much larger scope of patterns than just writing a reusable class or a function. The implemented pattern can affect any part of the system, from the database structure to the web API, extend other existing features or implement the crosscutting concerns.
* **Code decoupling and Extensibility**
  * Each feature is implemented as a DSL concept with minimal number of dependencies.
  * Additional features are added as an extension from outside, not increasing complexity of the existing features' implementation.

## What does the Rhetos platform contain

1. Programming language development tools:
    * A framework for developing DSL concepts (as plugins) and code generators.
2. Ready-to-use DSL libraries:
    * Implementations of standard business and design patterns
    * Web API generators (such as REST, SOAP and OData)
    * Authentication plugins
    * Reporting
    * Internationalization
    * and others
3. Application development & deployment process:
    * Setup the Rhetos server
    * Use existing libraries with DSL concepts and technology-specific solutions (NuGet packages)
    * Develop your application: Write DSL scripts, custom DSL concept (generate new NuGet packages)
    * Deploy all the packages to the Rhetos server to generate the application's business layer, database, web service and other features.

## Rhetos DSL

![DSL example](images/dsl-example.png)

Rhetos DSL (a programming language) is a set of **concepts** - the **keywords** in the DSL scripts.

* Each concept represents a business pattern or a software design pattern, for example Entity, InvalidData, Logging, RowPermissions, etc.
* Each concept has code generators that generate the application code, database structure, other concepts, web API and other.
* Existing libraries include many standard concepts, but the application developers can easily add new concepts to extend the programming language.

Developers write the business application's code in the DSL scripts:

* A DSL script can be understood as a set of **statements**: Each statement declares **a feature** of the application.
* Statements are instances of the concepts, starting with a concept keyword followed by parameter values.
* DSL scripts often include SQL and C# code snippets, or call external DLLs.

Rhetos works as a compiler to generate the final application from the DSL scripts.

* Rhetos generates the human-readable C# code for the server application, and compiles it to create the web application.
* The generated application uses Entity Framework to access the generated database.
* There are plugins available for generating different types of web services, helper classes for client development and similar.

Database upgrade:

* The database is not generated from scratch on each deployment, it is upgraded instead.
* Rhetos protects all the data if the database structure is changed when deploying a new version of the business application.
* Data-migration SQL scripts can be used to migrate the data when needed.
