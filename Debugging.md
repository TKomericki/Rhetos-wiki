#Debugging

Like every other framework, Rhetos brings a new level of abstraction in the work of developers, but it also brings additional complications during debugging.

A good thing is that the Rhetos server doesn't interpret DSL scripts "on the run", but on the basis of DSL scripts it generates the most common C# web service (source, dll and pdb) and a SQL database. When we need to debug a server side application, we can start Visual Studio and simply debug the Rhetos application like any other application that has been written in C#. Additionally, we sometimes use LinqPad to access the server object model, this is practical for smaller actions without installing and using Visual Studio.

Besides that, Rhetos has a detailed logging of all actions he performs, that is set up by default for logging errors only(because of the performances). The detail level of the logger is adjusted in the Web.config file.

To be able to step through the code from the generated server object model(ServerDom.cs/dll/pdb) in Visual Studio on the ISS, in Tools-Options it is required that you turn off the option "Just My Code"(that option disables debugging of optimized dll's from the external procesess).
