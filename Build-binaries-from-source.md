# Building the Rhetos server binaries from source

Official releases of Rhetos framework binaries are available on [NuGet online gallery](https://www.nuget.org/)
and [GitHub Rhetos releases](https://github.com/Rhetos/Rhetos/releases):

* Rhetos NuGet package
* Rhetos.CommonConcepts NuGet package
* Rhetos.MSBuild NuGet package
* Rhetos.Wcf NuGet package
* RhetosServer.zip (for older version of Rhetos)

You can build the latest version of the binaries directly from source.

> Note that using the latest version of the source is not recommended for business application development, because of possible compatibility issues with other Rhetos packages that might be resolved only when the new release of the framework and the packages is published.

Steps:

1. Use git to clone the repository <https://github.com/Rhetos/Rhetos.git> to a new source folder on your disk:
    * In the command prompt run `git clone https://github.com/Rhetos/Rhetos.git RhetosSource`
2. Open the command prompt in the created Rhetos source folder and run `Build.bat`. Verify that the last printed line is "Build.bat SUCCESSFULLY COMPLETED".
3. The Rhetos server binaries are created in the subfolder `Install\Rhetos`. Copy the content of `Install\Rhetos` to your application's RhetosServer folder.
