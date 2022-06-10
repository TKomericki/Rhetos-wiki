This article describes how to install and verify the prerequisites for developing applications with Rhetos framework. This is generally a standard C#/ASP.NET development environment.

> OTHER VERSIONS OF RHETOS:
This article applies to **Rhetos v3 and v4**.
For newer versions see [Prerequisites](Prerequisites).

Contents:

1. [Install prerequisites](#install-prerequisites)
2. [Verify the prerequisites](#verify-the-prerequisites)
3. [Configure your text editor for DSL scripts (*.rhe)](#configure-your-text-editor-for-dsl-scripts-rhe)
4. [Read next](#read-next)

## Install prerequisites

Prerequisites for running web applications with Rhetos framework:

* Windows 8 or newer
* .NET Framework 4.7.2
* IIS with ASP.NET 4.x installed
  * Follow the [installation instructions](Installing-IIS).
* Microsoft SQL Express or SQL Server 2008 or newer, or Oracle Database 11g Release 2 or newer.

Recommended application development environment (prerequisites for tutorials):

* Visual Studio 2017 v15.7 or later. Visual Studio 2022 is recommended.
* [NuGet.exe](https://www.nuget.org/downloads) command-line utility, download and [add to the PATH](https://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/) environment variable
* [Git client](https://gitforwindows.org), installed and added to the PATH environment variable
* Text editor (recommended Visual Studio Code, SublimeText3 or Notepad++)
* [LINQPad](https://www.linqpad.net), for testing and support.
  Select the latest version based on the .NET version of your application,
  see "[Supported frameworks](https://www.linqpad.net/Download.aspx)".
* [SQL Server Management Studio](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms), the latest version

## Verify the prerequisites

Verify IIS:

1. Start => Run (Win+R), and then type `InetMgr`.
   The "Internet Information Services (IIS) Manager" should be opened.
2. Start your browser, and then type `http://localhost` in the address.
   The default web site opens and should display an IIS image.

Verify command-prompt utilities:

1. Open command-prompt and enter the following commands to check if the utilities are installed and available in the PATH environment variable:
    * `nuget.exe list rhetos` (it should print a list of Rhetos packages available in the online gallery)
    * `git.exe --version` (it should report the installed git version)

Verify Visual Studio 2019 and ASP.NET:

1. Start "Visual Studio" **as administrator** (right click => Run as administrator) for IIS support.
2. Create a new project from the template "ASP.NET Web Application (.NET Framework)" with C# and .NET Framework 4.7.2. Select the "MVC" project template and under Authentication click "Change" and select "Windows Authentication".
3. Project Properties => Web => Change the setting "IIS Express" to "Local IIS", and click "Create Virtual Directory".
4. Build and Start the application (F5) to check if everything is installed correctly.
  The ASP.NET web page should automatically open in a browser (<http://localhost/WebApplicationX/>).
5. Delete the test project.

Verify the SQL Server and your development database:

1. Start "SQL Server Management Studio" and connect to the SQL Server that you will be using for development.
2. Create and new empty database that will be used for developing the Rhetos application.
    * Note: Each developer must have his/her own database for Rhetos application development, to avoid conflicts of deploying multiple Rhetos applications to the same database.
3. Open a new query window on the created database and execute query: `print user_name()`. The query should output `dbo`, meaning that the user has full permissions on the database.

Verify building Rhetos from source:

1. Use git to clone the repository <https://github.com/Rhetos/Rhetos.git> to a new source folder on your disk:
   * In the command prompt run `git clone https://github.com/Rhetos/Rhetos.git RhetosSource`
2. Switch to git branch `release-4`.
   * Open command prompt in the created `RhetosSource` folder and run `git checkout release-4`
3. Run `Build.bat`.
   * **Verify that the last printed line is "Build.bat SUCCESSFULLY COMPLETED".**

## Configure your text editor for DSL scripts (*.rhe)

The **syntax highlighting** plugins are available for the following text editors.

**Visual Studio Code:**

1. Open Visual Studio Code => Press Ctrl-Shift-P => Select "Extensions: Open Extensions Folder".
2. In the opened folder, use git to clone the <https://github.com/Rhetos/RhetosVSCode> repository to the subfolder "RhetosVSCode".
3. Restart Visual Studio Code.

**Visual Studio 2019 or 2022:**

Visual Studio extension for Rhetos includes highlighting, autocomplete, error reporting, signature help tooltips and other features.

1. Install the IntelliSense support for Rhetos DSL, see [Installation](https://github.com/Rhetos/LanguageServices#installation) instructions.
2. For a better insight on build process, show Output on build:
   * Tools => Options => Projects and Solutions => General => Enable: "Show Output window when build starts".

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

**SublimeText3:**

1. Install the *PackageControl* plugin by following the instructions at <https://packagecontrol.io/installation>.
2. Install the *RhetosDSL* sublime text package: Ctrl-Shift-P, select "install package", select "RhetosDSL".
    * Note: The source code is available at <https://github.com/Hugibeer/RhetosDSLSyntax>.

## Read next

* [Creating a new WCF application with Rhetos framework](Creating-new-WCF-Rhetos-application)
