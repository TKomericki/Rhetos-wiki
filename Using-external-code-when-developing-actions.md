# Using external code when developing DSL Actions

> This article applies to Rhetos v4 and earlier versions.
> In Rhetos v5 and later version, the Rhetos app can reference any other project or library,
> and the classes from the referenced assemblies will be automatically available
> in the Action code snippet.

## How to use an external class in an Action code snippet

For example, an Action can call an external method `string CreateUniqueName()`,
implemented in class `MyNamespace.MyClass`, in a separate DLL `MyAssembly.dll`.

For older Rhetos apps built with DeployPackages, in the DSL script add the `ExternalReference` statement,
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

## How to avoid circular dependencies between the external class and the generated object model (ServerDom)

> NOTE: This section describes an issue that occurs on applications with Rhetos v4 and earlier
that use DeployPackages in build process.
Newer application with Rhetos CLI (Rhetos.MSBuild) should implement
the custom classes directly in the application, thus avoiding any circular dependencies between the
custom classes and generated source from DSL scripts.

The examples above work only for external classes that do not reference the generated object model (ServerDom).
If the external class referenced the ServerDom, and the Action references the class, this would result with a circular dependency between the DLLs.

In such situations, one of the dependencies needs to be removed. There are two options:

* Reflection can be used in the `Action` code snippet to invoke the external method.
* The external class can use generic repository interfaces instead of directly referencing the ServerDom.
  * This can be done by using some of the helper classes and interfaces from the Rhetos.CommonConcepts nuget: GenericRepositories, GenericRepository, IRepository, IQueryableRepository, IReadableRepository or IWritableRepository.
  * The data (the properties of the loaded entities) can be accessed by using `dynamic` C# objects, or by creating interfaces that the Entity will implement in the DSL script. For examples see `Implements` keyword in [Security.rhe](https://github.com/Rhetos/Rhetos/blob/master/src/Rhetos.CommonConcepts/DslScripts/Security.rhe).
  * In this case, the dependency injection pattern should be used, so that the external class can get all other components from the system in its constructor (for example, the GenericRepositories instance). See "How to" above.
