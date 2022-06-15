Rhetos package is a plugin for Rhetos apps that extends features of Rhetos framework.
It is essentially a **NuGet** package that can contain:

* DSL scripts
* Libraries (DLLs) that extend Rhetos framework (DSL language, database update, web API and other)
* Data-migration scripts
* Additional resources

A Rhetos package typically contains some reusable **business** logic or **technology** implementation.
For example, a package can extend DSL language with new keywords for specific business
features, or provide a new web API protocol for existing entities in the application.
A package can also contain a complete business application.

Table of contents:

1. [How to create Rhetos package](#how-to-create-rhetos-package)
2. [Example](#example)
3. [See also](#see-also)

## How to create Rhetos package

Like any other NuGet package, you have to create a
[.nuspec file](https://docs.microsoft.com/en-us/nuget/reference/nuspec) which describes your package.

A package contains files, which are organized into following **folders (targets)**,
based on the file type:

* lib - Binary files (.dll, .pdb). This is a standard NuGet convention. It can contain a subfolder specifying the .NET version.
* DslScripts - Rhetos DSL scripts (.rhe).
* DataMigration - Rhetos [data-migration](Data-migration) scripts (.sql).
* Resources - Additional Rhetos resources used in your application (for example, report templates).
* Other special subfolders can be used for other file types that may be recognized by NuGet or some Rhetos plugin.
  For example, the Rhetos.AfterDeploy package detects any SQL scripts in AfterDeploy folder.

Each of the Rhetos target folders can contain subfolders, to better organize the files and resources.

Package also includes standard NuGet metadata (id, version, author, etc.) and a list of dependencies.

Here is a typical example of .nuspec file:

``` xml
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd">
    <metadata>
        <id>MyRhetosPackage</id>
        <version>1.0.0.0</version>
        <authors>John Smith</authors>
        <owners>My Organization Inc.</owners>
        <description>My First Rhetos Package</description>
        <copyright>My Organization Inc.</copyright>
        <dependencies>
            <dependency id="Rhetos" version="2.0.0" />
            <dependency id="Rhetos.CommonConcepts" version="2.0.0" />
        </dependencies>
    </metadata>
    <files>
        <file src="Readme.md" target="Readme.md" />
        <file src="DataMigration\**\*" target="DataMigration" />
        <file src="DslScripts\**\*" target="DslScripts" />
        <file src="Resources\**\*" target="Resources" />
        <file src="MyRhetosPlugin\bin\Debug\MyRhetosPlugin.dll" target="lib\net472" />
        <file src="MyRhetosPlugin\bin\Debug\MyRhetosPlugin.pdb" target="lib\net472" />
    </files>
</package>
```

Remove from this .nuspec file any files/src folders that you are not using in your plugin or application.

## Example

For a nuspec file that contains a complete Rhetos application,
see the [Bookstore](https://github.com/Rhetos/Bookstore) example,
file `src/Bookstore.nuspec`.

## See also

* [Installing plugin packages](Installing-plugin-packages)
