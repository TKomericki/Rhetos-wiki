
# Using old packages with new NuGet dependencies

This article shows now to add `bindingRedirect` configuration,
to allow your existing application to work with existing plugin packages,
without recompiling them with new version of the dependencies.

This issue applies only to *signed* dependencies.

1. [Configure Rhetos web application](#configure-rhetos-web-application)
2. [Configure Unit tests and utilities](#configure-unit-tests-and-utilities)
3. [Troubleshooting](#troubleshooting)

## Configure Rhetos web application

To allow the existing Rhetos applications and packages to work with new version of the
dependencies, without upgrading the packages, edit the **Web.config** file:
add (or replace) the following three `<dependentAssembly>` elements in `configuration/runtime/assemblyBinding`:

```xml
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      ...
      ...
      <!-- Add to following dependentAssembly elements: -->
      <dependentAssembly>
        <assemblyIdentity name="Autofac" publicKeyToken="17863af14b0044da" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-4.9.4.0" newVersion="4.9.4.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="Autofac.Integration.Wcf" publicKeyToken="17863af14b0044da" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-4.1.0.0" newVersion="4.1.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-12.0.0.0" newVersion="12.0.0.0" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
```

## Configure Unit tests and utilities

A similar change in *App.config* file should be done in your **unit testing projects**
and **other applications** (exe utilities) if they reference the generated Rhetos dlls (ServerDom.Reporitories.dll).
If your application (or unit test project) does not have the config file,
create it in Visual Studio: Project => Add New Item => Application Configuration File.

```xml
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      ...
      ...
      <dependentAssembly>
        <assemblyIdentity name="Autofac" publicKeyToken="17863af14b0044da" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-4.9.4.0" newVersion="4.9.4.0" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
```

You can test if the application returns some of the following errors on startup,
then add `dependentAssembly` elements only for those assemblies that are referenced
in the error message (usually only "Autofac" is needed, as shown above).

* *System.InvalidCastException: Unable to cast object of type '...' to type 'Autofac.Module'.*
* *Could not load file or assembly 'Autofac, Version=3.3.0.0, ...*
* *ReflectionTypeLoadException: Unable to load one or more of the requested types. Retrieve the LoaderExceptions property for more information.*

## Troubleshooting

* If a web request returns error
  "*The service '...' cannot be activated due to an exception during compilation ...*"
  or "*The service '...' configured for WCF is not registered with the Autofac container.*",
  compare the your new Web.config to the old version and
  make sure that you still have the `probing` element in the `configuration/runtime/assemblyBinding`.
