# How to upgrade your application to a new version of Rhetos

## Preparation

Check Rhetos [release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md)
for all versions between you current version and the new one.
Look if there are any **"Breaking changes"** sections for those versions:
they will describe everything that you will need to change in your application
*after* upgrading to the new version of Rhetos framework.

## Upgrade to new version of Rhetos framework

Check if your project's build script has this step automated.
For example see the "Install-RhetosServer" line in
<https://github.com/Rhetos/Bookstore/blob/master/Build.ps1>,
it includes the Rhetos framework version number
and automatically updates the framework if changed.
**Skip the steps** from this sections, if this is automated in your project.

Steps:

1. Back-up your RhetosServer folder.
2. Delete everything in your RhetosServer folder except:
   * .config files in root
   * bin\ConnectionStrings.config
   * Log subfolder
   * any additional custom files that you have added (LINQPad scripts, for example).
3. Download the new *RhetosServer.x.x.x.zip* file from the
   [latest release](https://github.com/Rhetos/Rhetos/releases) (not the source code).
4. Unpack the zip to the RhetosServer folder.
5. Keep your old Web.config file, instead of using the new one from the zip.
   This will ensure that your application works in backward compatible mode.

## Upgrade to new version of Rhetos packages

What to upgrade:

* Your application should use the same version of Rhetos.CommonConcepts package as
  the Rhetos server version. CommonConcepts is a standard library for Rhetos framework,
  the two are always developed and released together.
* If you are upgrading to the latest version of the Rhetos framework,
  it is recommended to upgrade to the latest version of all other Rhetos packages
  that you are using (see the list of packages in your .nuspec file
  and RhetosPackages.config file).

Steps:

1. In your **.nuspec file** and in **RhetosPackages.config**, enter the new version number
   for referenced packages.
2. In your Visual Studio projects, if you reference any of those packages,
   use the NuGet package manager from Visual Studio to upgrade the package version.
3. Don't forget to follow any additional instructions in the "Breaking changes"
   sections from [release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md).
