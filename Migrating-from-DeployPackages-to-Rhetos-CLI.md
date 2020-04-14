# Migrating from DeployPackages to Rhetos CLI

## Breaking changes

* Some plugin packages that generated custom assets files in `.\bin\Generated` folder (such as **MvcModelGenerator**) will now generate the files in `.\RhetosAssets`.
* Rhetos NuGet packages with DLLs in "Plugins" folder are not supported by Rhetos CLI. The warning will be reported on build if any package contains DLLs in Plugins folder, but the build might also fail with `Unknown DSL keyword` error because of the missing libraries from Plugins folder.
  * To update your Rhetos plugin, in .nuspec files **replace** `target="Plugins"` with `target="lib"`, to match the standard NuGet convention.
* Generated application folder structure is different.
  Code that used legacy Paths class will still work (it will point to new folders),
  but we recommend to use new classes instead (RhetosAppEnvironment, RhetosBuildEnvironment or IAssetsOptions).
  * .\bin => .\bin
  * .\bin\Plugins => .\bin
  * .\bin\Generated:
    * assets files => .\bin\RhetosAssets
    * generated source => .\bin\DebugSource (different file names, separated by modules)
    * generated binaries are now part of generated application => .\bin
    * Note that at build-time, the generated source is compiled from .\obj\Rhetos\RhetosSource, and assets are generated in .\obj\Rhetos\RhetosAssets.
  * .\Resources => .\Resources (unless _buildOptions.UseLegacyResourcesFolder is false)
* Custom usage of AssemblyGenerator: When using Rhetos CLI build, generated assemblies with embedded resources will be interpreted as assets instead of parts of the generated application. Such assemblies were not supported by `rhetos build` command, and this feature will allow backward-compatible usage of some old plugin packages such as MvcModelGenerator.
