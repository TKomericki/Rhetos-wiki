# Configuration management

This article describes how the Rhetos application is configured in different stages of development
and different project types.

Content:

1. [General notes](#general-notes)
2. [Build configuration](#build-configuration)
3. [Database update configuration](#database-update-configuration)
4. [Application run-time configuration](#application-run-time-configuration)
5. [Configuring application from code](#configuring-application-from-code)

## General notes

1. When there are **multiple configuration sources** specified, the later will extend and override configuration from previous sources.
2. Configuration settings are **differently formatted** in .config files and .json files. See the same example in both files bellow.
   * In .config files, they are always part of `appSettings` element. Keys contain dot as a path separator.
     ```xml
     <appSettings file="ExternalAppSettings.config">
       <add key="CommonConcepts.Legacy.AutoGeneratePolymorphicProperty" value="False" />
       <add key="CommonConcepts.Legacy.CascadeDeleteInDatabase" value="False" />
       <add key="Dsl.InitialConceptsSort" value="Key" />
     </appSettings>
     ```
   * In .json files, path for the key is represented by subobjects. Boolean and numeric values do not use quotes.
     ```json
     {
       "CommonConcepts": {
         "Legacy": {
           "AutoGeneratePolymorphicProperty": false,
           "CascadeDeleteInDatabase": false
         }
       },
       "Dsl": {
         "InitialConceptsSort": "Key"
       }
     }
     ```

## Build configuration

Default configuration sources for project with **DeployPackages**:

1. *Web.config* (*appSettings* element)
2. Often extended with configuration in *ExternalAppSettings.config* (only if explicitly specified in *Web.config*).
3. *DeployPackages.exe.config*.

Default configuration sources for project with **Rhetos.MSBuild / Rhetos CLI**:

1. Rhetos.exe.config (from NuGet packages folder) - Do not edit.
2. **rhetos-build.settings.json** - Recommended for configuring build.

See [General notes](#general-notes) above for difference in formatting between .config and .json files.

Common options classes:

* [BuildOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/BuildOptions.cs)
* [RhetosBuildEnvironment](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/RhetosBuildEnvironment.cs) - Specified by development environment setup. Considered hardcoded during build.
* [IAssetsOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/IAssetsOptions.cs)

## Database update configuration

Default configuration sources for application with **DeployPackages**:

1. *Web.config* (*appSettings* element)
2. Often extended with configuration in *ExternalAppSettings.config* (only if explicitly specified in *Web.config*).
3. *DeployPackages.exe.config*.

Default configuration sources for application with **Rhetos.MSBuild / Rhetos CLI**:

1. Web.config
2. Rhetos.exe.config (from bin folder) - Do not edit.
3. rhetos-app.settings.json
4. rhetos-app.local.settings.json
5. Overrides *SqlCommandTimeout* to 0 (unlimited).
6. **rhetos-dbupdate.settings.json** - Recommended for configuring database update.
7. Rhetos CLI switches.

Common options classes:

* All classes from "Application run-time configuration" are available.
* [DbUpdateOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/DbUpdateOptions.cs)

## Application run-time configuration

Default configuration sources for application with **DeployPackages**:

1. *Web.config* (*appSettings* element)
2. Often extended with configuration in *ExternalAppSettings.config* (only if explicitly specified in *Web.config*).

Default configuration sources for application with **Rhetos.MSBuild / Rhetos CLI**:

1. Web.config
2. **rhetos-app.settings.json** - Recommended for general application configuration.
3. **rhetos-app.local.settings.json** - Recommended for developer-specific or environment-specific configuration.

See [General notes](#general-notes) above for difference in formatting between .config and .json files.

Common options classes:

* [RhetosAppEnvironment](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/RhetosAppEnvironment.cs) - Specified by build configuration. Considered hardcoded during run-time.
* [RhetosAppOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/RhetosAppOptions.cs)
* [DatabaseOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/DatabaseOptions.cs)
* [SecurityOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/SecurityOptions.cs)
* [IAssetsOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/IAssetsOptions.cs)

## Configuring application from code

`Host.CreateRhetosContainer` and `RhetosRuntime.BuildConfiguration` methods allow extending
and overriding application configuration by using `IConfigurationBuilder` instance.

* Use `IConfigurationBuilder` extension methods (such as `AddKeyValue`, `AddOptions`
  and `AddJsonFile`) to add or override configuration settings.
* Runtime features of the application can access the configuration directly by requesting
  `IConfiguration` instance from dependency injection, but it is preferred to use registered
  options classes instead (see the "Common options classes" in different sections above),
  or register additional custom options classes.

Rhetos configuration can be extended with **custom options classes**:

* Register new options class to DI when building DI container with `ContainerBuilder` available
  at `Host.CreateRhetosContainer`, `RhetosRuntime.BuildContainer` or `RhetosTestContainer.InitializeSession`.
  For example MyCustomOptions should be registered with the following code:
  `builder.Register(context => context.Resolve<IConfiguration>().GetOptions<MyCustomOptions>()).SingleInstance();`
* You may use `OptionsAttribute` to add default configuration path that will be applied
  in GetOptions and AddOptions methods.
