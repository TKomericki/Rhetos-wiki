# Creating new WCF Rhetos application

Since Rhetos v4.0, new Rhetos applications should be created in Visual Studio with "New project" command.

Current limitations:

* Only WCF applications are supported. We plan to extend this in future to any VS project type.

Contents:

1. [Development environment setup](#development-environment-setup)
2. [Create a new application](#create-a-new-application)
3. [Troubleshooting](#troubleshooting)

## Development environment setup

1. Install the IntelliSense support for Rhetos DSL from latest release <https://github.com/Rhetos/LanguageServices/releases>
   (download and open *.vsix* file).
   This extension is not required for developing and building Rhetos applications,
   but it is very useful if using Visual Studio as an editor for DSL scripts.

## Create a new application

1. VS 2019 => **New project** => search and select "**WCF Service Application**" (C#) => Next => Framework: **.NET 4.7.2** => Create.
   * If nothing is found on search: Click "Install more tools and features" to open Visual Studio Installer => Select "Individual components" tab => Enable "Windows Communication Foundation" => Click "Modify" to install.
2. Test the new project:
   * Select "Service1.svc" in Solution Explorer and press F5 to start debugging.
   * WCF Test Client should open automatically => Double-click "GetData" method => Invoke => OK => Response should be "You entered: 0".
3. Add the following NuGet packages:
   1. Rhetos.Wcf
   2. Rhetos.CommonConcepts
   3. Rhetos.RestGenerator
4. Make sure your project is in "*PackageReference*" format instead of using *packages.config*:
   If your project contains *packages.config*, right-click the file in Solution Explorer
   and select "Migrate packages.config to PackageReference..." if available.
   * If you get an error `Cannot convert from packages.config to PackageRefrence`,
     change Visual Studio settings: NuGet Package Manager => Package Management => Default package management format = PackageReference.
     Then make a new WCF project from scratch.
5. Save the solution (File => Save All). In Visual Studio open Package Manager Console
   and run command `Add-RhetosWcfFiles`. It will add Rhetos WCF startup configuration and services
   to the application.
   * If the command results with execution policy error, run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` and then run `Add-RhetosWcfFiles` again.
   * If the command results with `Access is denied`, save the solution (File => Save All) before running it again.
6. Create an empty database for this Rhetos application.
   In your project folder: rename `Template.ConnectionStrings.config` to `ConnectionStrings.config`
   and enter the SQL server [instance](https://stackoverflow.com/a/45789478/2086516) name (`theServer`)
   and database name (`theDatabase`).
7. Configure user authentication for your application:
   * Option A) *(Recommended for quick-start)* Enable **anonymous access** by creating `ExternalAppSettings.config` in project folder, with the following content:
     `<appSettings>  <add key="Security.AllClaimsForAnonymous" value="True" />  </appSettings>`.
   * Option B) If you want to use **Windows authentication with IIS**:
      * Run Visual Studio *as Administrator*. Project properties => Web => Change from "ISS Express" to "Local IIS". On save answer Yes.
      * Open IIS Manager => Find you application => Authentication => Disable Anonymous, Enable Windows Authentication.
      * Add `Security.AllClaimsForUsers` configuration setting for your account and your
        machine name, to simplify testing. See instructions in
        [Suppressing permissions in a development environment](Basic-permissions#suppressing-permissions-in-a-development-environment).
   * Option C) If you want to use **Windows authentication with IIS Express**:
     * Edit `.vs\<solution name>\config\applicationhost.config`
       * in element `anonymousAuthentication` set `enabled` attribute to `false`.
       * in element `windowsAuthentication` set `enabled` attribute to `true`.
     * Add `Security.AllClaimsForUsers` configuration setting for your account and your
       machine name, to simplify testing. See instructions in
       [Suppressing permissions in a development environment](Basic-permissions#suppressing-permissions-in-a-development-environment).
8. Test: Select the project in Solution Explorer (e.g. WcfService1) and press F5 to start debugging.
    * Browser should open automatically.
    * Add "rest/Common/Claim/" to the base URL. It should return list of records in JSON format.
    * **In case of an error**, see [Troubleshooting](#troubleshooting) chapter below.
9. Right-click project => add folder "DslScripts" => in the folder add **Text file** "HelloWorld.rhe", and write a simple Entity in this script.
    * You can copy the example of DSL script from
      [tutorial](Create-your-first-Rhetos-application)
      (starting with `Module Bookstore`).
10. Test: Press F5 and test REST API for new entity (base URL + `rest/Bookstore/Book/`).
11. Setup git repository
    1. Add standard Visual Studio [.gitignore](https://github.com/github/gitignore/blob/master/VisualStudio.gitignore) file.
    2. Append Rhetos folders and user files to the end of the .gitignore file.
       For example, if your project subfolder is "WcfService1", append the following:
       ```text
       # Rhetos
       /WcfService1/rhetos-app.local.settings.json
       /WcfService1/Logs
       /WcfService1/Resources
       /WcfService1/ConnectionStrings.config
       /WcfService1/ExternalAppSettings.config
       ```

## Troubleshooting

1. Build fails with error `DeployPackages: System.Configuration.ConfigurationErrorsException: Unable to open configSource file 'ConnectionStrings.config'.`
   * Cause: *Web.config* references *ConnectionStrings.config* that is missing. See instructions above on how to add *ConnectionStrings.config*.
2. Startup fails with `Specified argument was out of the range of valid values.Parameter name: site`
   * See "Configure user authentication for your application" above.
3. Web page returns `Access to the path '...' is denied.` or UnauthorizedAccessException in `Internal server error occurred. See RhetosServer.log for more information. (UnauthorizedAccessException`
   * Cause: The application (or IIS app pool) does not have access to application folder.
   * Option A) Open IIS Manager => Find you application => Basic settings => Change application pool to new RhetosAppPool that is configured to run with your development account (see [IIS Setup](Development-environment-setup#iis-setup))
   * Option B) Add IIS web account permission for the application's folder (see ICACLS commands from [Configure IIS](https://github.com/Rhetos/AspNetFormsAuth#2-configure-iis))
4. Startup fails with `SqlUtility has not been initialized correctly: Value for connection string (name="ServerConnectionString") is not specified.`
   * Configure ConnectionStrings.config (see instructions in the section above).
5. Startup fails with SqlException `Login failed for user 'IIS APPPOOL\DefaultAppPool'.`
   * Cause: The application (or IIS app pool) does not have access to the database. If using IIS, Open IIS Manager => Find you application => Basic settings => Change application pool to new RhetosAppPool that is configured to run with your development account (see [IIS Setup](Development-environment-setup#iis-setup))
6. Startup fails with `User is not authenticated`
   * See instructions in "Configure user authentication for your application" above.
7. Visual Studio shows errors `The type or namespace name '...' could not be found`, even though Build passes successfully.
   * Click "Refresh" button in Solution Explorer to refresh IntelliSense.

See also the separate article on [Troubleshooting WCF services](Troubleshooting-WCF-services).
