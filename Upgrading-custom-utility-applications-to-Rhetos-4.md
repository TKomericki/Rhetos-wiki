# Upgrading custom utility applications to Rhetos 4.0

Rhetos has migrated to new configuration and DI container initialization design.
Changes are not fully backward-compatible, so some of the existing code may stop working.

Mostly, these changes will affect any kind of **tools/executables** which are custom entry points
to running Rhetos. Code that initializes Rhetos container or sets up options will be affected.
Expected errors are:

* `System.MissingMethodException: Method not found: 'Void Rhetos.Utilities.Paths.InitializeRhetosServerRootPath(System.String)'`
* `System.MissingMethodException: Method not found: 'Void Rhetos.Extensibility.Plugins.SetInitializationLogging(Rhetos.Logging.ILogProvider)'`

Here are described some common scenarios of **upgrade to Rhetos 4.0**,
for different types of custom utility applications:

Contents:

1. [Custom code that utilizes Rhetos static utilities, but DOES NOT construct Rhetos container](#custom-code-that-utilizes-rhetos-static-utilities-but-does-not-construct-rhetos-container)
2. [Custom code that constructs and uses Rhetos DI container to interact with Rhetos application](#custom-code-that-constructs-and-uses-rhetos-di-container-to-interact-with-rhetos-application)
3. [Custom code that uses RhetosTestContainer](#custom-code-that-uses-rhetostestcontainer)

## Custom code that utilizes Rhetos static utilities, but DOES NOT construct Rhetos container

Often there will be some form of initialization (at least for Rhetos app root path) in form of:

```cs
Paths.InitializeRhetosServerRootPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\.."));
```

This needs to be replaced with creation of configuration object.
Configuration is then used to initialize all legacy static classes.

```cs
var host = Host.Find(AppDomain.CurrentDomain.BaseDirectory, new ConsoleLogProvider());
var configuration = host.RhetosRuntime.BuildConfiguration(new ConsoleLogProvider(), host.ConfigurationFolder,
    configurationBuilder => configurationBuilder.AddConfigurationManagerConfiguration());
LegacyUtilities.Initialize(configuration);
```

Notes:

* The `Host.Find` method locates the Rhetos application in specified folder or any parent folder.
  The example above uses `AppDomain.CurrentDomain.BaseDirectory`, assuming that
  the utility application is located **within the Rhetos application**.
  If that is not the case, specify the path to Rhetos application.
* The `configuration` includes configuration settings of main Rhetos application
  (typically from *Web.config*), but the `BuildConfiguration` method allows adding
  or overriding configuration settings in code.
  * `AddConfigurationManagerConfiguration` includes current application's standard configuration,
    that can override main application's configuration when needed (for example to specify
    a custom SQL command timeout value in the utility's config file).

## Custom code that constructs and uses Rhetos DI container to interact with Rhetos application

This scenario will commonly use some form of default Rhetos DI container, for example:

```cs
Paths.InitializeRhetosServerRootPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\.."));

Plugins.SetInitializationLogging(new ConsoleLogProvider());
ConsoleLogger.MinLevel = EventType.Info;

var builder = new ContainerBuilder();
    builder.RegisterModule(new DefaultAutofacConfiguration(deploymentTime: false, deployDatabaseOnly: false));

builder.RegisterType<ProcessUserInfo>().As<IUserInfo>();
builder.RegisterType<ConsoleLogProvider>().As<ILogProvider>();

var container = builder.Build();
```

This should be replaced with the following code:

```cs
var processContainer = new ProcessContainer(
  addCustomConfiguration: configurationBuilder => configurationBuilder.AddConfigurationManagerConfiguration());

using (var container = processContainer.CreateTransactionScopeContainer())
{
  // Add your application code here.

  container.CommitChanges();
}
```

Notes:

* If the utility application is **not located** within the main Rhetos application (or any subfolder),
  then add `applicationFolder` parameter with path to the main application.
* The `ProcessContainer` parameters `addCustomConfiguration` and `registerCustomComponents`
  allow extending and overriding configuration setting and custom DI components registration.
  * `AddConfigurationManagerConfiguration` includes current application's standard configuration,
    that can override main application's configuration when needed
    (for example to specify a custom SQL command timeout value in utility's config file).
* In this scenario, note that we are not explicitly initializing legacy static utilities
  via `LegacyUtilities.Initialize()`. This is implicitly called in `ProcessContainer`
  to simplify the migration.

## Custom code that uses RhetosTestContainer

`RhetosTestContainer` class has been modified internally to comply with new design and using it
is **backward-compatible**, so the existing code does not need to be changed.

Optionally, migrate your utilities and tests to use the new `ProcessContainer`,
instead of `RhetosTestContainer`, for improved error handling.

* Command-line utilities can use the `ProcessContainer` from the example in the section above.
* Unit tests should reuse a single static instance of `ProcessContainer`, to avoid running
  initialization code for each test (Entity Framework startup and plugin discovery).
  See the examples in Bookstore application:
  [BookstoreContainer](https://github.com/Rhetos/Bookstore/blob/ad7a1dddb99c266cb12a1a7d496bc8129464dc76/test/Bookstore.Service.Test/Tools/BookstoreContainer.cs)
  is helper class that initializes `ProcessContainer` and is used by
  [unit tests](https://github.com/Rhetos/Bookstore/blob/ad7a1dddb99c266cb12a1a7d496bc8129464dc76/test/Bookstore.Service.Test/BookTest.cs).
