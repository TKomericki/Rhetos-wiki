## Existing applications should use the old behavior by default, new applications use the new behavior

Add an option in *Web.config* that allows developers to choose between old and new behavior.
This option should be configured so that the new behavior is enable,
but the C# code that checked this option should default to old behavior if this options
is missing (see the code examples below).

* When development of a new applications begins, developers will use this default *Web.config* file
  and the new behavior of the feature by default.
* The old applications usually do not change their *Web.config* when upgrading to the new version
  of Rhetos framework, so the new behavior will be disabled for them by default.

Web.config:

```xml
<appSettings file="ExternalAppSettings.config">
  ...
  <add key="Legacy.OldFeatureName" value="False" />
  or
  <add key="CommonConcepts.Legacy.OldFeatureName" value="False" />
</appSettings>
```

Usage the option in C# code:

```c#
public void SomeMethod(IConfiguration configuration)
{
    if (configuration.GetBool("CommonConcepts.Legacy.OldFeatureName", true).Value)
        ExecuteOldBehavior();
    else
        ExecuteNewBehavior();
}
```
