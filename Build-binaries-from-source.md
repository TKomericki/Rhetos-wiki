# Building the Rhetos framework binaries from source

Official releases of Rhetos framework binaries are available on
[NuGet online gallery](https://www.nuget.org/packages?q=rhetos)
and [GitHub Rhetos releases](https://github.com/Rhetos/Rhetos/releases).

You can build the latest version of the binaries directly from source.

> Note that using the latest version of the source is not recommended for business application development,
  because of possible compatibility issues with other Rhetos packages that
  might be resolved only when the new release of the framework and the packages is published.

Steps:

1. Use git to clone the repository <https://github.com/Rhetos/Rhetos.git> to a new source folder on your disk:
   * In the command prompt run `git clone https://github.com/Rhetos/Rhetos.git Rhetos`
2. Open the command prompt in the created Rhetos source folder and run `Build.bat`.
   Verify that the last printed line is "Build.bat SUCCESSFULLY COMPLETED".
3. The Rhetos framework binaries are created in the subfolder `Install`.
