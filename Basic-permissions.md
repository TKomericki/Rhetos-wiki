Contents:

1. [Users and roles](#users-and-roles)
   1. [Common administration activities](#common-administration-activities)
   2. [Claims](#claims)
   3. [Permissions](#permissions)
2. [Development](#development)
   1. [Suppressing permissions in a development environment](#suppressing-permissions-in-a-development-environment)
   2. [Automatic user management](#automatic-user-management)
   3. [Inserting the permissions on deployment](#inserting-the-permissions-on-deployment)
3. [See also](#see-also)

## Users and roles

By using a hierarchy of roles, the administrator can create
groups of users and permissions, or connect them directly.

The following diagram shows the Rhetos entities in the *Common* module
that determine the user's roles and permissions.
The diamond shapes represent the associative entities.

![Roles and Claims](images/claims.png)

### Common administration activities

All administration activities are performed by modifying the data in the entities from the diagram above. For example:

* To create a **new user account**, insert the record in the *Common.Principal* entity.
  * If using Windows authentication, enter the full account name: "domain\username".
  * If the forms authentication is used instead,
    check for the additional administration activities in the
    [AspNetFormsAuth documentation](https://github.com/Rhetos/AspNetFormsAuth/blob/master/Readme.md).
* To create **new roles** and define the **role permissions**, enter the data in *Common.Role* and *Common.RolePermission*.
  Some roles and the role permissions are usually preconfigured by the development team while developing the application.
* To configure the **user's permissions**, enter the data in *Common.PrincipalHasRole*
  (this will provide the permissions from the selected roles).
  Alternatively, a user can have  or *Common.PrincipalPermission*.

### Claims

Each record in a *Common.Claim* entity represents a basic element of access permission:
an operation on a resource (entity, action, ...) that can be allowed or denied.

The list of claims is created on deployment, and does not change during run-time.
There are claims generated for each of the following objects:

* For each entity: Read, New, Edit, Remove
* For each read-only data structure: Read
* For each action: Execute
* For each report: Download

Please note that the records in *Common.Claim* table are automatically updated on each deployment.
If a new custom claim is inserted into the table manually or by a DataMigration script,
it will be automatically removed (deactivated) on the next deployment.

A custom claim can be created in a DSL script by using the CustomClaim concept. Example:

```C
CustomClaim 'SomeModule.SomeResource' 'CustomOperationName';
```

### Permissions

User's permissions are defined here a **set of claims** that a certain user has.
They are represented in the system by connecting principals with the claims,
through tables *Common.PrincipalPermission* and *Common.RolePermission*.
The end result is a union of all permissions that are assigned
to the user directly or from the user's roles.

Denying permissions:

* All claims are denied by default, and added with user's and role's permission.
* Sometimes it is difficult to set up a purely additive system of roles and permissions. For example, if a user inherits some permissions (claims) from a certain role, but you need to remove some of those permissions without modifying this role, you can explicitly deny this permissions by setting `IsAuthorized = 0` in *PrincipalPermission* or *RolePermission* (with an additional role).
* Deny will always override the allowed permissions from other roles, so if the user has a certain permission allowed by one of his roles and denied by some other role, at the and the permission will be denied.
* Please note that denying permissions should be used as a **rare exception** because it complicates the administration of the permissions in the future.

## Development

### Suppressing permissions in a development environment

Suppressing permissions is useful only in an early stage of the project, while prototyping.
It allows developers to test the new features without need to manage users, roles and permissions.

The basic permission checking can be turned off in a development environment by setting the following options in the Rhetos server's **web.config** file.

1. **"Security.AllClaimsForUsers"** - The value should contain a comma-separated
   list of users with server computer name (formatted `username@servername, ...`)
   that will automatically have full permissions. Examples:
   * Domain user on a shared server:
     `<add key="Security.AllClaimsForUsers" value="mydomain\myusername@myserver" />`.
   * Local windows user without Windows domain:
     `<add key="Security.AllClaimsForUsers" value="mypc\myusername@mypc" />`.
   * Forms Authentication user "admin":
     `<add key="Security.AllClaimsForUsers" value="admin@myserver" />`.
2. **"BuiltinAdminOverride"** - If set to "True",
   the user that is a local administrator will have full permissions.
   This option works only for Windows authentication, and if the web server
   is able to check the user's Windows groups (usually in development environment).
   Use the AllClaimsForUsers option otherwise.

### Automatic user management

For back-office business applications, an explicit user management is done
by system administrator within the Rhetos application
or any related external source such as Active Directory.

For public web applications, we don't want to manage each user manually.
For example, we might allow anyone to obtain a system account,
or setup default permission for all users.

The following built-in features may help with those business requirements:

1. If `AuthorizationAddUnregisteredPrincipals` option is set to "True"
   in *web.config* file, Rhetos will **automatically add a new user account**
   in table "Common.Principal" on the first login.
   * The created account will have no permissions by default,
     but the additional functionality can be added to automatically initialize
     the user's roles and permissions (for example, by using the
     [ActiveDirectorySync](https://github.com/Rhetos/ActiveDirectorySync) plugin,
     or adding some custom features on entity *Common.Principal*).
   * When this option is set to "False" (default), an administrator needs
     to insert the record in *Common.Principal* before the user can login.
2. For automatic synchronization of Rhetos user roles with
   the **user groups in Active Directory**, add the
   [ActiveDirectorySync](https://github.com/Rhetos/ActiveDirectorySync) plugin package
   to the Rhetos application.
   * This will allow the domain administrator to indirectly set the user permissions in the Rhetos application.

### Inserting the permissions on deployment

There is often a need to insert some permissions as the new version of the application is deployed. This usually means inserting or updating the data in tables *Common.Role*, *Common.RolePermission* or *Common.PrincipalPermission*.

The recommended solution is to include [Rhetos.AfterDeploy](https://github.com/Rhetos/AfterDeploy) package, and write the AfterDeploy SQL scripts that will insert, update or delete the permission records in the database to match the expected permissions.

Note: The DataMigration scripts are often the first solution that comes to mind, but there are issues with this approach:

* DataMigration scripts are intended for incremental modifications. This means that when changing permissions, new DataMigration scripts should be added to correct the existing permissions. It is easier to maintain an AfterDeploy script that is executed on each deployment, that contains a complete list of wanted permissions and updates the records in database to match the list.
* The claims in *Common.Claim* table are generated automatically at the end of each deployment (see the *DeployPackages.log*). The data-migration scripts are executed at the beginning of the deployment, so the inserted permissions will not include the new claims that will be generated at the end. Possible workaround is to insert the claims along with the permissions, but the AfterDeploy script is much better solutions.
* This recommendation to use AfterDeploy scripts is specific to managing permissions. For most other data that needs to be initialized or hard-coded in the database, the DataMigration scripts are recommended way to go, because they will work well with future changes of the database structure.

## See also

* See other options for user authorization in the article [User authentication and authorization](User-authentication-and-authorization).
