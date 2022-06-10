# Creating a "playground" console app

This instructions are part of tutorial
[Using the Domain Object Model](Using-the-Domain-Object-Model#option-b-creating-a-playground-console-app)

The following steps show now to create a "playground" console app for .NET 6.

1. In Visual Studio, in the same solution with the existing Rhetos application (Bookstore.Service),
    add a "Console App" C# project, named "Bookstore.Playground" located in the "Bookstore\test" subfolder,
    with .NET 6 framework.
2. Add a project reference to the main Rhetos application:
   Project => Add Project Reference... => Check "Bookstore.Service" => OK.
3. Project => Manage NuGet Packages... => Browse => search "ConsoleDump"
   => select the ConsoleDump package => Install => OK.
4. Copy the content of the `Main` method from the `Bookstore.Service\bin\Debug\net6.0\LinqPad\Rhetos DOM.linq` script
   into the Program.cs file of Bookstore.Playground project.
5. Fix the compiler errors by adding the suggested "using" statement for each error.
   The resulting using statements should look like this:
   ```cs
   using ConsoleDump;
   using Rhetos;
   using Rhetos.Dom.DefaultConcepts;
   using Rhetos.Logging;
   using Rhetos.Utilities;
   ```
6. Replace the line `string rhetosHostAssemblyPath = ...`
   with a relative or absolute path to the Rhetos application assembly,
   for example:
   ```cs
   string rhetosHostAssemblyPath = @"..\..\..\..\..\src\Bookstore.Service\bin\Debug\net6.0\Bookstore.Service.dll";
   ```
   For Rhetos v4, the path should reference the Bookstore.Service project folder, instead of the assembly in bin folder.
7. Set Bookstore.Playground as startup project (Project => Set as Startup Project),
   and run the application with **Ctrl+F5**. It should print a few tables and end with "Done.".
8. Troubleshooting:
   * If you get an error `ArgumentException: Please specify the host application assembly file. File '...' does not exist.`,
     check how the reported path relates to the `string rhetosHostAssemblyPath` line in the Main method
     (see the steps above). Correct the rhetosHostAssemblyPath to match the Rhetos application folder.

Notes:

* The examples use the ConsoleDump's method `Dump()` to print the results in a table format.
* An example of a similar playground app (for .NET 5) is part of the Bookstore demo application
  at <https://github.com/Rhetos/Bookstore/tree/master/test/Bookstore.Playground>.
