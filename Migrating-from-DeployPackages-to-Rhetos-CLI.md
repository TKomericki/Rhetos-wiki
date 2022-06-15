# Migrating from DeployPackages to Rhetos.MSBuild with Rhetos CLI v4

This article contains step-by-step instruction for migrating an existing **Rhetos application** or **Rhetos plugin package**
from old build and deployment process (with DeployPackages) to the new one (Rhetos.MSBuild with Rhetos CLI),
available since Rhetos 4.0.

See [Rhetos CLI Features](Rhetos-CLI#features) for overview of rhetos.exe
and comparison to old utility **DeployPackages.exe**.

Content:

1. [Upgrade your application to Rhetos v4.0 while still using DeployPackages](#upgrade-your-application-to-rhetos-v40-while-still-using-deploypackages)
2. [Create new Rhetos application in Visual Studio](#create-new-rhetos-application-in-visual-studio)
3. [Apply the required changes to your existing code](#apply-the-required-changes-to-your-existing-code)
   1. [NuGet packages must contain DLLs in "lib" instead of "Plugins"](#nuget-packages-must-contain-dlls-in-lib-instead-of-plugins)
   2. [Generated application folder structure is different](#generated-application-folder-structure-is-different)
   3. [Build options are not read from Web.config file](#build-options-are-not-read-from-webconfig-file)
   4. [The "Resources" folder usage](#the-resources-folder-usage)
   5. [Custom usage of AssemblyGenerator](#custom-usage-of-assemblygenerator)
4. [See also](#see-also)

## Upgrade your application to Rhetos v4.0 while still using DeployPackages

Before migrating an existing application to Rhetos CLI, first
upgrade your application to Rhetos v4.0 **while still using DeployPackages**,
and test that it works correctly.

* The upgrade instructions are in "Breaking changes" section
  in [Rhetos release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md).
* Also update the referenced Rhetos plugins packages to the latest version,
  to make sure they are compatible with Rhetos 4.0.

## Create new Rhetos application in Visual Studio

Earlier Rhetos apps that use DeployPackages were created by unpacking RhetosServer.zip installation
file, which contained the web application. This installation method is no longer used.

To migrate your existing project from DeployPackages to Rhetos CLI,
**backup** the old Rhetos application and **create the new Rhetos web application** from scratch
in Visual Studio:

1. Following the instructions from [Creating a new WCF application with Rhetos framework](Creating-new-WCF-Rhetos-application).
2. Add all NuGet packages to the project, that were used by the old Rhetos application.
   * You can find the list of packages in *RhetosPackages.config* file,
     or your application's *.nuspec* file (under "dependencies").
   * Use the latest version of Rhetos NuGet packages,
     to make sure they are compatible with Rhetos CLI.
   * If you were using any custom NuGet source in *RhetosPackageSources.config* (e.g. network
     folders or private NuGet galleries), make sure to **add the custom package source** in
     [Visual Studio settings](https://docs.microsoft.com/en-us/nuget/consume-packages/install-use-packages-visual-studio#package-sources).
3. Move your DSL scripts into DslScripts subfolder in that application, and add them to the project
   in Visual Studio to see them in Solution Explorer.
4. For large projects, it is recommended to turn off automatic database update on each build,
   and run it manually from console when testing the application with `rhetos.exe dbupdate`
   (the exe is located in bin folder).
   * To turn off automatic database update add the following XML element in the .csproj file,
     inside the `Project` element. **Close** Visual Studio before editing.
     ```xml
       <PropertyGroup>
         <RhetosBuild>true</RhetosBuild>
         <RhetosDeploy>false</RhetosDeploy>
       </PropertyGroup>
     ```
5. Copy appSettings and system configuration from old Web.config file.
   Review differences between new and old Web.config.

## Apply the required changes to your existing code

### NuGet packages must contain DLLs in "lib" instead of "Plugins"

Rhetos NuGet packages with DLLs in "Plugins" folder are not supported by Rhetos CLI.
The warning will be reported on build if any package contains DLLs in Plugins folder,
but the build might also fail with `Unknown DSL keyword` error because of the missing
libraries from Plugins folder.

1. To update your Rhetos plugin package, in .nuspec files **replace** `target="Plugins"`
   with `target="lib"`, to match the standard NuGet convention.

### Generated application folder structure is different

1. Review and **update any hardcoded paths** in the existing code or scripts.
   Here is the mapping from old folders to new ones:
   * bin => bin
   * bin\Plugins => bin
   * bin\Generated:
     * assets files => bin\RhetosAssets
     * generated source => bin\DebugSource (different file names, separated by modules)
     * generated binaries are now part of the generated application's DLL file
     * Note that at build-time, the generated source is compiled from obj\Rhetos\Source,
       and assets are generated in obj\Rhetos\RhetosAssets.
   * Resources => Resources
2. Most notable difference is that some plugin packages that generated custom assets
   files in `bin\Generated` folder (such as **MvcModelGenerator**) will now generate
   the files in `bin\RhetosAssets`.
   * **Modify** your build scripts and project files to look for generated assets
     in `bin\RhetosAssets` instead of `bin\Generated`.
3. Code that used legacy `Paths` class will still work (it will point to new folders),
   but we recommend to modify it to use the new classes from dependency injection instead:
   RhetosAppOptions, RhetosAppEnvironment, RhetosBuildEnvironment and IAssetsOptions.

### Build options are not read from Web.config file

For applications built with Rhetos CLI, *Web.config* file (`appSettings` element) can contain
only configuration settings for run-time environment and database update.
Build configuration must be moved from *Web.config* to *rhetos-build.settings.json* file.

1. **Remove** the following **3 settings** from Web.config `appSettings` element.
    ```xml
    <appSettings>
      <add key="InitialConceptsSort" value="Key" />
      <add key="CommonConcepts.Legacy.AutoGeneratePolymorphicProperty" value="False" />
      <add key="CommonConcepts.Legacy.CascadeDeleteInDatabase" value="False" />
    </appSettings>
    ```
    or
    ```xml
    <appSettings>
      <add key="Rhetos:Build:InitialConceptsSort" value="Key" />
      <add key="CommonConcepts:AutoGeneratePolymorphicProperty" value="False" />
      <add key="CommonConcepts:CascadeDeleteInDatabase" value="False" />
    </appSettings>
    ```
2. Place them in *rhetos-build.settings.json* file, located in the project root folder
   (with the .csproj file). Make sure to **replace these values** with your old ones,
   or **remove** the settings if they were not configured in *Web.config*.
    ```json
    {
      "Rhetos": {
        "Build": {
          "InitialConceptsSort": "Key"
        }
      },
      "CommonConcepts": {
        "AutoGeneratePolymorphicProperty": false,
        "CascadeDeleteInDatabase": false
      }
    }
    ```
3. You can **keep the other** `appSettings` options in *Web.config*, or move them to a separate
   run-time configuration file *rhetos-app.settings.json* (not *rhetos-build.settings.json*!).
   * Note that there is also *rhetos-app.local.settings.json* file available for user-specific
     runtime configuration that should not be added to source repository or shared
     between environments.

### The "Resources" folder usage

1. Rhetos will not generated this folder by default.
   * For existing applications and plugins to work, **enable** "Resources" folder
     in `rhetos-build.settings.json` file with `"BuildResourcesFolder": true`,
     if not enabled already.
2. If your application's old nuspec file contained assets files in Resources folder,
   you can no longer keep this file in same location with the new Visual Studio project,
   because Rhetos will generate the Resources folder from NuGet packages on each build.
   * If the files must be in this location for the application to work,
     **create** a new NuGet package with these files in the Resources folder,
     and reference that package from this project.
   * **Move** "TextReplacements.xml" from Resources to root project folder.

### Custom usage of AssemblyGenerator

1. If your application or plugin package directly uses `IAssemblyGenerator`
   to generate files for other applications (client helpers, for example), not for the main
   application, then **add** an empty `manifestResources` parameter to make sure that
   these files are generated as custom assets, and not as part of the new application runtime.
   * If the embedded resources parameter is provided (even if empty), it will generate
     source files and compile library (DLL) in `bin\RhetosAssets` folders instead of
     `bin\Generated`. These files are consider as custom assets,
     not as an executable part of the main application runtime.
   * If the embedded resources are not provided, it will generate source files only (C#)
     as part of the main application. These files will be compiled into the main Rhetos
     application and used at runtime.

## See also

* [Rhetos CLI](Rhetos-CLI).
* [Upgrading custom utility applications to Rhetos 4.0](Upgrading-custom-utility-applications-to-Rhetos-4).
