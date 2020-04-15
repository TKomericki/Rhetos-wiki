# Rhetos CLI

Contents:

1. [Features](#features)
2. [MSBuild integration with Rhetos.MSBuild NuGet package](#msbuild-integration-with-rhetosmsbuild-nuget-package)
3. [Build and database configuration settings](#build-and-database-configuration-settings)
4. [See also](#see-also)

## Features

Commands:

* `build` command generates C# code, database model file and other assets.
* `dbupdate` command updates the database structure and initializes the application data in the database.

CLI switches:

* `rhetos --help`
* `rhetos build --help`
* <https://github.com/dotnet/command-line-api/wiki/Features-overview#Suggestions>

## MSBuild integration with Rhetos.MSBuild NuGet package

**Rhetos.MSBuild** NuGet package automatically adds Rhetos CLI to the project, and
executes rhetos.exe on build.

Inside .csproj file you can add the following group of properties to configure automatic
Rhetos build and database update on each build.

```xml
  <PropertyGroup>
    <RhetosBuild>true</RhetosBuild>
    <RhetosDeploy>true</RhetosDeploy>
  </PropertyGroup>
```

* RhetosBuild - Generate C# source from DSL scripts, and executes other file generators.
* RhetosDeploy - Update database and initialized application data in database.

Note that each of the Rhetos commands might not run if there are no changes in source detected.

For large projects, it is recommended to turn off automatic database update on each build,
and run it manually from console when testing the application with `rhetos.exe dbupdate`
(the exe is located in bin folder).

## Build and database configuration settings

Each Rhetos CLI command reads configuration from different configuration files,
see [Configuration management](Configuration-management) for details.

## See also

* Rhetos.exe is a successor to DeployPackages.exe, see the comparison in article
  [Migrating from DeployPackages to Rhetos.MSBuild with Rhetos CLI](Migrating-from-DeployPackages-to-Rhetos-CLI).
