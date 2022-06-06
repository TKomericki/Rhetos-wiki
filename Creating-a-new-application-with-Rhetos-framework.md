# Creating a new application with Rhetos framework

This tutorial shows how to add Rhetos to ASP.NET Web API application.

In this tutorial, we will create **a business service** for demo application called **"Bookstore"**,
test it, and later add some additional features in other tutorial articles.

* *Business service* is a web application that manages business features, data and security,
  and exposes the features through a web API.
  We will use automatically generated RESTful JSON API in this tutorial.
* This is a typical usage of Rhetos framework as a part of an N-tier
  enterprise system where the front-end is developed as a separate application
  (for example, an Angular web application).
  Note that Rhetos can be used in any type of .NET application,
  from simple libraries to ASP.NET Core web applications.

> OTHER VERSIONS OF RHETOS:
This article applies to **Rhetos v5** and later versions.
For older versions see a corresponding article for
[Rhetos v4](Creating-new-WCF-Rhetos-application),
[Rhetos v3](Create-your-first-Rhetos-application)
or [Migrating from DeployPackages to Rhetos.MSBuild with Rhetos CLI](Migrating-from-DeployPackages-to-Rhetos-CLI).

Contents:

1. [Prerequisites](#prerequisites)
2. [Introduction: Rhetos DSL programming language](#introduction-rhetos-dsl-programming-language)
3. [Create a web app and add Rhetos](#create-a-web-app-and-add-rhetos)
   1. [Build your first Rhetos App](#build-your-first-rhetos-app)
   2. [Connecting to ASP.NET pipeline](#connecting-to-aspnet-pipeline)
   3. [Connecting to a database](#connecting-to-a-database)
   4. [Applying Rhetos model to database](#applying-rhetos-model-to-database)
4. [Use Rhetos components in ASP.NET controllers](#use-rhetos-components-in-aspnet-controllers)
5. [Read next](#read-next)

## Prerequisites

1. Run `dotnet --version` in command prompt to check if you have **.NET 6 SDK** installed.
   It should output 6.x.x.
   If not, install the latest version of SDK from <https://dotnet.microsoft.com/download/dotnet/6.0>.

## Introduction: Rhetos DSL programming language

Rhetos enables usage of Rhetos DSL programming language in .NET applications.
We can combine Rhetos DSL source files with C# source files in a same application.

We will use the following DSL script as the source code of the *Bookstore* application in this tutorial:

```c
Module Bookstore
{
   Entity Book
   {
      ShortString Code { AutoCode; }
      ShortString Title;
      Integer NumberOfPages;

      ItemFilter CommonMisspelling 'book => book.Title.Contains("curiousity")';
      InvalidData CommonMisspelling 'It is not allowed to enter misspelled word "curiousity".';

      Logging;
   }
}
```

Before creating the application, let's review this source code first.

Rhetos DSL is a *declarative* programming language,
so the source code should be viewed as a **set of features** (statements)
that the application contains, instead of a **list of commands** that the computer will execute.

Each statement is starting with a *keyword* (Module, Entity, ShortString, AutoCode, ...)
and some *parameters* after the keyword. Statements can be nested in other statements.

* **Module** keyword represents a business module, and a namespace in C# code.
* **Entity** represents a business object (C# class) and a table in database that contains the object's data.
  The Book entity here contains some properties and some business features.
  These features are explained in later tutorial articles.
* See [Rhetos DSL syntax](Rhetos-DSL-syntax) article for better understanding of the DSL scripts.

## Create a web app and add Rhetos

1. For this tutorial, create the following folder structure with 3 subfolders.
   It will allow us to add new components and test projects later.

   ```text
   * Bookstore
       * src
           * Bookstore.Service
   ```

2. Open console in **Bookstore.Service** folder, and execute the following commands to create
   a new Web API application and add Rhetos:

   ```batch
   dotnet new webapi
   dotnet add package Rhetos.Host
   dotnet add package Rhetos.Host.AspNet
   dotnet add package Rhetos.CommonConcepts
   dotnet add package Rhetos.MSBuild
   dotnet add package Microsoft.Extensions.Configuration
   ```

3. Temporarily disable Rhetos database update, to simplify setup:

   * Open the Bookstore.Service.csproj file and inside `<PropertyGroup>` element add: `<RhetosDeploy>False</RhetosDeploy>`

### Build your first Rhetos App

1. Inside Bookstore.Service, add a subfolder `DslScripts` and inside it create a text file
   named `Books.rhe`.
   Edit the file to contain the DSL script from the [Introduction](#introduction-rhetos-dsl-programming-language)
   section above (`Module Bookstore ...`).

2. Run `dotnet build` in "Bookstore.Service" folder to verify that everything compiles.

   * On build, your DSL model from the .rhe script is compiled, and the generated Rhetos classes
     are now available in your project in `obj\Rhetos\Source` folder.
   * SQL code and others assets files are also generated.

### Connecting to ASP.NET pipeline

To wire up Rhetos and ASP.NET dependency injection, modify `Program.cs`,
add a following static method (this is a useful convention but it is not required):

```cs
using Rhetos;
```

```cs
void ConfigureRhetosHostBuilder(IServiceProvider serviceProvider, IRhetosHostBuilder rhetosHostBuilder)
{
    rhetosHostBuilder
        .ConfigureRhetosAppDefaults()
        .UseBuilderLogProviderFromHost(serviceProvider)
        .ConfigureConfiguration(cfg => cfg.MapNetCoreConfiguration(builder.Configuration));
}
```

And register Rhetos where other builder.Services are configured:

```cs
builder.Services.AddRhetosHost(ConfigureRhetosHostBuilder)
    .AddAspNetCoreIdentityUser()
    .AddHostLogging();
```

> NOTE:
New ASP.NET 6 applications use "minimal hosting model" by default (i.e. there is no Startup.cs).
If your application uses a classic Startup class instead,
adapt the code samples from this tutorial for your application
by reviewing differences in [Code samples](https://docs.microsoft.com/en-us/aspnet/core/migration/50-to-60-samples?view=aspnetcore-6.0)
from Microsoft.

### Connecting to a database

Each Rhetos application needs it's own database.

1. Create a new empty database, for example named "Bookstore":

   * Start "SQL Server Management Studio" and connect to the SQL Server that you will be using for development.

   * Create and new empty database that will be used for developing the Rhetos application.
     Note: Each developer must have his/her own database for each Rhetos application development,
     to avoid conflicts of deploying multiple Rhetos applications to the same database.

   * Open a new query window on the created database, and execute query: `print user_name()`.
     The query should output `dbo`, meaning that the user has full permissions on the database.

2. Add the database connection string named `RhetosConnectionString` to the `appsettings.json` file,
   for example:

   ```js
   "ConnectionStrings": {
      "RhetosConnectionString": "Data Source=ENTER_SQL_SERVER_NAME;Initial Catalog=ENTER_RHETOS_DATABASE_NAME;Integrated Security=SSPI;"
   }
   ```

> Note:
The connection string is placed in `appsettings.json` to simplify this tutorial.
In practice, it should not included in the application's source for security reasons
and better configuration management.
For example, the connection string may be placed in a separate environment-specific file
(`local.settings.json`, e.g.)
that will not be added to Visual Studio project nor committed to the source repository (use .gitignore),
so that it can be configured separately for each developer and each test/production environment.

### Applying Rhetos model to database

The model described in the DSL script above (Books.rhe) will be used to create the
tables and other objects in the database.
To apply the model to database we need to use `rhetos.exe` CLI tool.

1. Run `dotnet build`

2. In the binary output folder (`Bookstore.Service\bin\Debug\net6.0`) execute dbupdate command:
   `rhetos.exe dbupdate Bookstore.Service.dll`

If you receive a database connection error, correct the connection string
and run the `dotnet build` again.

After dbupdate executes successfully, verify that the table Bookstore.Book has been created in the database.

Detailed log of `Rhetos DbUpdate` command is available in "Logs" subfolder,
for example see `Bookstore.Service\bin\Debug\net6.0\Logs\RhetosCli.log`.

See [Rhetos CLI](Rhetos-CLI) article for more info on the utility commands.

## Use Rhetos components in ASP.NET controllers

This example shows how to use Rhetos components when developing a custom controller.

Add a new controller `Controllers/DemoController.cs`:

```cs
using Microsoft.AspNetCore.Mvc;
using Rhetos;
using Rhetos.Processing;
using Rhetos.Processing.DefaultCommands;

[Route("Demo/[action]")]
public class DemoController : ControllerBase
{
    private readonly IProcessingEngine processingEngine;
    private readonly IUnitOfWork unitOfWork;

    public DemoController(IRhetosComponent<IProcessingEngine> processingEngine, IRhetosComponent<IUnitOfWork> unitOfWork)
    {
        this.processingEngine = processingEngine.Value;
        this.unitOfWork = unitOfWork.Value;
    }

    [HttpGet]
    public string ReadBooks()
    {
        var readCommandInfo = new ReadCommandInfo { DataSource = "Bookstore.Book", ReadTotalCount = true };
        var result = processingEngine.Execute(readCommandInfo);
        return $"{result.TotalCount} books.";
    }

    [HttpGet]
    public string WriteBook()
    {
        var newBook = new Bookstore.Book { Title = "NewBook" };
        var saveCommandInfo = new SaveEntityCommandInfo { Entity = "Bookstore.Book", DataToInsert = new[] { newBook } };
        processingEngine.Execute(saveCommandInfo);
        unitOfWork.CommitAndClose(); // Commits and closes database transaction.
        return "1 book inserted.";
    }
}
```

By default, Rhetos permissions will not allow anonymous users to read any data. Enable anonymous access by modifying `appsettings.json`:

```json
"Rhetos": {
  "AppSecurity": {
    "AllClaimsForAnonymous": true
  }
}
```

Run `dotnet run` and browse to `http://localhost:5000/Demo/ReadBooks`.
You should receive a response value `0 books.` indicating there are 0 entries in the database.

* Instead of `http://localhost:5000`, your application might have a different base URI.
  See the base URI in the output text from `dotnet run` command.
* For the rest of this tutorial, the examples will use the **port number 5000**.
  Replace it with your application's port number if it is different.

In `WriteBook` method, `unitOfWork.CommitAndClose()` commits the database transaction
for the current unit of work (a web request).

* Instead of manually committing the transaction, you can later use a ServiceFilter `ApiCommitOnSuccessFilter` from Rhetos.RestGenerator plugin,
see [example](https://github.com/Rhetos/Bookstore/blob/master/src/Bookstore.Service/Controllers/BookController.cs).

## Read next

* Install recommended dev tools from article on [Prerequisites](Prerequisites).
* Configure standard development environment and add common integration features to your Rhetos app:
  [Recommended application setup](Recommended-application-setup).
