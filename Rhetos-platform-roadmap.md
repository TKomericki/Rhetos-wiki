This roadmap presents high-level priorities, goals and plans for further development of the platform. Each point represents a themed group which will be broken into one or more projects during implementation.

## 1. Better IDE experience

* Embedded C# code IntelliSense
* Better Rhetos DSL IntelliSense
* Seamless build workflow

We want to significantly improve overall experience of developing Rhetos based applications. Specifically, primary focus is to provide full IntelliSense and static code analysis features for Rhetos DSL code as well as embedded C# code used in it.

We would also like developers to be able to seamlessly run (and debug) their Rhetos based applications from within IDE in the same way they can run a regular C# application.

Please discuss this topic on [Rhetos#49](https://github.com/Rhetos/Rhetos/issues/49).

## 2. Complex web API methods

The existing REST service exposes only simple objects by default. For example, if developer needs to read or write a master-detail object in a single request, a custom code must be developed, sometimes with custom data serialization within already serialized web requests.

Our goal is to allow developers to simply create view-models or DTOs, including complex hierarchical objects, using only declarative code, without need for developing middleware service or custom web methods.

Please discuss this topic on [Rhetos#50](https://github.com/Rhetos/Rhetos/issues/50).

## 3. Migration to .NET Core

With .NET Core gaining so much momentum, especially in the open-source space, we feel it is a natural next step for Rhetos platform.

We want to fully migrate Rhetos and all its components to .NET Core platform. Expected benefits are: better performance, modern tooling and cross-platform support.

Please discuss this topic on [Rhetos#119](https://github.com/Rhetos/Rhetos/issues/119).

## Timeline

This roadmap provides only high-level priorities and plans and does not include a specific timeline.
As development on these points gets planned we will post further information.

The short-term release plan is described with [Milestones](https://github.com/Rhetos/Rhetos/milestones?direction=asc&sort=title&state=open).
See [Release management](Release-management) article for other information on release planning and publishing.

## Related resources

* [Release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md) for previous releases
