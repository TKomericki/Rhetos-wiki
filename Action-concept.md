The `Action` concept is intended for implementing server commands that are available as web API methods.
The action's code will be execution in a single transaction,
so that in case of an error the whole action will be canceled (all-or-nothing).

Contents:

1. [Create an action](#create-an-action)
2. [Execute an action](#execute-an-action)
3. [Using external code when developing actions](#using-external-code-when-developing-actions)
   1. [How to use an external class in an Action code snippet](#how-to-use-an-external-class-in-an-action-code-snippet)
   2. [How to use an external class in an Action with dependency injection](#how-to-use-an-external-class-in-an-action-with-dependency-injection)
   3. [How to avoid circular dependencies between the external class and the generated object model (ServerDom)](#how-to-avoid-circular-dependencies-between-the-external-class-and-the-generated-object-model-serverdom)
4. [Example for the ExtAction concept](#example-for-the-extaction-concept)
5. [BeforeAction concept](#beforeaction-concept)

## Create an action

The action can be implemented in two ways:

* Using the `Action` concept, which assumes writing the C# code directly in the .rhe script, or in a referenced .cs script file.
* Using the `ExtAction` concept, where the C# code is implemented in a plugin DLL.

Both ways have their pros and cons, and the choice depends on a situation. The `Action` concept is good for simple code snippets, while `ExtAction` is usually used for more complex implementations.

Tips:

* Action is executed in a single transaction. This means that it is not possible to log an exception error in the database.
* Row permission and other security claims are not checked inside the action.
  * The user need to have permission to execute the action (has the *Execute* claim on the action),
      but not for the resources that are used inside the action. The code inside the action has access to all data.
  * The user's permission can be explicitly checked in the action by using `Common.RowPermissionsReadItems`
      and `Common.RowPermissionsWriteItems` filters, or `IAuthorizationManager` for checking security claims.
* Reference property in the action parameters will not be bound the the database by the ORM (the lazy-load is not supported).
  Also the whole entity cannot be sent as a reference property parameter.
* Exceptions that are cached in the action must be rethrown.

Example:

```C
Module Demo
{
    Action CreatePrincipal '(parameter, repository, userInfo) =>
    {
        var principal = new Common.Principal
        {
            ID = parameter.ID ?? Guid.NewGuid(),
            Name = parameter.Name
        };
        repository.Common.Principal.Insert(principal);
    }'
    {
        Guid ID;
        ShortString Name;
    }
}
```

## Execute an action

1. The execute an action from a client application, see Actions in
   [REST service specification](https://github.com/Rhetos/RestGenerator/blob/master/Readme.md#actions).
2. The execute an action in C# code from the Rhetos application,
   see [Using the Domain Object Model](Using-the-Domain-Object-Model#execute-action)

## Using external code when developing actions

### How to use an external class in an Action code snippet

For example, an Action can call an external method `string CreateUniqueName()`, implemented in class `MyNamespace.MyClass`, in a separate DLL `MyAssembly.dll`.

For older Rhetos applications built with DeployPackages, in the DSL script add the `ExternalReference` statement,
so that the generated object model references the DLL in which your class is implemented.

```C
Module Demo
{
    ExternalReference 'MyNamespace.MyClass, MyAssembly';

    Action CreatePrincipal '(parameter, repository, userInfo) =>
    {
        var nameGenerator = new MyNamespace.MyClass();
        var principal = new Common.Principal
        {
            ID = parameter.ID ?? Guid.NewGuid(),
            Name = nameGenerator.CreateUniqueName()
        };
        repository.Common.Principal.Insert(principal);
    }'
    {
        Guid ID;
    }
}
```

### How to use an external class in an Action with dependency injection

1. Implement the custom class that requests other dependency injection components as constructor parameters.
   For older applications that use DeployPackages, the class must be implemented in a separate C# library project (DLL).
2. Register your class to the [Autofac](https://autofac.org/) dependency injection container
    * See example of how to register your plugin’s classes: <https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/Plugins/Rhetos.Dom.DefaultConcepts/AutofacModuleConfiguration.cs>
    * The singleton class should be registered to [Autofac](https://autofac.org/) container as a “SingleInstance” component. For other component registration options please refer to Autofac documentation: <https://autofaccn.readthedocs.io/en/latest/register/registration.html>
3. This class can then be used in the Action concept by adding it to the Action’s repository with `RepositoryUses` concept.
    * See example in the unit test DSL script: <https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/DataStructure.rhe>
    * In this example the RepositoryUses concept adds the `_logProvider` member property to be used in the Action’s code snippet. In that line you can see the property type `ILogProvider` (here you can use that singleton class name instead of the interface) and the assembly where the type is implemented “Rhetos.Logging.Interfaces.dll” (without the .dll extension).

### How to avoid circular dependencies between the external class and the generated object model (ServerDom)

> NOTE: This section describes an issue that occurs on applications that use old Rhetos
build process with DeployPackages. New application with Rhetos CLI (Rhetos.MSBuild) should implement
the custom classes directly in the application, thus avoiding any circular dependencies between the
custom classes and generated source from DSL scripts.

The examples above work only for external classes that do not reference the generated object model (ServerDom).
If the external class referenced the ServerDom, and the Action references the class, this would result with a circular dependency between the DLLs.

In such situations, one of the dependencies needs to be removed. There are two options:

* Reflection can be used in the `Action` code snippet to invoke the external method. The `ExtAction` concept is just a helper that does the same.
* The external class can use generic repository interfaces instead of directly referencing the ServerDom.
  * This can be done by using some of the helper classes and interfaces from the Rhetos.CommonConcepts nuget: GenericRepositories, GenericRepository, IRepository, IQueryableRepository, IReadableRepository or IWritableRepository.
  * The data (the properties of the loaded entities) can be accessed by using `dynamic` C# objects, or by creating interfaces that the Entity will implement in the DSL script. For examples see `Implements` keyword in [Security.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/DslScripts/Security.rhe).
  * In this case, the dependency injection pattern should be used, so that the external class can get all other components from the system in it's constructor (for example, the GenericRepositories instance). See "How to" above.

## Example for the ExtAction concept

DSL:

```C
Module Demo
{
    ExtAction CreatePrincipal 'Demo.Rhetos.Principals, Demo.Rhetos' 'CreatePrincipal'
    {
        Guid ID;
        ShortString Name;
    }
}
```

C#:

```C#
// This method is implemented in the assembly Demo.Rhetos, in class Principals.
public static void CreatePrincipal(CreatePrincipal parameter, DomRepository repository, IUserInfo userInfo)
{
    var principal = new Common.Principal
    {
        ID = parameter.ID ?? Guid.NewGuid(),
        Name = parameter.Name
    }

    repository.Common.Principal.Insert(principal);
}
```

## BeforeAction concept

If you are using an action that is already implemented in another package and you want to extend that action you can use the concept BeforeAction.
The code snippet of the BeforeAction concept will be executed before the Action is executed.

```C
BeforeAction Demo.CreatePrincipal.AppendUnderscoreToUsername '
    actionParameter.Name += "_";
';
```
