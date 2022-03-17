# Creating a new WCF application with Rhetos framework

This article shows how to create a new application that uses Rhetos framework.

In this tutorial, we will create **a business service** for demo application called "Bookstore",
test it, and later add some additional features in other tutorial articles.

* *Business service* is a web application that manages business features, data and security,
  and exposes the features through a web API.
  We will use automatically generated RESTful JSON API in this tutorial.
* This is a typical usage of Rhetos framework as a part of an N-tier
  enterprise system where the front-end is developed as a separate application
  (for example, an Angular web application).
* Currently only WCF applications are supported. We plan to extend this to any Visual Studio
  project type in future releases.

This article applies to **Rhetos framework v4.0** and later versions. For older versions
see articles [Create your first Rhetos application](Create-your-first-Rhetos-application)
or [Migrating from DeployPackages to Rhetos.MSBuild with Rhetos CLI](Migrating-from-DeployPackages-to-Rhetos-CLI).

Contents:

1. [Development environment setup](#development-environment-setup)
2. [Create a new application in Visual Studio](#create-a-new-application-in-visual-studio)
3. [Set up the database and user authentication](#set-up-the-database-and-user-authentication)
4. [Write a simple DSL script](#write-a-simple-dsl-script)
5. [Build your application](#build-your-application)
6. [Test and review the application](#test-and-review-the-application)
7. [Publishing the application to a test environment or production](#publishing-the-application-to-a-test-environment-or-production)
8. [A more complex project structure](#a-more-complex-project-structure)
9. [Read next](#read-next)
10. [Troubleshooting](#troubleshooting)

## Development environment setup

1. Install the **IntelliSense** support for **Rhetos DSL**: Visual Studio => Extensions =>
   Manage Extensions => Online => Search: "Rhetos DSL Language Extension" => Download.
   Note that this extension is not required for developing and building Rhetos applications,
   but it is very useful when using Visual Studio as an editor for DSL scripts.
2. Before creating a new project, make sure that you will use the new **PackageReference** format
   in Visual Studio, instead of **packages.config**.:
   Visual Studio 2019 => Tools => NuGet Package Manager => Package Manager Settings =>
   Default package management format: "PackageReference".
   Rhetos MSBuild integration requires the information on packages that is provided by
   PackageReference format.
3. To make sure that you have all system components installed for developing web applications
   with .NET Framework, follow the article [Prerequisites](Prerequisites).

## Create a new application in Visual Studio

1. Visual Studio 2019 => Create a new project => search and select "**WCF Service Application**" (C#) => Next.
   For tutorial, enter Project name: "Bookstore.Service", Solution name: "Bookstore".
   Select framework: ".NET Framework 4.7.2", then click Create.
   * If "WCF Service Application" project type is not available:
     Click "Install more tools and features" to open
     Visual Studio Installer => Select "Individual components" tab =>
     Enable "Windows Communication Foundation" => Click "Modify" to install.
2. Test the new project:
   1. Select "Service1.svc" in Solution Explorer and press F5 to start debugging.
   2. WCF Test Client should open automatically => Double-click "GetData()" method => Invoke =>
      OK => Response Value should be "You entered: 0".
3. Add the following **NuGet packages** (if NuGet dialog asks for format, select ProjectReference instead of packages.config).
   1. Rhetos.Wcf
   2. Rhetos.CommonConcepts
   3. Rhetos.RestGenerator
4. Save the solution (File => Save All). In Visual Studio open Package Manager Console,
   in the console at "Default project" select you application (Bookstore.Service, e.g.)
   and run command `Add-RhetosWcfFiles`. It will add Rhetos WCF startup configuration and services
   to the application.
   * If the command results with execution policy error,
     run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` and then
     run `Add-RhetosWcfFiles` again.
   * If the command results with `Access is denied`, save the solution (File => Save All)
     before running it again.
     If needed, try closing all Visual Studio windows and open the solution again.
5. Configure git repository:
   1. Add a standard [Visual Studio .gitignore](https://github.com/github/gitignore/blob/master/VisualStudio.gitignore)
      file to the solution's folder.
   2. Append Rhetos folders and user files to the end of the .gitignore file.
      For example, if your project subfolder is "Bookstore.Service", append the following:
      ```text
      # Rhetos
      /Bookstore.Service/rhetos-app.local.settings.json
      /Bookstore.Service/Logs
      /Bookstore.Service/Resources
      /Bookstore.Service/ConnectionStrings.config
      /Bookstore.Service/ExternalAppSettings.config
      ```

## Set up the database and user authentication

1. Create an empty database for this Rhetos application
   (SQL Server 2008 or newer, Developer Edition is recommended for development).
   * Note: Each application and each developer should have a separate database.
2. In your project folder, rename `Template.ConnectionStrings.config` to `ConnectionStrings.config`.
   Edit `ConnectionStrings.config`: replace `theDatabase` with your database name,
   and `theServer` with your SQL Server [instance](https://stackoverflow.com/a/45789478/2086516) name.
3. Configure user authentication for your application:
   * Create file `rhetos-app.local.settings.json` in project folder
     (where `Bookstore.Service.csproj` is located).
     This is an environment-specific file, it should not be added to the Visual Studio project or source control.
     It is already excluded from source repository by .gitignore (see above).
   * Option A) *(Recommended for quick-start)* **Enable anonymous access**:
     * In file `rhetos-app.local.settings.json` enter text:
       `{ "Rhetos": { "AppSecurity": { "AllClaimsForAnonymous": true } } }`
   * Option B) **Windows authentication with IIS**:
     * Run Visual Studio *as Administrator*. Project properties => Web =>
       Change from "ISS Express" to "Local IIS". On save answer Yes.
     * Open IIS Manager => Find and select your web application.
       * Authentication => Disable Anonymous, Enable Windows Authentication.
       * Basic settings => Change application pool
         to new RhetosAppPool that is configured to run with your development account
         (see [IIS Setup](Development-environment-setup#iis-setup))
     * In file `rhetos-app.local.settings.json` enter text:
       `{ "Rhetos": { "AppSecurity": { "AllClaimsForUsers": "account@computername" } } }`,
       for your account and your machine name, to simplify testing. See the instructions in
       [Suppressing permissions in a development environment](Basic-permissions#suppressing-permissions-in-a-development-environment).
     * In the table `Common.Principal` insert a record with the `Name` column value set to your username.
   * Option C) **Windows authentication with IIS Express**:
     * Edit `.vs\<solution name>\config\applicationhost.config`
       * in element `anonymousAuthentication` set `enabled` attribute to `false`.
       * in element `windowsAuthentication` set `enabled` attribute to `true`.
     * In file `rhetos-app.local.settings.json` enter text:
       `{ "Rhetos": { "AppSecurity": { "AllClaimsForUsers": "account@computername" } } }`,
       for your account and your machine name, to simplify testing. See the instructions in
       [Suppressing permissions in a development environment](Basic-permissions#suppressing-permissions-in-a-development-environment).
       Note that the backslash character ("`\`") should be written as "`\\`" in a .json file.
     * In the table `Common.Principal` insert a record with the `Name` column set to your username.
   * Other [authentication methods](https://github.com/Rhetos/Rhetos/wiki/User-authentication-and-authorization)
     can be used by adding a specific plugin package or implementing a custom user provider.
4. Test the application: Select the project in Solution Explorer (e.g. Bookstore.Service)
   and press F5 to start debugging.
    * Web browser should open automatically, displaying "Installed packages" list and "Server status".
      * If using Windows Authentication, check that "User identity" displays your account name.
    * In the browser append `rest/Common/Claim/` to the base URL.
      It should return list of records in JSON format.
    * **In case of an error**, see [Troubleshooting](#troubleshooting) chapter below.

## Write a simple DSL script

Right-click the project => Add folder "DslScripts".
In the folder add **Text file** "Books.rhe", and enter the following code:

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

This script is the source code of the Bookstore application,
written in the Rhetos DSL programming language.

Rhetos DSL is a declarative language, and the source code should be viewed as a **set of features (statements)**.
Each statement is starting with a *keyword* (Module, Entity, ShortString, AutoCode, ...)
and some *parameters* after the keyword. Statements can be nested in other statements.

* **Module** keyword represents a business module, and a namespace in C# code.
* **Entity** represents a business object (C# class) and a table in database that contains the object's data.
  The Book entity here contains some properties and some business features.
  These features are explained in later tutorial articles, see [Read next](#read-next) below.
* See [Rhetos DSL syntax](Rhetos-DSL-syntax) article for better understanding of the DSL scripts.

## Build your application

Rhetos MSBuild integration has already been enabled on this application,
since we installed Rhetos.Wcf NuGet package (it has a dependency to Rhetos.MSBuild package).
When building the application in Visual Studio or MSBuild,
the following steps are executed automatically:

1. `rhetos.exe build` command. It compiles DSL scripts (.rhe) and generates
   additional C# code for the current application (obj\Rhetos\RhetosSource), and the database model.
2. C# compiler compiles the generated and custom application source.
3. `rhetos.exe dbupdate` command. It updates the database structure and data.

You can also manually execute Rhetos CLI commands from command prompt.
For large projects you can disable automatic database update on build,
and run it manually from console before testing the application.
See [Rhetos CLI](Rhetos-CLI) article for more info.

Review the Rhetos build output:

1. Add an empty line to HelloWorld.rhe script to provoke Rhetos compiler,
   and build the application again.
2. In Visual Studio, open the "Output" window (View => Output), and select Show output from: "Build".
   It will display the Rhetos CLI output for build and dbupdate commands.

## Test and review the application

Here we will run the application and test the generated REST API for the Book entity.

* The Book entity was implements in the HelloWorld.rhe DSL script (see above).
* The REST API is automatically generated by Rhetos.RestGenerator NuGet package.

Steps:

1. Run the application from Visual Studio. It should open web browser with application's base URL,
   displaying "Installed packages" list and "Server status".
   * The base URL might be similar to <http://localhost:12345> for IIS Express,
     or <http://localhost/Bookstore.Service> for IIS.
     Let's call this BASE_URL in the following examples.
2. Open "BASE_URL/rest/Bookstore/Book/". It should return an empty JSON array
   `{ "Records": [] }` if there are no records in the database table.
3. Open SQL Server Management Studio and and check that the database contains "Bookstore.Book" table.
   Enter some data directly into the table.
4. Open "BASE_URL/rest/Bookstore/Book/" to see the entered records in JSON format.
5. Install a browser plugin for REST commands (such as "Restlet Client" or "RESTer"),
   that will allow you to **insert a new book** through the application's REST API.
   This will enable us to test the implemented business logic (such as AutoCode and InvalidData).
    * Using the plugin send the following web request:
      * Method: POST
      * URL: BASE_URL/rest/Bookstore/Book/
      * Header: Name `Content-Type`, Value `application/json; charset=utf-8`
      * Body: `{ "Code": "B+++", "NumberOfPages": 123, "Title": "The curiousity" }`
    * The expected response from the application is "400 Bad Request", with the UserMessage
      "It is not allowed to enter misspelled word "curiousity".".
      This is a standard Rhetos response for validation that is defined with **InvalidData**
      concept (see the DSL script above).
    * You can also use Postman to test the REST Web API, see the [instructions](Using-Postman-with-Rhetos).
      Note that it sometimes has trouble with Windows Authentication.
6. Correct the request body by replacing "The curiousity" with "The curiosity", and send the request again.
    * The expected response is "200 OK" with the generated ID in the response body.
7. View the new book in the database or in browser. Check that the inserted book has automatically
   generated three-digit Code with prefix "B" (by **AutoCode** concept for pattern "B+++").

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

## Publishing the application to a test environment or production

In **development environment**, you can run the application directly from Visual Studio,
there is no need to publish it.

To publish the application to a **shared test or production environment**,
you will need to copy the application files and update the database:

1. Copy the application files from the project folder to the target folder. This includes:
   * Bin folder and subfolders.
   * Resources folder - Some of the Rhetos plugin packages use it, but only if configuration option
     "BuildResourcesFolder" is enabled in build settings.
   * LinqPad folder - Utilities for accessing application's object model.
   * Following files from project folder:
     * *.aspx
     * *.asax
     * *.svc
     * Web.config
     * rhetos-app.settings.json
2. For *initial* deployment, you will need to setup IIS and database:
   * Create a web application in IIS with the target folder as a source.
     Configure app pool and authentication, see [IIS setup](Development-Environment-Setup#iis-setup).
   * Create an empty database and configure connection string.
   * Configure any environment-specific settings in rhetos-app.local.settings.json,
     see [Configuration management](Configuration-management).
3. Update the database by running `rhetos dbupdate` from command prompt
   in the target application's **bin** folder.
   See [Rhetos CLI](Rhetos-CLI) article for dbupdate options.

To update the test or production environment again to a new version of the application,
follow the steps 1. and 3. above.

## A more complex project structure

[Bookstore](https://github.com/Rhetos/Bookstore) demo application, available on GitHub,
is an example of a Rhetos application with multiple projects, including custom DSL language
extensions, basic unit tests and integration tests.

You can use its **project structure, build process and utility scripts** as a *prototype*
for a new Rhetos applications.
For more information, see [Readme.md](https://github.com/Rhetos/Bookstore/blob/master/Readme.md).

## Read next

Add new features to you application with following tutorial articles:

1. How to create a data model: [Data model and relationships](Data-model-and-relationships)
2. Add simple features to your application: [Implementing simple business rules](Implementing-simple-business-rules)

## Troubleshooting

1. Build fails with error `System.Configuration.ConfigurationErrorsException: Unable to open configSource file 'ConnectionStrings.config'.`
   * Cause: *Web.config* references *ConnectionStrings.config* that is missing. See instructions above on how to add *ConnectionStrings.config*.
2. Startup fails with `Specified argument was out of the range of valid values.Parameter name: site`
   * See "Configure user authentication for your application" above.
3. Web page returns `Access to the path '...' is denied.` or UnauthorizedAccessException in `Internal server error occurred. See RhetosServer.log for more information. (UnauthorizedAccessException`
   * Cause: The application (or IIS app pool) does not have access to application folder.
   * Option A) Open IIS Manager => Find your application => Basic settings => Change application pool to new RhetosAppPool that is configured to run with your development account (see [IIS Setup](Development-environment-setup#iis-setup))
   * Option B) Add IIS web account permission for the application's folder (see ICACLS commands from [Configure IIS](https://github.com/Rhetos/AspNetFormsAuth#2-configure-iis))
4. Startup fails with `SqlUtility has not been initialized correctly: Value for connection string (name="ServerConnectionString") is not specified.`
   or `Configuration value for connection string 'RhetosConnectionString' (settings key "ConnectionStrings:RhetosConnectionString") is not specified.`
   * Configure ConnectionStrings.config (see instructions in the section above).
5. Startup fails with SqlException `Login failed for user 'IIS APPPOOL\DefaultAppPool'.`
   * Cause: The application (or IIS app pool) does not have access to the database. If using IIS, Open IIS Manager => Find your application => Basic settings => Change application pool to new RhetosAppPool that is configured to run with your development account (see [IIS Setup](Development-environment-setup#iis-setup))
6. Startup fails with `User is not authenticated`
   * See instructions in "Configure user authentication for your application" above.
7. Visual Studio shows errors `The type or namespace name '...' could not be found`, even though Build passes successfully.
   * Click "Refresh" button in Solution Explorer to refresh IntelliSense.

See also a separate article on [Troubleshooting WCF services](Troubleshooting-WCF-services).
