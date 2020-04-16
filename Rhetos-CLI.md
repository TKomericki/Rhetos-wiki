# Rhetos CLI

Contents:

1. [Features](#features)
2. [MSBuild integration with Rhetos.MSBuild NuGet package](#msbuild-integration-with-rhetosmsbuild-nuget-package)
3. [Build and dbupdate configuration settings](#build-and-dbupdate-configuration-settings)
4. [See also](#see-also)

## Features

Commands:

* `build` command generates C# code, database model file and other assets.
* `dbupdate` command updates the database structure and initializes the application data in the database.

CLI switches:

* See command-line help for information on arguments and options.
  You can execute this in Command Prompt or Package Manager Console in Visual Studio.
  * `rhetos --help`
  * `rhetos build --help`
  * `rhetos dbupdate --help`
* See [System.CommandLine](https://github.com/dotnet/command-line-api/wiki/Features-overview) features for additional debugging switches.

During application development, rhetos.exe is usually **executed automatically** by MSBuild
(for example when building the application in Visual Studio),
if the project includes NuGet package Rhetos.MSBuild.
It can also be executed manually from command prompt,
for example to update the database on deployment.

Rhetos.exe is a successor to DeployPackages.exe. Main design differences in rhetos.exe are:

* Separated commands for build and deploy.
* It does not download NuGet packages. They are managed by MSBuild and Visual Studio.
* It does not build the application's DLL files. It generates source code as part of
  the current project, that will be compiled with MSBuild.
* It allows custom source code to be developed and compiled side-by-side with generated
  C# source code in the same Rhetos application.

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

## Build and dbupdate configuration settings

Each Rhetos CLI command reads configuration from different configuration files,
see [Configuration management](Configuration-management) for details.

## See also

* [Creating a new Rhetos application with Rhetos.MSBuild](Creating-new-WCF-Rhetos-application.md)
* [Migrating from DeployPackages to Rhetos.MSBuild with Rhetos CLI](Migrating-from-DeployPackages-to-Rhetos-CLI).
b