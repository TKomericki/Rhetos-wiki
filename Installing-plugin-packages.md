Rhetos can install a plugin package directly from the online NuGet gallery, or from a local folder (nupkg file extension).

Many Rhetos packages are available at the [NuGet.org](https://www.nuget.org/) public online gallery.
See [Recommended plugin packages](Home#recommended-plugin-packages).

## Installing an additional plugin package to the Rhetos server application

1. To install the additional package to a Rhetos server, add it to the Rhetos server's **RhetosPackages.config** file.
    * For example, to install a package named "Rhetos.AfterDeploy", version 2.0.0, add the `package` line to the *RhetosPackages.config* file. Remove the version attribute to install the latest version.

        ```XML
        <?xml version="1.0" encoding="utf-8"?>
        <packages>
            ...
            <package id="Rhetos.AfterDeploy" version="2.0.0" />
            ...
        ```

2. Make sure the location of the package (a folder or a NuGet web gallery) is listed in the **RhetosPackageSources.config** file.
    * For example, if the package is available at [NuGet.org](https://www.nuget.org/) online gallery, add the following line to the *RhetosPackageSources.config* file.

        ```XML
        <source location="https://www.nuget.org/api/v2/" />
        ```

3. Read the package's **Readme.md** file, to see if there are additional step that need to be done in order to install or configuring the plugin correctly.

4. Run `bin\DeployPackages.exe` to rebuild the Rhetos server application with the new package.
