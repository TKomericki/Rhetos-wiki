# Creating a "playground" console app v4

This instructions are part of tutorial
[Using the Domain Object Model](Using-the-Domain-Object-Model#option-b-creating-a-playground-console-app)

The following steps show now to create a "playground" console app for .NET Framework 4.7.2.

1. In Visual Studio, add a new project to the existing solution with the main Rhetos application:
   * Project template: "Console App (.NET Framework)".
   * Framework: ".NET Framework 4.7.2" (same as your main Rhetos application).
   * If you are creating a Bookstore demo application, set the following:
     * Location: create `test` subfolder in your "Bookstore" project folder (`...\Bookstore\test\`),
     * Name: "Bookstore.Playground"
2. Add a project reference to the main Rhetos application:
   Project => Add reference... => Projects => Check "Bookstore.Service" => OK.
3. Project => Manage NuGet Packages... => Browse => search "ConsoleDump"
   => select the ConsoleDump package => Install => OK.
4. Copy the content of the `Main` method from the `LinqPad\Rhetos Server DOM.linq` script
   into the Main method of your Playground project.
5. Replace the line `string applicationFolder = Path.GetDirectoryName(Util.CurrentQueryPath);`
   with a relative or absolute path to the Rhetos application folder,
   for example `string applicationFolder = @"..\..\..\..\src\Bookstore.Service";`.
6. Fix the compiler errors by adding the suggested "using" statement for each error.
   The resulting using statements should look like this:
    ```C#
    using ConsoleDump;
    using Rhetos;
    using Rhetos.Configuration.Autofac;
    using Rhetos.Dom.DefaultConcepts;
    using Rhetos.Logging;
    using Rhetos.Utilities;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    ```
7. Run the application with **Ctrl+F5**. It should print a few tables and end with "Done.".
8. Troubleshooting:
   * If you get an error `FrameworkException: Cannot find application's configuration (rhetos-app.settings.json) in ...`,
     check how the reported path relates to the `string applicationFolder` line in the Main method
     (see the steps above). Correct the applicationFolder to match the Rhetos application folder.

Notes:

* The examples use the ConsoleDump's method `Dump()` to print the results in a table format.
* For the end result, see the example of the created playground app for the Bookstore demo application
at <https://github.com/Rhetos/Bookstore/tree/rhetos-4/test/Bookstore.Playground>.
