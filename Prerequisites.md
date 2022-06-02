This article describes how to install and verify the prerequisites for developing applications with Rhetos framework. This is generally a standard C#/ASP.NET development environment.

> OTHER VERSIONS OF RHETOS:
This article applies to **Rhetos v5** and later versions.
For older versions see [Prerequisites v4](Prerequisites-v4).

Contents:

1. [Prerequisites](#prerequisites)
2. [Recommended application development environment](#recommended-application-development-environment)
3. [Configure your text editor for Rhetos DSL scripts](#configure-your-text-editor-for-rhetos-dsl-scripts)
4. [Read next](#read-next)

## Prerequisites

Prerequisites for running applications with Rhetos framework:

* Linux, Windows or macOS.
  See [.NET 6 - Supported OS versions](https://github.com/dotnet/core/blob/main/release-notes/6.0/supported-os.md) for more details on versions and distributions.
* [.NET 6 runtime](https://dotnet.microsoft.com/en-us/download).
  Older versions of .NET Framework and .NET 5 are supported with [previous Rhetos versions](Previous-releases).
* SQL Server 2008 or newer, Microsoft SQL Express, or Oracle Database 11g Release 2 or newer.

## Recommended application development environment

There are no special prerequisites for development environment of Rhetos applications.
Rhetos is distributed as a NuGet package, and it will work on any environment
that supports development of .NET 5/.NET 6 applications on Linux, Windows or macOS.

Tutorials in this wiki use the following development tools, as a recommended application development environment:

* [.NET 6 SDK](https://dotnet.microsoft.com/en-us/download).
* Visual Studio 2022 with Rhetos DSL IntelliSense, or a text editor with Rhetos DSL syntax highlighting (Visual Studio Code, SublimeText3 or Notepad++). See the setup in a following section.
* [NuGet.exe](https://www.nuget.org/downloads) command-line utility, download and [add to the PATH](https://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/) environment variable.
* [Git client](https://gitforwindows.org), installed and added to the PATH environment variable.
* [LINQPad](https://www.linqpad.net), for testing and support.
  Select the latest version based on the .NET version of your application,
  see "[Supported frameworks](https://www.linqpad.net/Download.aspx)".
* [SQL Server Management Studio](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms), the latest version.
* To manage databases on a local machine for development and testing, install [SQL Server 2019](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) "Developer" edition.

Verify command-prompt utilities after installation:

1. Open command-prompt and enter the following commands to check if the utilities are installed and available in the PATH environment variable:
    * `nuget.exe list rhetos` (it should print a list of Rhetos packages available in the online gallery)
    * `git.exe --version` (it should report the installed git version)

## Configure your text editor for Rhetos DSL scripts

The following plugins for text editors are not required for development of Rhetos apps,
but can help with syntax highlighting or IntelliSense for Rhetos DSL scripts (*.rhe files)

**Visual Studio 2019 or 2022:**

Visual Studio extension for Rhetos includes highlighting, autocomplete, error reporting, signature help tooltips and other features.

1. Install the IntelliSense support for Rhetos DSL, see [Installation](https://github.com/Rhetos/LanguageServices#installation) instructions.
2. For a better insight on build process, show Output on build:
   * Tools => Options => Projects and Solutions => General => Enable: "Show Output window when build starts".

**Visual Studio Code:**

1. Open Visual Studio Code => Press Ctrl-Shift-P => Select "Extensions: Open Extensions Folder".
2. In the opened folder, use git to clone the <https://github.com/Rhetos/RhetosVSCode> repository to the subfolder "RhetosVSCode".
3. Restart Visual Studio Code.

**SublimeText3:**

1. Install the *PackageControl* plugin by following the instructions at <https://packagecontrol.io/installation>.
2. Install the *RhetosDSL* sublime text package: Ctrl-Shift-P, select "install package", select "RhetosDSL".
    * Note: The source code is available at <https://github.com/Hugibeer/RhetosDSLSyntax>.

**Notepad++:**

1. Download the [RhetosNppSyntaxHighlight.xml](https://raw.githubusercontent.com/Rhetos/RhetosNPP/master/RhetosNppSyntaxHighlight.xml)
   file from <https://github.com/Rhetos/RhetosNPP>.
2. Open "Notepad++" => Menu "Language" => "Define your language" => Click "Import..." => Select the downloaded XML file.
3. Optionally, configure direct *build and deployment* of DSL scripts from Notepad++. This is only for the development environment, and only for older Rhetos applications that contain DeployPackages.exe.
   1. Install the *NppExec* plugin (Plugins -> Plugin Manages ->...).
   2. F6 -> enter the path to "DeployPackages.exe" inside the Rhetos application, for example
      "C:\Projects\MyRhetosServer\bin\DeployPackages.exe", click "Save...", enter script name "DeployPackages".
      Henceforward, that action can be executed directly with CTRL-F6.
   3. For automatic analysis of deployment results: SHIFT-F6 -> "Highlight" -> enter the following table.
      Henceforward, a double-click on the underlined line in the log is going to directly open the file and position on the error.

    |    |     |     |     |     |     |     |     |
    |--- | --- | --- | --- | --- | --- | --- | --- |
    | ☑ |[Info *At line %L%, column %C%, file '%A%'* | 00 | 00 | FF | ☐ | ☑ | ☑ |
    | ☑ |*At line %L%, column %C%, file '%A%'* | FF | 00 | 00 | ☐ | ☑ | ☑ |
    | ☑ |*Exception* | FF | 00 | 00 | ☐ | ☑ | ☐ |
    | ☑ | *FAILED* | FF | 00 | 00 | ☐ | ☑ | ☐ |
    | ☑ | [Error]* | FF | 00 | 00 | ☐ | ☑ | ☐ |
    | ☑ | [Info]* | 00 | 00 | FF | ☐ | ☑ | ☐ |
    | ☑ | [Trace] Done. | 00 | FF | 00 | ☐ | ☑ | ☐ |
    | ☑ |*SUCCESSFULLY COMPLETED* | 00 | FF | 00 | ☐ | ☑ | ☐ |
    | ☑ | at * in %A%:line %L% | 00 | 00 | 00 | ☐ | ☐ | ☑ |

4. Optionally, you can download the plug-in QuickText [here](https://sourceforge.net/projects/quicktext/?source=dlp).
   The plug-in enables you to define and use shortcuts that will be replaced with complete expressions.
   For example replace "ss" with "ShortString" and so on.

## Read next

* [Creating a new application with Rhetos framework](Creating-a-new-application-with-Rhetos-framework)
