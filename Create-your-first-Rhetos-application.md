This article shows how to create a new application that uses Rhetos framework.

In this tutorial, we will create a demo application called "Bookstore",
and later add a some additional features to the application in the other tutorial articles.
It is a simplified example of a business application that manages different processes in a bookstore.

Contents:

1. [Setup](#setup)
2. [Write a simple DSL scripts](#write-a-simple-dsl-scripts)
3. [Build your application](#build-your-application)
4. [Test and review](#test-and-review)
5. [Read next](#read-next)

## Setup

1. Make sure that you have all the [Prerequisites](Prerequisites) installed.
2. Follow the instructions in [Development environment setup](Development-environment-setup), to setup the development environment for the Bookstore applications.
The resulting folder structure should look like this:
    ```Text
    * Bookstore\
        * dist\
            * BookstoreRhetosServer\
        * src\
            * DslScripts\
    ```
3. Initialize the Git repository:
   1. Download the ".gitignore" from <https://raw.githubusercontent.com/Rhetos/Bookstore/master/.gitignore>, and place it in the Bookstore root folder (it is a default Visual Studio gitignore file with added `dist` subfolder that contains this project's output binaries).
   2. Open command prompt in the Bookstore folder and run the following commands:
      ```Text
      git init
      git add .
      git commit -m "Initial project structure"
      ```

## Write a simple DSL scripts

In `src\DslScripts` folder insert the file `Book.rhe`. Extension ".rhe" is used for scripts written in the Rhetos DSL programming language.

We recommend using Visual Studio Code with Rhetos plugin to edit the ".rhe" files (see [VS Code setup](https://github.com/Rhetos/Rhetos/wiki/Prerequisites#configure-your-text-editor-for-dsl-scripts-rhe)). Edit `Book.rhe` and type in the following text:

```C
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

This is the source code of the Bookstore application.

Rhetos DSL is a declarative language, and the source code should be viewed as a **set of features (statements)**.
Each statement is starting with a *keyword* (Module, Entity, ShortString, AutoCode, ...) and some *parameters* after the keyword.
Statements can be nested in other statements.

**Module** keyword represents a business module, and a namespace in C# code. **Entity** represents a business object (C# class) and a table in database that contains the object's data. The Book entity here contains some properties and some business features. These features are explained in later tutorial articles.

See [Rhetos DSL syntax](Rhetos-DSL-syntax) article for better understanding of the DSL scripts.

## Build your application

The Bookstore application backend is a web application set in the `dist\BookstoreRhetosServer` folder.
The Rhetos server application that you have downloaded in that folder,
contains only framework infrastructure, without business features.

All business features are included in the application as packages.
Edit `dist\BookstoreRhetosServer\RhetosPackages.config` file to contains the following list of packages:

```XML
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Rhetos.CommonConcepts" />
  <package id="Rhetos.RestGenerator" />
  <package id="Bookstore" source="..\..\src" />
</packages>
```

* **CommonConcepts** is the standard library for Rhetos. It contains keywords such as *Module* and *Entity*, and code generators for those keywords that will generate C# code (feature implementation) and the database.
* **RestGenerator** is a plugin that will generate a REST web API for the Bookstore application.
* **Bookstore** is a package that contains source code for our applications. Currently this is just one DSL script.

These packages will be downloaded into the BookstoreRhetosServer from different sources:

* CommonConcepts and RestGenerator will be downloaded automatically (as NuGet packages) from the public online gallery <https://nuget.org>.
  See `dist\BookstoreRhetosServer\RhetosPackageSources.config` file to check that it contains nuget.org in the default download locations list.
* The third package, "Bookstore", is not published as a NuGet package. To make the development easier, Rhetos can read a package directly from the source folder without need to "pack" it to a .nupkg file. Rhetos will detect the DslScripts subfolder by convention.

Open command prompt and run `dist\BookstoreRhetosServer\bin\DeployPackages.exe`. This utility will rebuild the BookstoreRhetosServer web application, based on the included plugins. See [What is Rhetos](What-is-Rhetos) article for a high-level overview of this process.

* Check the begging of the output to see that all three packages are included.
* If completed successfully (last line of output is "[Trace] DeployPackages: Done."), it has generated the web application.

Note that **after making changes** in the DSL script (Book.rhe), you will need to run `DeployPackages.exe` again to update the web application.

## Test and review

1. Open <http://localhost/BookstoreRhetosServer/> to see that the application is working.
    * The "Installed packages" list should contain the "Bookstore" package and others.
    * Check that the "User identity" displays your account name (Windows Authentication should be working).
2. Open the database and check that it contains "Bookstore.Book" table. Enter some data directly into the table.
3. Open <http://localhost/BookstoreRhetosServer/rest/Bookstore/Book/>  (don't skip the "/" at the end of the address) to see the entered records in JSON format.
4. Install a browser plugin for REST commands (such as "Restlet Client" or "RESTer"), that will allow you to **insert a new book** through the application. This will enable us to test the implemented business logic (such as AutoCode and InvalidData).
    * Using the plugin send the following web request:
      * Method: POST
      * URL: <http://localhost/BookstoreRhetosServer/rest/Bookstore/Book/>
      * Header: Name `Content-Type`, Value `application/json; charset=utf-8`
      * Body: `{ "Code": "B+++", "NumberOfPages": 123, "Title": "The curiousity" }`
    * The expected response from the server is "400 Bad Request", with the UserMessage "It is not allowed to enter misspelled word "curiousity".". This is a standard Rhetos response for validation that is defined with **InvalidData** concept (see the DSL script above).
    * Troubleshooting: If you are using Postman, note that it sometimes has trouble with Windows Authentication.
5. Correct the request body by replacing "The curiousity" with "The curiosity", and send the request again.
    * The expected response is "200 OK" with the generated ID in the response body.
6. View the new book in the database or in browser. Check that the inserted book has the automatically generated three-digit Code with prefix "B" (by **AutoCode** concept for pattern "B+++").

## Read next

Add new features to you application with following tutorial articles:

1. How to create a data model: [Data model and relationships](Data-model-and-relationships)
2. Add simple features to your application: [Implementing simple business rules](Implementing-simple-business-rules)
