This article describes how to install and verify the prerequisites for developing applications with Rhetos framework. This is generally a standard C#/ASP.NET development environment.

Contents:

1. [Install prerequisites](#Install-prerequisites)
2. [Verify the prerequisites](#Verify-the-prerequisites)
3. [Configure your text editor for DSL scripts (*.rhe)](#Configure-your-text-editor-for-DSL-scripts-rhe)
4. [Read next](#Read-next)

## Install prerequisites

Prerequisites for the Rhetos server:

* Windows 8 or newer
* .NET Framework 4.5.1
* IIS with ASP.NET 4.x installed
  * To make sure all of the needed ASP.NET components are installed, follow the instructions in the chapter "[Installing IIS Features on Windows 8 and Windows 10](https://docs.microsoft.com/en-us/previous-versions/dynamicsnav-2016/hh167503(v=nav.90)#installing-iis-features-on-windows-8-and-windows-10)" on MSDN, but **skip .NET 3.5** features.
* Microsoft SQL Express or SQL Server 2008 or newer, or Oracle Database 11g Release 2 or newer.

Application development environment (prerequisites for tutorials):

* Visual Studio 2015 or newer
* [NuGet.exe](https://www.nuget.org/downloads) command-line utility, download and [add to the PATH](https://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/) environment variable
* [Git client](https://gitforwindows.org), installed and added to the PATH environment variable
* Text editor (recommended Visual Studio Code, SublimeText3 or Notepad++)
* [LinqPad](https://www.linqpad.net/Download.aspx), the latest version
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

Verify Visual Studio 2017 and ASP.NET:

1. Start "Visual Studio" **as administrator**.
2. Create a new project from the template "ASP.NET Web Application (.NET Framework)", select the "MVC" project template and Change Authentication to "Windows Security".
3. Project Properties => Web => Change the setting "IIS Express" to "Local IIS", and Create Virtual Directory.
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
2. Open the command prompt in the created Rhetos source folder and run `Build.bat`.
    * **Verify that the last printed line is "Build.bat SUCCESSFULLY COMPLETED".**

## Configure your text editor for DSL scripts (*.rhe)

The **syntax highlighting** plugins are available for the following text editors.

**Visual Studio Code:**

1. Open Visual Studio Code => Press Ctrl-Shift-P => Select "Extensions: Open Extensions Folder".
2. In the opened folder, use git to clone the <https://github.com/Rhetos/RhetosVSCode> repository to the subfolder "RhetosVSCode".
3. Restart Visual Studio Code.

**Notepad++:**

1. Download the [RhetosNppSyntaxHighlight.xml](https://raw.githubusercontent.com/Rhetos/RhetosNPP/master/RhetosNppSyntaxHighlight.xml)
   file from <https://github.com/Rhetos/RhetosNPP>.
2. Open "Notepad++" => Menu "Language" => "Define your language" => Click "Import..." => Select the downloaded XML file.
3. For direct *deployment* of DSL scripts from Notepad++ (only for the development environment):
   1. Install the *NppExec* plugin (Plugins -> Plugin Manages ->...).
   2. F6 -> enter the path to "DeployPackages.exe" inside the Rhetos server, for example
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

* [Development environment setup](Development-environment-setup)
