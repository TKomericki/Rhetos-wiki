# Configuration management

This article describes how the Rhetos application is configured in different stages of development
and different project types.

Content:

1. [General notes](#general-notes)
2. [Configuration sources](#configuration-sources)
   1. [Build configuration](#build-configuration)
   2. [Database update configuration](#database-update-configuration)
   3. [Application run-time configuration](#application-run-time-configuration)
3. [Reading configuration with custom options classes](#reading-configuration-with-custom-options-classes)
4. [Configuring application from code](#configuring-application-from-code)
5. [Configuration keys before Rhetos v4.0](#configuration-keys-before-rhetos-v40)

## General notes

1. When there are **multiple configuration sources** specified, the later will extend and override
   configuration from previous sources.
2. Configuration settings are **differently formatted** in .config files and .json files.
   See the same example in both files bellow.
   * In .config files, they are always part of `appSettings` element.
     Keys contain colon or dot as a path separator.
     ```xml
     <appSettings file="ExternalAppSettings.config">
       <add key="CommonConcepts:AutoGeneratePolymorphicProperty" value="False" />
       <add key="CommonConcepts:CascadeDeleteInDatabase" value="False" />
       <add key="SomeOldPlugin.CustomOption" value="SomeText" />
     </appSettings>
     ```
   * In .json files, path for the key is represented by subobjects.
     Boolean and numeric values do not use quotes.
     ```json
     {
       "CommonConcepts": {
          "AutoGeneratePolymorphicProperty": false,
          "CascadeDeleteInDatabase": false
       },
       "SomeOldPlugin": {
         "CustomOption": "SomeText"
       }
     }
     ```
3. **Environment-specific configuration files** contain settings that are specific for a single
   developer/test/production environment.
   They extends or overrides the base configuration (Web.config or rhetos-app.settings.json).
   These files should be optional and excluded from source repository.
   Environment-specific configuration files:
   * *rhetos-app.local.settings.json* (since Rhetos v4.0), see configuration sources below for more details.
   * In Web.config file, the environment-specific configuration files can be explicitly referenced in
     different sections of the configuration. For example, `appSettings` element in the snippet above
     references *ExternalAppSettings.config* file.

## Configuration sources

### Build configuration

See [General notes](#general-notes) above for difference in formatting between .config and .json files.

Default configuration sources for project with **Rhetos.MSBuild / Rhetos CLI**:

1. Rhetos.exe.config (from NuGet packages folder) - Do not edit.
2. **rhetos-build.settings.json** - Recommended for configuring build.

Default configuration sources for project with **DeployPackages**:

1. Web.config (*appSettings* element). Sometimes extended with environment-specific configuration, e.g. *ExternalAppSettings.config*.
2. DeployPackages.exe.config - Do not edit.

Common options classes:

* [BuildOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/BuildOptions.cs)
* [RhetosBuildEnvironment](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/RhetosBuildEnvironment.cs) - Specified by development environment setup. Considered hardcoded during build.
* [IAssetsOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/IAssetsOptions.cs)

### Database update configuration

Default configuration sources for application with **Rhetos.MSBuild / Rhetos CLI**:

1. Web.config (*appSettings* element). Sometimes extended with environment-specific configuration, e.g. *ExternalAppSettings.config*.
2. rhetos-app.settings.json
3. rhetos-app.local.settings.json
4. Overrides *Rhetos:Database:SqlCommandTimeout* option to 0 (unlimited).
5. Rhetos.exe.config (from bin folder) - Do not edit.
6. **rhetos-dbupdate.settings.json** - Recommended for configuring database update.
7. Rhetos CLI switches.

Default configuration sources for application with **DeployPackages**:

1. Web.config (*appSettings* element). Sometimes extended with environment-specific configuration, e.g. *ExternalAppSettings.config*.
2. rhetos-app.settings.json - Since Rhetos v4.0.
3. rhetos-app.local.settings.json - Since Rhetos v4.0.
4. DeployPackages.exe.config - Do not edit.

Common options classes:

* All classes from "Application run-time configuration" are available.
* [DbUpdateOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/DbUpdateOptions.cs)

### Application run-time configuration

See [General notes](#general-notes) above for difference in formatting between .config and .json files.

Default configuration sources for application with **Rhetos.MSBuild / Rhetos CLI**:

1. Web.config (*appSettings* element). Sometimes extended with environment-specific configuration, e.g. *ExternalAppSettings.config*.
2. **rhetos-app.settings.json** - Recommended for general application configuration.
3. **rhetos-app.local.settings.json** - Recommended for developer-specific or environment-specific configuration.

Default configuration sources for application with **DeployPackages**:

1. Web.config (*appSettings* element). Sometimes extended with environment-specific configuration, e.g. *ExternalAppSettings.config*.
2. rhetos-app.settings.json - Since Rhetos v4.0.
3. rhetos-app.local.settings.json - Since Rhetos v4.0.

Common options classes:

* [RhetosAppEnvironment](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/RhetosAppEnvironment.cs)
* [RhetosAppOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/RhetosAppOptions.cs)
* [DatabaseOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/DatabaseOptions.cs)
* [SecurityOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/SecurityOptions.cs)
* [IAssetsOptions](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/IAssetsOptions.cs)

## Reading configuration with custom options classes

Rhetos configuration can be extended with **custom options classes**.
Options class is a POCO class, that provides type-safe alternative to reading configuration
directly from IConfiguration with string key.

* Register custom options class to be resolved from IConfiguration, when building the Dependency Injection container.
  For example, `MyCustomOptions` should be registered with the following code for `ContainerBuilder`:
  ```cs
  builder.Register(context => context.Resolve<IConfiguration>().GetOptions<MyCustomOptions>()).SingleInstance();
  ```
* You may use `OptionsAttribute` to add default configuration path that will be applied
  in GetOptions and AddOptions methods.

## Configuring application from code

`Host.CreateRhetosContainer` and `RhetosRuntime.BuildConfiguration` methods allow extending
and overriding application configuration by using `IConfigurationBuilder` instance.

* Use `IConfigurationBuilder` extension methods (such as `AddKeyValue`, `AddOptions`
  and `AddJsonFile`) to add or override configuration settings.
* Runtime features of the application can access the configuration directly by requesting
  `IConfiguration` instance from dependency injection, but it is preferred to use registered
  options classes instead (see the "Common options classes" in different sections above),
  or register additional custom options classes.

## Configuration keys before Rhetos v4.0

Rhetos framework v4.0 introduced new settings structure and modified configuration keys.
Here is a mapping between old and new options keys.

| Rhetos v1, v2, v3 | Rhetos v4+ |
| -- | -- |
| AssemblyGenerator.ErrorReportLimit | Rhetos:Build:AssemblyGeneratorErrorReportLimit |
| AuthorizationAddUnregisteredPrincipals | Rhetos:App:AuthorizationAddUnregisteredPrincipals |
| AuthorizationCacheExpirationSeconds | Rhetos:App:AuthorizationCacheExpirationSeconds |
| BuiltinAdminOverride | Rhetos:AppSecurity:BuiltinAdminOverride |
| CommonConcepts.Debug.SortConcepts | Rhetos:Build:InitialConceptsSort |
| CommonConcepts.Legacy.AutoGeneratePolymorphicProperty | CommonConcepts:AutoGeneratePolymorphicProperty |
| CommonConcepts.Legacy.CascadeDeleteInDatabase | CommonConcepts:CascadeDeleteInDatabase |
| DataMigration.SkipScriptsWithWrongOrder | Rhetos:DbUpdate:DataMigrationSkipScriptsWithWrongOrder |
| EntityFramework.UseDatabaseNullSemantics | Rhetos:App:EntityFrameworkUseDatabaseNullSemantics |
| Security.AllClaimsForUsers | Rhetos:AppSecurity:AllClaimsForUsers |
| Security.LookupClientHostname | Rhetos:AppSecurity:LookupClientHostname |
| SqlCommandTimeout | Rhetos:Database:SqlCommandTimeout |
| SqlExecuter.MaxJoinedScriptCount | Rhetos:SqlTransactionBatches:MaxJoinedScriptCount |
| SqlExecuter.MaxJoinedScriptSize | Rhetos:SqlTransactionBatches:MaxJoinedScriptSize |
| SqlExecuter.ReportProgressMs | Rhetos:SqlTransactionBatches:ReportProgressMs  |

When running older applications on new Rhetos framework, you can either update the settings keys,
or enable the legacy keys support. For migration instructions, see Breaking changes in
[Release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md#breaking-changes).
