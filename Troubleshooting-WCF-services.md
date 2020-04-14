# Troubleshooting WCF services

This article contains tips on some common issues that can occur on old WCF applications, mostly related to service configuration and authentication.

Contents:

1. ["Compilation Error" on ASPX pages (for example Rhetos homepage)](#compilation-error-on-aspx-pages-for-example-rhetos-homepage)
2. [SOAP service "Autofac container" error](#soap-service-autofac-container-error)
3. [SOAP service "authentication schemes" error](#soap-service-authentication-schemes-error)

## "Compilation Error" on ASPX pages (for example Rhetos homepage)

```log
Server Error in '/Rhetos' Application.

Compilation Error
Description: An error occurred during the compilation of a resource required to service this request. Please review the following specific error details and modify your source code appropriately.

Compiler Error Message: CS0012: The type 'System.Collections.Generic.IEnumerable`1<T0>' is defined in an assembly that is not referenced. You must add a reference to assembly 'netstandard, Version=2.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51'.

Source Error:

...
Line 12:     foreach (var snippet in snippets.GetPlugins())
```

**Solution:**

In *web.config*, inside `system.web / compilation / assemblies`, insert the element:

```xml
<add assembly="netstandard, Version=2.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51"/>
```

For example

```xml
  <system.web>
    <compilation debug="true" targetFramework="4.7.2">
      <assemblies>
        <add assembly="netstandard, Version=2.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51"/>
      </assemblies>
    </compilation>
  </system.web>
```

## SOAP service "Autofac container" error

SOAP service returns error:

```text
The service 'Rhetos.RhetosService, Rhetos' configured for WCF is not registered with the Autofac container.
```

**Solution:**

Make sure that "RhetosService.svc" file in your application root folder contains the current application assembly name:

Instead of `Service="Rhetos.RhetosService, Rhetos"`
it should be `Service="Rhetos.RhetosService, My.Application.Name"`.

Replace "My.Application.Name" above with the assembly name of your web application (see: Project => Properties => Application => Assembly name).

## SOAP service "authentication schemes" error

SOAP service returns error:

```text
The authentication schemes configured on the host ('Anonymous') do not allow those configured on the binding 'BasicHttpBinding' ('Negotiate').  Please ensure that the SecurityMode is set to Transport or TransportCredentialOnly.  Additionally, this may be resolved by changing the authentication schemes for this application through the IIS management tool, through the ServiceHost.Authentication.AuthenticationSchemes property, in the application configuration file at the <serviceAuthenticationManager> element, by updating the ClientCredentialType property on the binding, or by adjusting the AuthenticationScheme property on the HttpTransportBindingElement. 
```

**Solution:**

This may occur if the service is configured for Windows Authentication, while using anonymous or other authentication type.

To work without Windows Authentication, comment out or delete the following **two occurrences** of the `security` element in *web.config* file:

```xml
<security mode="TransportCredentialOnly">
  <transport clientCredentialType="Windows" />
</security>
...
<security mode="TransportCredentialOnly">
  <transport clientCredentialType="Windows" />
</security>
```
