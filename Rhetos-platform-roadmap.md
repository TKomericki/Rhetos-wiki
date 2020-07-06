This roadmap presents high-level priorities, goals and plans for further development of the platform.
Each point represents a themed group which will be broken into one or more projects during implementation.

The best way to give feedback is to create issues or comment and vote on existing [issues](https://github.com/Rhetos/Rhetos/issues).

## 1. Improving build performance (Rhetos 4.1)

The goal is to speed up the code-build-test development cycle,
by optimizing build process
and improving application startup time.

## 2. Migration to .NET Core (Rhetos 5.0)

With .NET Core gaining so much momentum, especially in the open-source space,
we feel it is a natural next step for Rhetos platform.

We want to fully migrate Rhetos and all its components to .NET Core platform.
Expected benefits are: better performance, modern tooling and cross-platform support.

Please discuss this topic on [Rhetos#119](https://github.com/Rhetos/Rhetos/issues/119).

## 3. Runtime performance

There are many possibilities to improve the runtime performance at the framework level,
that could provide benefits to both new and existing Rhetos applications:
data caching, read scalability, batching database writes and queries (validations),
reducing row permissions to aggregate roots, and other.

## 4. Extending developer's toolset

There is an active list of project [candidates](https://github.com/Rhetos/Rhetos/milestone/11)
on GitHub issues list.
It contains features such as

- DSL concepts for custom business process implementation (BPM),
- Asynchronous and background processing,
- Swagger/OpenAPI integration,
- better support for multitenant applications,
- and others.

Vote or comment on the issues to provide feedback.

## Timeline

This roadmap provides only high-level priorities and plans and does not include a specific timeline.
As development on these points gets planned we will post further information.

The short-term release plan is described with [Milestones](https://github.com/Rhetos/Rhetos/milestones?direction=asc&sort=title&state=open).
See [Release management](Release-management) article for other information on release planning and publishing.

## Previous releases

See [Previous releases](Previous-releases) article for a high-level overview of previous releases,
and [Release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md) for detailed info.
