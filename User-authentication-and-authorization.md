> OTHER VERSIONS OF RHETOS:
This article applies to **Rhetos v5 and later** versions.
For earlier versions see [User authentication and authorization v4](User-authentication-and-authorization-v4).

## Authentication

*Authentication* refers to a process of establishing the user's identity.
For example, by providing the username and the password.

**Any authentication method** supported by ASP.NET may be used in Rhetos apps.

* This is handled by `AddAspNetCoreIdentityUser()` call on AddRhetosHost.
  See the method call in tutorial article
  [Creating a new application with Rhetos framework](Creating-a-new-application-with-Rhetos-framework).
* For example, to add Windows Authentication to your application, follow the ASP.NET Core documentation:
  [Configure Windows Authentication](https://docs.microsoft.com/en-us/aspnet/core/security/authentication/windowsauth?view=aspnetcore-6.0&tabs=visual-studio).

Various Rhetos plugins are available for additional administration features:

* Automatic synchronization with the **Active Directory user groups**, see "Automatic user management"
  in article [Basic permissions](Basic-permissions#automatic-user-management).
* [Impersonation](https://github.com/Rhetos/Impersonation) -
  It provides a safe way for specified users to log in as another user for debugging and support.
* [AspNetFormsAuth](https://github.com/Rhetos/AspNetFormsAuth) -
  A backward-compatibility plugin for forms authentication on Rhetos v4 and earlier.

Rhetos components use [IUserInfo](https://github.com/Rhetos/Rhetos/blob/master/src/Rhetos.Core/Utilities/IUserInfo.cs)
interface to retrieve current user information.

* IUserInfo may be customized by registering a new implementation in Rhetos DI container.
  Custom implementation of IUserInfo is intended for applications that do not use standard ASP.NET Core authentication middleware.
  See [Implementing Rhetos authentication plugins](Implementing-Rhetos-authentication-plugins) article
  for more details on the topic.

## Authorization

*Authorization* refers to a process of deciding which operations a user is allowed to perform in the system, and which will be denied.

There are two subsystems available for the authorization of user access in the Rhetos apps.

1. [Basic permissions (Claims)](Basic-permissions)
    * The access rights are typically defined by the roles that a user has (entered by the administrator).
    * The basic element of access is an operation on an entity (read/insert/update/delete) or an action.
2. [Row permissions](RowPermissions-concept)
    * Programmable permissions.
    * The access rights are implemented on an entity to allow some users access **a subset** of the entity's records.
