# Recommended application setup

This tutorial shows how to configure standard development environment and
add common integration features to your Rhetos app.

Contents:

1. [Prerequisites](#prerequisites)
2. [Additional development environment setup](#additional-development-environment-setup)
   1. [Using Visual Studio and automatic dbupdate](#using-visual-studio-and-automatic-dbupdate)
   2. [Setup git repository](#setup-git-repository)
3. [Additional integration/extension options](#additional-integrationextension-options)
   1. [Adding Rhetos dashboard](#adding-rhetos-dashboard)
   2. [Adding Rhetos.RestGenerator](#adding-rhetosrestgenerator)
   3. [View Rhetos REST endpoints in Swagger](#view-rhetos-rest-endpoints-in-swagger)
   4. [Use NLog to write application's system log into a file](#use-nlog-to-write-applications-system-log-into-a-file)
   5. [Adding localization](#adding-localization)
   6. [Improve Entity Framework performance](#improve-entity-framework-performance)
4. [Publishing the application to a test environment or production](#publishing-the-application-to-a-test-environment-or-production)
5. [A more complex project structure](#a-more-complex-project-structure)
6. [Read next](#read-next)

## Prerequisites

* Create a Rhetos app by following the instructions in tutorial
  [Creating a new application with Rhetos framework](Creating-a-new-application-with-Rhetos-framework).

## Additional development environment setup

### Using Visual Studio and automatic dbupdate

Visual Studio is not required for development of Rhetos apps, but it can be helpful because
there is a DSL IntelliSense extension available for VS.

1. Install Visual Studio 2022 or later, it is required for .NET 6 applications.
   .NET 5 applications can be developed in Visual Studio 2019 and 2022.

2. Download and install **Rhetos DSL IntelliSense** for Visual Studio.
   See [Installation instructions](https://github.com/Rhetos/LanguageServices#installation).

3. For a better insight on build process, show Output on build in Visual Studio:
   Tools => Options => Projects and Solutions => General => Enable: "Show Output window when build starts".

4. For this tutorial, create a solution in Bookstore folder and add the existing project to the solution.
   You can do this by executing the following commands in "Bookstore" folder:

   ```batch
   dotnet new sln
   dotnet sln add --in-root src\Bookstore.Service\Bookstore.Service.csproj
   ```

5. Configure automatic Rhetos database update on build. This is a helpful feature for
   development environment on **smaller projects**.

   * Open the Bookstore.sln (created in previous step) in Visual Studio 2022.
     In Solution Explorer window, double-click the "Bookstore.Service" project
     to open the .csproj file, and set RhetosDeploy property to `True`.

Test:

* Test if DSL IntelliSense is available by editing DslScripts/Books.rhe directly in Visual Studio.
* Review the build output:
  * Add a new property to entity Book in Books.rhe: `ShortString SomeProperty;`
  * Build the application in Visual Studio, and review Rhetos log from the build output in Visual Studio
    (View => Output, select Show output from: "Build").
    It will display the Rhetos CLI output for Build and DbUpdate commands.
  * The log should contain a line `DatabaseGenerator: Creating 1 database objects`,
    which is related to creating this new column in the database.
* Press F5 to run the application in Visual Studio.
  By default, it should open Swagger page with visible Demo controller API.
  Test /Demo/ReadBooks with Swagger (expand it => Try it out => Execute).
  "Response body" should show the number of the books.

Review the generated source code in Visual Studio:

1. In Solution Explorer select your application project (Bookstore.Service),
   and click "Show All Files" toolbar button.
   It should display additional files and subfolders under the projects.
2. Open `obj\Rhetos\Source\Model\BookstoreModel.cs` and find `class Book`.
   It contains basic properties as specified in the DSL script.
3. Open `obj\Rhetos\Source\Repositories\BookstoreRepositories.cs` and find `class Book_Repository`.
   It contains implementation of all business rules for the Book entity.
   * For example, it contains a `Filter` method with parameter `CommonMisspelling`, that applies
     the filter specified in the DSL script on a given LINQ query.

Disabling rhetos dbupdate in build scripts:

* When dbupdate is enabled on build (RhetosDeploy not set to False in .csproj file),
  you can disable it on automated builds such as Azure Pipelines to make the build process cleaner.
  Simply disable RhetosDeploy in the build script with /p switch: `dotnet build /p:RhetosDeploy=False`.

### Setup git repository

This tutorial covers standard application development environment,
and git source control is a recommended part of it.

Create a git repository for this solution with Visual Studio (Git => Create Git Repository),
or any other utility.
If using a different utility to create the git repository, make sure to add a standard
[".gitignore" file for Visual Studio](https://raw.githubusercontent.com/github/gitignore/main/VisualStudio.gitignore)
to the solution's folder.

## Additional integration/extension options

### Adding Rhetos dashboard

Rhetos dashboard is a standard Rhetos "homepage" that includes basic system information and GUI for some plugins.
It is intended for testing and administration, but it could also be used by end users if needed,
since all official features are implemented with standard Rhetos security permissions.

* Various plugins extend the dashboard with custom information and controls.

Adding Rhetos dashboard to a Rhetos app:

1. Extend the Rhetos services configuration (at `builder.Services.AddRhetosHost`)
   with the dashboard components: `.AddDashboard()`

2. Extend the application with new endpoint just before `app.Run()`:

   ```cs
   if (app.Environment.IsDevelopment())
      app.MapRhetosDashboard();
   ```

To see the dashboard, run `dotnet run Environment=Development` and navigate to `https://localhost:5000/rhetos`.
The route is configurable in `MapRhetosDashboard` parameter.

### Adding Rhetos.RestGenerator

Rhetos.RestGenerator package automatically maps all Rhetos data structures to REST endpoints.

If you are following a Bookstore tutorial, it will generate a RESTful JSON web service
for the Book entity that was implemented previously in the
[Books.rhe](Creating-a-new-application-with-Rhetos-framework#introduction-rhetos-dsl-programming-language)
DSL script.

1. Add NuGet package "Rhetos.RestGenerator" to the Bookstore.Service project.

2. Extend the Rhetos services configuration (at `builder.Services.AddRhetosHost`)
   with Rhetos REST plugin components: `.AddRestApi(o => o.BaseRoute = "rest")`

3. **Before** line `app.MapControllers()` or `app.UseEndpoints`, add `app.UseRhetosRestApi();`

Test the generated REST API:

1. If you have not configured anonymous authentication yet, enable "AllClaimsForAnonymous"
   configuration option (see the example in the [previous tutorial](Creating-a-new-application-with-Rhetos-framework#use-rhetos-components-in-aspnet-controllers)).
2. Run the application in Visual Studio or execute `dotnet run`.
   The application not contains the generated REST API.
3. In browser, navigate to `https://localhost:5000/rest/Bookstore/Book` to issue a GET
   and retrieve all Book entity records in the database.
4. Open SQL Server Management Studio and and check that the database contains "Bookstore.Book" table.
   Enter some data directly into the table.
5. Browse "rest/Bookstore/Book" again, to see the entered records in JSON format.

For more info on usage and serialization configuration see [Rhetos.RestGenerator](https://github.com/Rhetos/RestGenerator)

### View Rhetos REST endpoints in Swagger

Since Swagger is already added to "webapi" project template by default,
we can generate Open API specification for mapped Rhetos endpoints.

1. Modify `AddRestApi` call with to read:

   ```cs
       .AddRestApi(o => 
       {
           o.BaseRoute = "rest";
           o.GroupNameMapper = (conceptInfo, controller, oldName) => "v1";
       });
   ```

2. To support multiple entities with the same name in different modules,
   add CustomSchemaIds to the existing `builder.Services.AddSwaggerGen` method call:

   ```cs
   builder.Services.AddSwaggerGen(o => o.CustomSchemaIds(type => type.ToString())); // CustomSchemaIds allows multiple entities with the same name in different modules.
   ```

This addition maps all generated Rhetos API controllers to an existing Swagger document named 'v1'.

Test the implemented business logic on Book entity, by using Rhetos REST API with Swagger UI:

1. Run the application from Visual Studio (Start without Debugging), or execute `dotnet run Environment=Development`,
   then navigate to `https://localhost:5000/swagger/index.html`.
   You should see the entire Rhetos REST API in interactive UI.
2. Use the Swagger UI to **insert a new book** with incorrect title:
   * Expand method "POST /rest/Bookstore/Book" => click "Try it out"
   * In the "Request body" enter `{ "Code": "B+++", "NumberOfPages": 123, "Title": "The curiousity" }`
   * Click "Execute".
   * Server response should display `400 Error: Bad Request`, with userMessage: `"It is not allowed to enter misspelled word "curiousity"`.
     This is a standard Rhetos response for validation that is defined with **InvalidData**
     concept (see the DSL script above).
3. Correct the request body by replacing "The curiousity" with "The curiosity", and send the request again.
   * The expected response is "200 OK" with the generated ID in the response body.
4. View the new book in the database or in browser. Check that the inserted book has automatically
   generated three-digit Code with prefix "B" (by **AutoCode** concept for pattern "B+++").

In larger applications, for improved Swagger load time, it is recommended to
**split each DSL Module into a separate Swagger document** (this is default `GroupNameMapper` behavior).
See additional instructions in RestGenerator documentation in section
[Adding Swagger/OpenAPI](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md#adding-swaggeropenapi).

### Use NLog to write application's system log into a file

1. Add NuGet package `NLog.Web.AspNetCore`, select latest release of 4.x.x.
2. In Program.cs add `using NLog.Web;`
3. Add `builder.Host.UseNLog();`
4. Extend the Rhetos services configuration (at `builder.Services.AddRhetosHost`)
   with `.AddHostLogging()` (if it's not there already).
5. To configure NLog add the `nlog.config` file to the project.
   Make sure that the file properties are set to Copy to Output Directory: Copy if newer.
   To make logging compatible with Rhetos v3 and v4, enter the following text into the file.

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- THis configuration file is used by NLog to setup the logging if the hostBuilder.UseNLog() method is called inside the Program.CreateHostBuilder method-->
<nlog throwConfigExceptions="true" xmlns="http://www.nlog-project.org/schemas/NLog.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <targets>
    <target name="MainLog" xsi:type="File" fileName="${basedir}\Logs\RhetosServer.log" encoding="utf-8" archiveFileName="${basedir}\Logs\Archives\RhetosServer {#####}.zip" enableArchiveFileCompression="true" archiveAboveSize="2000000" archiveNumbering="DateAndSequence" />
    <target name="ConsoleLog" xsi:type="Console" />
    <target name="TraceLog" xsi:type="AsyncWrapper" overflowAction="Block">
      <target name="TraceLogBase" xsi:type="File" fileName="${basedir}\Logs\RhetosServerTrace.log" encoding="utf-8" archiveFileName="${basedir}\Logs\Archives\RhetosServerTrace {#####}.zip" enableArchiveFileCompression="true" archiveAboveSize="10000000" archiveNumbering="DateAndSequence" />
    </target>
    <target name="TraceCommandsXml" xsi:type="AsyncWrapper" overflowAction="Block">
      <target name="TraceCommandsXmlBase" xsi:type="File" fileName="${basedir}\Logs\RhetosServerCommandsTrace.xml" encoding="utf-16" layout="&lt;!--${longdate} ${logger}--&gt;${newline}${message}" archiveFileName="${basedir}\Logs\Archives\RhetosServerCommandsTrace {#####}.zip" enableArchiveFileCompression="true" archiveAboveSize="10000000" archiveNumbering="DateAndSequence" />
    </target>
    <target name="PerformanceLog" xsi:type="AsyncWrapper" overflowAction="Block">
      <target name="PerformanceLogBase" xsi:type="File" fileName="${basedir}\Logs\RhetosServerPerformance.log" encoding="utf-8" archiveFileName="${basedir}\Logs\Archives\RhetosServerPerformance {#####}.zip" enableArchiveFileCompression="true" archiveAboveSize="10000000" archiveNumbering="DateAndSequence" />
    </target>
  </targets>
  <rules>
    <logger name="*" minLevel="Info" writeTo="MainLog" />
    <!-- <logger name="*" minLevel="Info" writeTo="ConsoleLog" /> -->
    <!-- <logger name="*" minLevel="Trace" writeTo="TraceLog" /> -->
    <!-- <logger name="ProcessingEngine Request" minLevel="Trace" writeTo="ConsoleLog" /> -->
    <!-- <logger name="ProcessingEngine Request" minLevel="Trace" writeTo="TraceLog" /> -->
    <!-- <logger name="ProcessingEngine Commands" minLevel="Trace" writeTo="TraceCommandsXml" /> -->
    <!-- <logger name="ProcessingEngine CommandsResult" minLevel="Trace" writeTo="TraceCommandsXml" /> -->
    <!-- <logger name="ProcessingEngine CommandsWithClientError" minLevel="Trace" writeTo="TraceCommandsXml" /> -->
    <logger name="ProcessingEngine CommandsWithServerError" minLevel="Trace" writeTo="TraceCommandsXml" />
    <!-- <logger name="ProcessingEngine CommandsWithServerError" minLevel="Trace" writeTo="MainLog" /> -->
    <!-- <logger name="Performance*" minLevel="Trace" writeTo="PerformanceLog" /> -->
  </rules>
</nlog>
```

Test the logging with the above configuration:

* Run the application.
  NLog should create the log file `Bookstore.Service\bin\Debug\net6.0\Logs\RhetosServer.log`.

### Adding localization

Localization provides support for multiple languages, but it can also be very useful even if
an application uses **only one** language (English, e.g.) to modify the standard system messages
to match the client requirements (for example, when a required field is not set).

Localization in Rhetos app is automatically applied on translating the Rhetos response messages
for end users. For example, a data validation error message (InvalidData), UserException, and other.

The following example adds [GetText/PO](http://en.wikipedia.org/wiki/Gettext) localization
support to the Rhetos app:

1. Rhetos components are configured to use the host application's localization
   (standard ASP.NET Core localization) by simply adding `AddHostLocalization()` in Rhetos setup.
2. **Any ASP.NET Core localization plugin can be used.**
   This example uses OrchardCore, a 3rd party library recommended by Microsoft,
   see [Configure portable object localization in ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/portable-object-localization?view=aspnetcore-5.0)

Add localization to your Rhetos app:

1. Add NuGet package "OrchardCore.Localization.Core".

2. In the `.csproj` file, add the following lines:

    ```xml
      <ItemGroup>
        <None Update="Localization\hr.po">
          <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
      </ItemGroup>
    ```

3. Create file `Localization\hr.po` with translations for language "hr" with the following content
   (see [CultureInfo](https://docs.microsoft.com/en-us/dotnet/api/system.globalization.cultureinfo)
   and [Windows languages](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c)
   for language tags):

    ```pot
    msgid "It is not allowed to enter {0} because the required property {1} is not set."
    msgstr "Please fill out the field '{0}' on '{1}'. (this is customized message)"
    
    msgid "NumberOfPages"
    msgstr "Number of pages"
    
    msgid "AuthorID"
    msgstr "Author"
    
    msgctxt "Bookstore.Book"
    msgid "AuthorID"
    msgstr "Author of the book"
    ```

4. In `Program.cs` file, add the following lines.
   Note that DefaultRequestCulture is set to "hr" language in this example instead of "en" (English),
   to match the language of "hr.po" file from the previous step.

    ```cs
    using Microsoft.AspNetCore.Localization;
    using System.Collections.Generic;
    using System.Globalization;

    // ... Add at builder.Services.AddRhetosHost:
              .AddHostLocalization()

    // ... Add where other builder.Services are configured:
    builder.Services.AddLocalization()
        .AddPortableObjectLocalization(options => options.ResourcesPath = "Localization")
        .AddMemoryCache();

    // ... Add after UseRouting(), if applicable:
    // For information on ordering the Localization Middleware in the middleware pipeline of Program.cs, see ASP.NET Core Middleware https://docs.microsoft.com/en-us/aspnet/core/fundamentals/middleware/?view=aspnetcore-6.0#middleware-order
    app.UseRequestLocalization(options =>
    {
        var supportedCultures = new List<CultureInfo>
        {
            new CultureInfo("en"),
            new CultureInfo("hr")
        };

        options.DefaultRequestCulture = new RequestCulture("hr"); // Default language to use for requests.
        options.SupportedCultures = supportedCultures;
        options.SupportedUICultures = supportedCultures;
        options.RequestCultureProviders = new List<IRequestCultureProvider>
        {
            // The culture will be resolved based on the query parameter.
            // For example if we want the validation message to be translated to Croatian
            // we can call the POST method rest/Bookstore/Book?culture=hr and insert a json object without the 'Title' property.
            // It can be configured so that the culture gets resolved based on cookies or headers.
            new QueryStringRequestCultureProvider()
        };
    });
    ```

Test the localization:

1. Run the application.
2. Use Swagger, or another utility, to POST a request to `https://localhost:5000/rest/Common/Role`
   with an empty JSON object in a request body: `{}`.
3. The server response should contain the localized error message:
   `"Please fill out the field 'Common.Role' on 'Name'. (this is customized message)"`,
   instead of the default message
   `"It is not allowed to enter Common.Role because the required property Name is not set."`

For example in a demo application, see [Bookstore.Service/Startup.cs](https://github.com/Rhetos/Bookstore/blob/master/src/Bookstore.Service/Startup.cs).

### Improve Entity Framework performance

Complex applications with large number of entities may experience performance improvement
if Entity Framework's query cache size is increased from its default value.
This needs to be configured in App.config, since EF 6 still uses the `ConfigurationManager`
class to load its configuration.

* Add the App.config file as a plain text file in the project root, with the recommended
EF configuration settings:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <configSections>
        <section name="entityFramework" type="System.Data.Entity.Internal.ConfigFile.EntityFrameworkSection, EntityFramework" />
    </configSections>
    <entityFramework>
        <queryCache size="10000" cleaningIntervalInSeconds="60" />
    </entityFramework>
</configuration>
```

## Publishing the application to a test environment or production

In **development environment**, you can run the application directly from Visual Studio,
there is no need to publish it.

In simplest form, a .NET application may be published to a **shared test environment or production**
by simply copying the binary folder to the target machine.
Various other methods may be used, depending on the hosting environment,
see an overview in [Host and deploy ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/?view=aspnetcore-6.0).

After publishing a Rhetos app, you will need to **update the database**.
This is done by running Rhetos CLI utility that is automatically included with the application's binaries
(in bin folder):

1. For **initial deployment**, you will need to create an empty database and configure connection string,
   then run `rhetos.exe dbupdate Bookstore.Service.dll` command to populate the database.
2. When updating a previously deployed application to a **new version**,
   after copying the new application files,
   run `rhetos.exe dbupdate Bookstore.Service.dll` again to update the existing database.

## A more complex project structure

[Bookstore](https://github.com/Rhetos/Bookstore) demo application, available on GitHub,
is an example of a Rhetos app with multiple projects, including custom DSL language
extensions, basic unit tests and integration tests.

You can use its **project structure, build process and utility scripts** as a *prototype*
for a new Rhetos apps.
For more information, see [Readme.md](https://github.com/Rhetos/Bookstore/blob/master/Readme.md).

## Read next

Add new business features to you application with following tutorial articles:

1. How to create a data model: [Data model and relationships](Data-model-and-relationships)
2. Add simple features to your application: [Implementing simple business rules](Implementing-simple-business-rules)
