Rhetos is plugin based platform, therefore the Rhetos package
is fundamental part of development on Rhetos platform.
Rhetos package is the only way to publish your application on the Rhetos server.

Table of contents:

1. [What is Rhetos package](#what-is-rhetos-package)
2. [How to create Rhetos package](#how-to-create-rhetos-package)
3. [Folder structure of your Rhetos package source](#folder-structure-of-your-rhetos-package-source)
4. [Example](#example)
5. [See also](#see-also)

## What is Rhetos package

Rhetos package is a plugin for Rhetos platform.
It is essentially a special type of NuGet package that Rhetos platform can recognize and absorb your application.
It can contain:

* DSL scripts
* binary Rhetos plugins
* data migration scripts
* additional resources

## How to create Rhetos package

Rhetos package being a special type of NuGet package,
you have to create a nuspec file which describes your package.
Rhetos platform supports four type of files that can be deployed.
Accordingly, NuGet package is organized in four targets
that contains your application:

* DslScripts - target for all the .rhe files
* DataMigration - target for all the sql data migration scripts
* Resources - target for all additional resources used in your application (.eg report templates)
* lib\net451 - target for all the binaries(.dll, .pdb)

Like any other NuGet package, package can include standard metadata
for the package (id, version, author, etc.) and list of dependencies.
All of the mentioned targets can be populated by subfolders
for better separation of the code and the resources.

Here is the example of nuspec file for a Rhetos package:

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
            <dependency id="Rhetos" version="1.2.1" />
            <dependency id="Rhetos.CommonConcepts" version="1.2.0" />
        </dependencies>
    </metadata>
    <files>
        <file src="DataMigration\**\*" target="DataMigration" />
        <file src="DslScripts\**\*" target="DslScripts" />
        <file src="Resources\**\*" target="Resources" />
        <file src="MyRhetosPlugin\bin\Debug\MyRhetosPlugin.dll " target="lib\net451" />
        <file src="MyRhetosPlugin\bin\Debug\MyRhetosPlugin.pdb " target="lib\net451" />
    </files>
</package>
```

Remove from this nuspec file any files/src folders that you are not using in you application.

## Folder structure of your Rhetos package source

Following the Rhetos package structure, the best practice for folder structure looks like this:

```Text
MyRhetosPackage
    DslScripts
    DataMigration
    Resources
    MyRhetosPlugin
        MyRhetosPlugin.csproj
    MyRhetosPackage.nuspec
```

## Example

For a complete Rhetos applications see the [Bookstore](https://github.com/Rhetos/Bookstore) example.
Its `src` folder has the source structure as described above,
with the nuspec file and the corresponding subfolders.

## See also

* [Installing plugin packages](Installing-plugin-packages)
