## Release types and versioning

We are using [Semantic Versioning](https://semver.org/) for version numbering. There are 3 type of releases, each is marked by increasing the corresponding part of the version number ("major.minor.patch").

* **Major release** - Major changes, possibly breaking backward compatibility.
* **Minor release** - This is most common type of release, usually contains some new features and bug fixes.
* **Patch** - Usually contains a critical bug fix. For each minor release version, application developers should always use the latest patch version.

Each of those 3 types of releases is built and published in the same way and contain the same build artifacts.

## Milestones and planning

Major and minor releases:

* A minor release is expected to be published **once per month**.
  The next minor releases are planned ahead with GitHub [Milestones](https://github.com/Rhetos/Rhetos/milestones?direction=asc&sort=title&state=open).
* A major release is published less often, depending on the basic technology changes or major changes in development process. See [Previous major releases](Previous-releases).
* Long-term plans are described in [Rhetos roadmap](Rhetos-platform-roadmap).

Patches are released as needed (*ad hoc*), when a critical fix is required for an existing release.

A list of **previous releases**, with description of the changes made is available at  [Release notes](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md).

## How to build and publish a new release

The release process is described in the article [Releasing a new Rhetos version](Releasing-a-new-Rhetos-version).
