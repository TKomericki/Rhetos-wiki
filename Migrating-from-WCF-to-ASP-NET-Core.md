# Migrating from WCF to ASP.NET Core

Rhetos v5 is migrated to .NET 5, and it no longer supports WCF.
New Rhetos apps should use APS.NET Core instead.

When migrating existing Rhetos application to APS.NET Core, the configuration in web.config should also be migrated.
How the migration is done depends on the web server which is used.

Contents:

1. [Code sample - Configuring request size limits](#code-sample---configuring-request-size-limits)
2. [More info](#more-info)
   1. [Kestrel](#kestrel)
   2. [File upload](#file-upload)
   3. [IIS](#iis)

## Code sample - Configuring request size limits

In *Program.cs* (.NET 6/7), add and call the following method when configuring `builder.Services`:

```cs
static void ConfigureRequestSizeLimits(WebApplicationBuilder builder, int maxRequestBodySize, int maxUriLength)
{
    // Kestrel configuration
    builder.Services.Configure<KestrelServerOptions>(o =>
    {
        o.Limits.MaxRequestBodySize = maxRequestBodySize;
        o.Limits.MaxRequestLineSize = maxUriLength;
        o.Limits.MaxRequestBufferSize = Math.Max(o.Limits.MaxRequestBufferSize.Value, maxUriLength);
    });

    // IIS support
    builder.Services.Configure<IISServerOptions>(o =>
    {
        o.MaxRequestBodySize = maxRequestBodySize;
        o.MaxRequestBodyBufferSize = Math.Max(o.MaxRequestBodyBufferSize, maxUriLength);
    });

    // File upload
    builder.Services.Configure<FormOptions>(x =>
    {
        x.ValueLengthLimit = maxRequestBodySize;
        x.MultipartBodyLengthLimit = maxRequestBodySize;
    });
}
```

For IIS support, additionally add the *web.config* file and configure `requestLimit` element,
see the example below.

* Set `maxAllowedContentLength` to match the `maxRequestBodySize` from the C# code above.
* Set `maxUrl` and `maxQueryString` to match the `maxUriLength` from the C# code above.
* **Replace** the `Bookstore.Service.exe` path with your application.

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="bin\Debug\net6.0\Bookstore.Service.exe" arguments="" stdoutLogEnabled="false" hostingModel="InProcess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_HTTPS_PORT" value="443" />
        </environmentVariables>
      </aspNetCore>
      <security>
        <requestFiltering>
          <!-- Ove limite je potrebno dodatno konfigurirati u Program.cs: ConfigureRequestSizeLimits. -->
          <requestLimits maxAllowedContentLength="104857600" maxUrl="2097151" maxQueryString="2097151" />
        </requestFiltering>
      </security>
    </system.webServer>
  </location>
</configuration>
```

## More info

### Kestrel

For Kestrel you can follow the instructions on https://docs.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel/options?view=aspnetcore-5.0.

For example see the `ConfigureKestrel` method call in the code sample section above.

### File upload

To configure the limit of each multipart body, in the startup class you need to
configure `FormOptions`, see the code sample above.

This is required, for example, when using the **Rhetos.LightMDS** package if you want to increase the file upload size limit.

### IIS

IIS still uses the web.config file for server specific configuration.

The web.config file is not added automatically when creating an empty ASP.NET Core application so you need to add it manually.

The `system.serviceModel` section in web.config is WCF specific so it is not used anymore.

The `system.web` section is ASP.NET specific and it is not used anymore
but some of its configuration can be set under the `system.webserver` section which is IIS specific.
**Migrate the following attribute values** from the old to the new web.config file.

| Old web.config attribute | New web.config attribute |
|---|---|
| `system.web:httpRuntime maxUrlLength` | `system.webServer:security:requestFiltering:requestLimits maxUrl`
| `system.web:httpRuntime maxQueryStringLength` | `system.webServer:security:requestFiltering:requestLimits maxQueryString`
| `system.web:httpRuntime maxRequestLength` | `system.webServer:security:requestFiltering:requestLimits maxAllowedContentLength`

Review the IIS limits in IIS Manager: web site => Request filtering => Edit Feature Settings.

When using IIS, other limits may apply to max URL length.
Review the following articles if needed:

* Configuring Http.sys registry settings <https://stackoverflow.com/questions/16600113/request-url-too-long-20k-characters-iis-7/24282934#24282934>.
* IISServerOptions for [In-process hosting with IIS and ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/in-process-hosting?view=aspnetcore-5.0)
* [BadHttpRequestException: Request body too large.](https://github.com/dotnet/aspnetcore/issues/20369)
