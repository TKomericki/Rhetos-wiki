This article is focused on the framework development.
See [User authentication and authorization](User-authentication-and-authorization) article
for more information on business application development.

> This article applies to **Rhetos v4 and earlies** versions.
On **Rhetos v5** and later versions, different authentication methods should be implemented
in ASP.NET Core, while Rhetos should simply use the ASP.NET's authentication (with `AddAspNetCoreIdentityUser()`).
Custom implementation of IUserInfo on Rhetos v5 is intended only for applications that do not use standard ASP.NET Core authentication middleware.

## Overview

Role of the authentication subsystem in Rhetos is to:

1. Verify the user's authenticity
2. **Provide the username** to the rest of the system.

After that, the authorization subsystem will check for the user's permissions, based solely on the provided username.

## Verifying the user's authenticity

Code that verifies the user is not directly handled by Rhetos framework. Here are some existing examples.

**Windows Authentication** is enabled in Rhetos by default, if no other authentication plugins are installed.

* The user verification is actually handled automatically between the browser and the IIS server; there is no code needed in Rhetos framework to handle that.
* There is no web GUI needed for the authentication.
* Note: The authentication on a remote server may not work by default on some browsers until the server is added to the browser's trusted NTLM sites list.

On the Rhetos homepage (<http://localhost/Rhetos>, or similar) at the end of the page you can see the currently authenticated user name and method (usually NTLM or Negotiate).

**Forms Authentication** is used instead of Windows, if the [AspNetFormsAuth](https://github.com/Rhetos/AspNetFormsAuth) Rhetos plugin is installed (see [Readme.md](https://github.com/Rhetos/AspNetFormsAuth/blob/master/Readme.md) for instruction).

* The user verification is handled by the Microsoft ASP.NET library that contains methods for storing and verifying the user's password.
* The Rhetos plugin contains a **simple web API** for those ASP.NET methods, to allow user to login.
  * For example, see the Login and Logout web methods in [AuthenticationService](https://github.com/Rhetos/AspNetFormsAuth/blob/master/Plugins/Rhetos.AspNetFormsAuth/AuthenticationService.cs) plugin. They are mostly just wrappers around ASP.NET's WebSecurity.Login and Logout methods.
* A web form is needed for user to enter the username and the password. This is usually developed as a part of the business application's front-end. Additionally, the AspNetFormsAuth plugin extends the Rhetos homepage (<http://localhost/Rhetos>, or similar) with a few simple pages for user login and administration, intended for developers and system administrators.
* After logging in, ASP.NET uses a secure cookie to cache the authentication token in the user's browser session.

**Any additional authentication method** can be developed as a new plugin, by any means of user authenticity verification, as long as the plugin can provide the username to the rest of the system (see the next section).

* Sometimes the development of the new plugin can be simplified by extending the AspNetFormsAuth plugin, so that after the new mechanism verifies the user it can use the ASP.NET methods to directly create the user's security token. AspNetFormsAuth can work with that token after that, even though user's password is never set or used.

## Providing the username

Each Rhetos authentication plugin needs to provide the username to the rest of the system. This is achieved by implementing the [IUserInfo](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Utilities/IUserInfo.cs) interface and registering the implementation plugin. IUserInfo contains the username getter; all other members are optional. A new IUserInfo instance is created for each web request.

For example, **Windows Authentication** user in Rhetos v4 is implemented by [WcfWindowsUserInfo](https://github.com/Rhetos/Rhetos/blob/release-4/Source/Rhetos.Security/WcfWindowsUserInfo.cs) class, where the username is returned by WCF library call `ServiceSecurityContext.Current.WindowsIdentity.Name`.

**AspNetFormsAuth** plugin in Rhetos v4 implements IUserInfo with a very simple [AspNetUserInfo](https://github.com/Rhetos/AspNetFormsAuth/blob/rhetos-4/Plugins/Rhetos.AspNetFormsAuth/AspNetUserInfo.cs) class, where the username is returned from ASP.NET by calling `HttpContext.Current.User.Identity.Name`.

To register a new class in Rhetos as a plugin that implements IUserInfo you need to register it to the dependency injection container, while making sure that there are no other security plugins registered. For example of how to do it see the [AutofacModuleConfiguration](https://github.com/Rhetos/AspNetFormsAuth/blob/master/Plugins/Rhetos.AspNetFormsAuth/AutofacModuleConfiguration.cs) class and all mentions of "AspNetUserInfo" in it. [Autofac](https://autofac.org/) is used in Rhetos for DI.

The IUserInfo instance is most often used in the rest of the system as a property of ExecutionContext. For example, the following DSL script will generate a reader that returns the current user's username independently of the authentication mechanism.

    Module Demo
    {
        Computed MyAccount 'repository => new[] {
            new MyAccount { UserName = _executionContext.UserInfo.UserName } }'
        {
            ShortString UserName;
        }
    }

It can be tested by opening <http://localhost/Rhetos/rest/Demo/MyAccount/>
