This article describes how to setup the development environment for developing applications with Rhetos framework.

> NOTE: This article applies to **older versions of Rhetos framework**. For **Rhetos framework v4.0**
and later versions see article [Creating a new WCF application with Rhetos framework](Creating-new-WCF-Rhetos-application).

Table of contents:

1. [Prerequisites](#prerequisites)
2. [Create a working folder](#create-a-working-folder)
3. [Get Rhetos framework binaries](#get-rhetos-framework-binaries)
4. [Database setup](#database-setup)
5. [Packages configuration](#packages-configuration)
6. [IIS setup](#iis-setup)
7. [IIS Express setup](#iis-express-setup)
8. [Read next](#read-next)

## Prerequisites

Before following the instructions in this article, **make sure that all the [Prerequisites](Prerequisites) are installed**.

If you are following a Rhetos tutorial, we recommend that you start from the tutorial article [Create your first Rhetos application](Create-your-first-Rhetos-application), then come back here.

## Create a working folder

Create a development folder for your business application.

1. Create subfolders `src` (for source files) and `dist` (for final output).
2. Add a subfolder `src\DslScripts`, here we will write DSL scripts that describe features of our application.
3. Add a subfolder `dist\<MyApplicationName>RhetosServer`, where the Rhetos server binaries will be placed. The following documentation will refer to this folder as "**RhetosServer folder**".

Note that this folder structure is not required by Rhetos, but it is recommended.
It is used in different Rhetos tutorial articles, it conforms to Microsoft's new projects, and is easy to extend with new services and Rhetos components.

## Get Rhetos framework binaries

1. Download the RhetosServer zip file from the [latest release](https://github.com/Rhetos/Rhetos/releases) (not the source code).
2. Unpack the zip to the RhetosServer folder.

For example, the tutorial application "Bookstore" should have the following folder structure after the previous steps:

```Text
* Bookstore\
    * dist\
        * BookstoreRhetosServer\
            * bin\
    * src\
        * DslScripts\
```

Alternatively, you could build the Rhetos server binaries from the latest version of the source code, but this is not recommended: see the [article](Build-binaries-from-source).

## Database setup

1. Create an empty database (SQL Server 2008 or newer, Developer Edition is recommended for development).
2. In the folder `RhetosServer\bin` create a copy of the template file
   "Template.ConnectionStrings.config", and rename the copy to "ConnectionStrings.config".
3. Edit the existing configuration line in the **ConnectionStrings.config** file
   to reference the created database:
   Replace "theDatabase" with your database name, and "theServer" with SQL Server
   [instance](https://stackoverflow.com/a/45789478/2086516) name.

## Packages configuration

Rhetos packages define the content of the Rhetos application.
This section describes **the initialization of the packages configuration files**,
but with no packages selected.
That will result with an *empty* Rhetos server being deployed.

1. In the **RhetosServer** folder:
    * Create a copy if the "Template.RhetosPackages.config" file and rename the copy
      to "RhetosPackages.config", if the target file does not already exist.
    * Create a copy if the "Template.RhetosPackageSources.config" file and rename the copy
      to "RhetosPackageSources.config", if the target does not already exist.
2. Verify that the RhetosServer is configured correctly by opening command prompt
   at `RhetosServer\bin` folder and running `DeployPackages.exe`.
    * Note that the output may include warnings or errors
      `No packages specified in 'RhetosPackages.config'`
      and `Empty assembly is generated`.
      This is ok for now, because no packages are provided yet.
    * The last printed line should be "*[Trace] DeployPackages: Done.*".

## IIS setup

Follow the steps in this section if using IIS (recommended) instead of IIS Express.

1. Start "Internet Information Services (IIS) Manager".
2. Select "Application Pools" => "Add Application Pool...", enter the following data:
    * Name: "RhetosAppPool"
    * NET framework version: "v4.x"
    * Managed pipeline mode: "Integrated"
3. Open "RhetosAppPool" => "Advanced settings" => Change "Identity" => Select "Custom account" => Enter a domain user account that will be used for Rhetos web application (on a development computer enter your full account name; to find it type `whoami` in the command prompt). If you are **not using** a Windows domain account, see the next paragraph for setting the custom account.
    * Note: This account must have *db_owner* rights for the Rhetos database (see Database setup).
4. *Only for older versions*: If using Rhetos v1.1 or older, "RhetosAppPool" => "Advanced settings" => check "Enable 32-Bit Application".
5. Select "Sites" => Right click "Default Web Site" => "Add application...", enter the following data:
    * Enter Alias: "&lt;MyApplicationName&gt;RhetosServer". For example: "BookstoreRhetosServer".
    * Application pool: select "RhetosAppPool"
    * Physical path: select the path of the RhetosServer folder inside your application's development folder.
6. Select the created "RhetosServer" web application => Open "Authentication" icon:
    * Enable "Windows Authentication"
    * *Disable* all other authentication options.
7. Start your browser, and type address `http://localhost/<MyApplicationName>RhetosServer/`
   (for example <http://localhost/BookstoreRhetosServer/>).
   Verify that the web site is working and the Rhetos server status is displayed on the web page.
    * Troubleshooting: If you are getting an error "Access is denied." in browser, with the message "Error message 401.3: You do not have permission to view this directory ...", it is probably caused by working from  development folder instead of "inetpub". To fix this, execute the **step 4.** in the following paragraph, that contains running the `ICACLS` commands.

**If is is not possible to use Windows domain account**, the web application can be set up to use ApplicationPoolIdentity in a development environment:

1. **Skip the following steps** if you are using a Windows domain account.
2. Modify the *RhetosAppPool* to use built-in account "ApplicationPoolIdentity", instead of the developers domain account (Advanced Settings => Identity). This is the default user for a new app pool.
3. Open SQL Server Management Studio:
    * On the SQL Server add a Security => Logins => New Login... => Enter "BUILTIN\IIS_IUSRS".
    * Open the created  login entry (BUILTIN\IIS_IUSRS) => Open "User Mapping" => Select the Rhetos database and mark the "db_owner" checkbox.
4. Allow IIS system accounts read access to the Rhetos server folder and write access to the Rhetos logs folder (the "Logs" subfolder or directly in the Rhetos server folder, depending on the settings in *web.config*), by entering these commands to the command prompt *as administrator*, in the "RhetosServer" folder:

        ICACLS . /grant "BUILTIN\IIS_IUSRS":(OI)(CI)(RX)
        ICACLS . /grant "NT AUTHORITY\IUSR":(OI)(CI)(RX)
        IF NOT EXIST Logs\ MD Logs
        ICACLS .\Logs /grant "BUILTIN\IIS_IUSRS":(OI)(CI)(M)
        ICACLS .\Logs /grant "NT AUTHORITY\IUSR":(OI)(CI)(M)

5. If the web application fails with a file access error, set the required permissions for the IIS system accounts "BUILTIN\IIS_IUSRS" and "NT AUTHORITY\IUSR":
    * Read permissions to the RhetosServer folder.
    * Write permissions to the RhetosServer logs folder ("RhetosServer\Logs", or directly "RhetosServer" folder).
6. Open "RhetosServer\Web.config" file and set the "Rhetos:AppSecurity:AllClaimsForUsers" parameter value to your username and computer name, formatted "username@computername". Note that your username may include the domain name prefix. For older applications use [Configuration keys before Rhetos v4.0](Configuration-management#configuration-keys-before-rhetos-v40).

## IIS Express setup

Follow the steps in this section **only if using IIS Express instead of IIS**.
IIS is recommended (see the previous section), but IIS Express can be useful if a restricted environment is needed on the development machine.

The following instructions use tools from the Rhetos source repository.

`SetupRhetosServer.bat` will set up web environment for IIS Express.
It requires few parameters based on which it sets up database, configures
Rhetos server and sets up IIS Express local config which is enough to start Rhetos
server and developing.

Open command prompt in "Source\Rhetos" subfolder and run:

    SetupRhetosServer.bat <WebsiteName> <Port> <SqlServer> <DatabaseName>

SetupRhetosServer.bat command-line arguments:

* *WebsiteName* - name of website in IISExpress config
  (choose any name, it is not directly related to URL of Rhetos web service)
* *Port* - port that Rhetos web service will be listening to if using IIS Express
  (1234, for example)
* *SqlServer* - Microsoft SQL Server instance on which there is/will be database for Rhetos server
* *DatabaseName* - name of database that will Rhetos use, script will create
  database if it doesn't exist.

After running this script and before running Rhetos server, you can manually
configure `IISExpress.config`. It is template config for IIS Express site
with modified `<sites>` section and added `<location>` part at the end of config.
Those two defines which port on localhost Rhetos will be listening and that
security used is based on windows authentication.

If one wants to use different database it is defined in ConnectionStrings.config
in "Source\Rhetos\bin" subfolder.

Note that besides configuring IIS and Database, `SetupRhetosServer.bat` also
deploys *CommonConcepts* and user defined packages to that database. If one chooses
manual setup it is necessary to run ApplyPackages.bat in "Source\Rhetos".

Once configured, Rhetos server can be started by running following command
in cmd while positioned in "Source\Rhetos":

    CALL "C:\Program Files (x86)\IIS Express\IISExpress.exe" /config:IISExpress.config

If using Rhetos v1.1 or older, use the 32-bit "Program Files" folder.

## Read next

* [Create your first Rhetos application](Create-your-first-Rhetos-application)
