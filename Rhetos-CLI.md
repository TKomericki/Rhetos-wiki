# Rhetos CLI

This article describes features and usage of **rhetos.exe** command-line utility.

Contents:

1. [Features](#features)
2. [CLI arguments and switches](#cli-arguments-and-switches)
3. [MSBuild integration with Rhetos.MSBuild NuGet package](#msbuild-integration-with-rhetosmsbuild-nuget-package)
4. [Build and dbupdate configuration settings](#build-and-dbupdate-configuration-settings)
5. [See also](#see-also)

## Features

Commands:

* `build` - Generates C# code, database model file and other project assets.
  * Inputs for the build command are DSL scripts and libraries that contain DSL language
    extensions, code generators and other Rhetos plugins (usually from NuGet packages).
* `dbupdate` - Updates the database structure and initializes the application data in the database.
  * Inputs for dbupdate command are assets files and libraries that are part of the generated
    application. They include database structure model and different kinds of data-initialization code.

During application development, rhetos.exe is usually **executed automatically** by MSBuild
(for example when building the application in Visual Studio),
if the project includes NuGet package Rhetos.MSBuild.

* It can also be executed manually from **Command Prompt**, for example to update the database on deployment.
* From Visual Studio, you can execute rhetos.exe directly in **Package Manager Console**.

Rhetos.exe is a successor to DeployPackages.exe. Main design differences in rhetos.exe are:

* Separated commands for build and deploy.
* It does not download NuGet packages. They are managed by MSBuild and Visual Studio.
* It does not build the application's DLL files. It generates source code as part of
  the current project, that will be compiled with MSBuild.
* It allows custom source code to be developed and compiled side-by-side with generated
  C# source code in the same project.

## CLI arguments and switches

Generic switches:

* To see command-line help for information on arguments and options:
  * `rhetos --help`, `rhetos build --help`, `rhetos dbupdate --help`
* See [System.CommandLine](https://github.com/dotnet/command-line-api/wiki/Features-overview)
  features for additional debugging switches.

Build command:

* Generates C# code, database model file and other project assets.
* Usage:
  * `rhetos build [options] [<project-root-folder>]`
* Arguments:
  * `<project-root-folder>` Project folder where csproj file is located. If not specified, current working directory is used by default.
* Options:
  * `--msbuild-format` Adjust error output format for MSBuild integration.

Database update command:

* Updates the database structure and initializes the application data in the database.
* Usage:
  * `rhetos dbupdate [options] [<application-folder>]`
* Arguments:
  * `<application-folder>` If not specified, it will search for the application at rhetos.exe location and parent directories.
* Options:
  * `--short-transactions` Commit transaction after creating or dropping each database object.
  * `--skip-recompute` Skip automatic update of computed data with KeepSynchronized. See output log for data that needs updating.

## MSBuild integration with Rhetos.MSBuild NuGet package

**Rhetos.MSBuild** NuGet package automatically adds Rhetos CLI to the project, and
executes rhetos.exe on build.

* If there are any build errors or warning, you can **review detailed output** of rhetos.exe
  build and dbupdate commands in Visual Studio inside Output window (View => Output),
  by selecting Show output from: Build.
* You can automatically show this windows on each build in Visual Studio => Tools => Options
  => Projects and Solutions => General => Enable: Show Output window when build starts.

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

Instead of modifying .csproj file, these properties can be provided from command-line
as MSBuild arguments.
For example: `MSBuild.exe MyRhetosApp.sln /p:RhetosDeploy=False`

Note that each of the Rhetos commands might not run if there are no changes in source detected.

For large projects, it is recommended to turn off **automatic database update** on each build,
and run it manually from console before testing the application.
To manually update database execute `rhetos.exe dbupdate` (the exe is located in bin folder).

## Build and dbupdate configuration settings

Each Rhetos CLI command reads configuration from different configuration files,
see [Configuration management](Configuration-management) for details.

## See also

* [Creating a new WCF application with Rhetos framework](Creating-new-WCF-Rhetos-application)
* [Migrating from DeployPackages to Rhetos.MSBuild with Rhetos CLI](Migrating-from-DeployPackages-to-Rhetos-CLI).
