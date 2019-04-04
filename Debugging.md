# Debugging

Like every other framework, Rhetos brings a new level of abstraction in the work of developers,
and therefore it also brings additional complications during debugging.

A good thing is that the Rhetos server doesn't interpret DSL scripts "on the run",
but on the basis of DSL scripts it generates a common C# web service
(source, dll and pdb) and an SQL database.
When we need to debug the generated server application,
we can start Visual Studio and simply debug the Rhetos application like any other application that has been written in C#.
Additionally, we sometimes use LINQPad to [access the server object model](https://github.com/Rhetos/Rhetos/wiki/Using-the-Domain-Object-Model),
this is practical for smaller actions without installing and using Visual Studio.

Besides that, Rhetos has a detailed [logging](Logging#system-log) of all actions it performs,
that is set up by default for logging errors only (because of the performances).
The detail level of the logger is adjusted in the Web.config file.

To be able to step through the code of the generated server application
(ServerDom cs/dll/pdb) in Visual Studio on the ISS,
you will need to make sure that the Visual Studio has loaded the debugging symbols.
Use one of the two options:

* A) Build the ServerDom dlls in *Debug* mode, with `DeployPackages.exe /Debug` switch.
* B) Alternatively, to debug the application in *Release* mode,
  in Visual Studio - Tools - Options turn off the option "Just My Code"
  (that option disables debugging of optimized dll's from the external processes).
