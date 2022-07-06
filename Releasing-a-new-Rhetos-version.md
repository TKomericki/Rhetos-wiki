This article describes the release process for both Rhetos framework (<https://github.com/Rhetos/Rhetos>) and Rhetos plugins (most of the other repositories in <https://github.com/Rhetos>). Steps that are applied only to Rhetos framework release are marked with [Framework only].

1. Before you start:
    * [ ] Make sure you are working on the latest version of the master branch (git pull).
    * [ ] Check out the [project network](https://github.com/Rhetos/Rhetos/network)
      and [pull requests](https://github.com/Rhetos/Rhetos/pulls) for any forgotten branches.
    * [ ] Check the last [release number](https://github.com/Rhetos/Rhetos/releases) and decide on the new version number.
      A new release usually just increases the minor version by 1 (the second number).
      * Note: The version number format must be compliant with [semantic versioning](https://semver.org/).
    * [ ] List any other plugin packages that also need to be released along with this release.
2. Build:
    * [ ] Update *ChangeLog.md* file based on the commit history since the previous release.
    * [ ] Set the release version number in *Build.bat* file (probably it is already set), and the *Prerelease* to an empty value:
      ```text
      SET Prerelease=
      ```
    * [ ] Run full build in the command prompt: `Clean.bat && Build.bat && Test.bat`.
      * Some Rhetos packages don't contain Clean.bat or Test.bat.
    * [ ] Verity that the build is successful: the console output should end with "Test.bat SUCCESSFULLY COMPLETED.".
    * [ ] [Rhetos v4 and earlier] In the *Install* subfolder: zip the *RhetosServer* folder
          to *RhetosServer.&lt;NEW VERSION&gt;.zip* (for example RhetosServer.1.2.0.zip).
3. Publish:
    * [ ] [Private builds only] Copy the generated files from the Install folder to your company's shared storage.
    * [ ] Commit your repository changes, **except Build.bat file**, with comment "Release &lt;NEW VERSION&gt;.".
      For example "Release 1.2.0.".
      * Note: If there is nothing to commit, simply do the next step on the last commit.
    * [ ] In your repository create a new tag "v&lt;NEW VERSION&gt;" at the last commit ("Release ...").
      For example "v1.2.0".
    * [ ] Push your repository to GitHub (set the option *Include Tags*).
    * [ ] [Private builds only] Publish the new NuGet package to your company's NuGet gallery (ask your system administrator for the location).
    * [ ] Publish the NuGet package(s) to the public [NuGet gallery](https://www.nuget.org/packages/manage/upload).
    * [ ] Publish the *.snupkg* symbols package(s) to the public [NuGet gallery](https://www.nuget.org/packages/manage/upload).
    * [ ] Create a release on GitHub: Open [tags on GitHub](https://github.com/Rhetos/Rhetos/tags)
      => At the tag for the newly released version click "Create release"
      => **Check** that the opened form displays the tag you have just selected.
      * At *Describe this release* write:
        ```text
        See Release notes in [ChangeLog.md](https://github.com/Rhetos/Rhetos/blob/master/ChangeLog.md).
        Rhetos NuGet files are available at [nuget.org](https://www.nuget.org/packages?q=rhetos).
        ```
      * [Rhetos v4 and earlier] Drag & drop the RhetosServer.x.zip file to the "**Attach binaries**" box.
      * Click "Publish release".
4. Prepare the code for further development:
    * [ ] In *Build.bat* increase the second version number by 1 and set the third to 0
          (for example from 1.2.5 to 1.3.0). Set the `Prelease` version to `auto`,
          so that the source is ready for the development of the next release:
      ```text
      SET Version=<CURRENT +0.+1.0>
      SET Prerelease=auto
      ```
    * [ ] Run *Build.bat*.
    * [ ] Commit with comment "Development &lt;NEXT VERSION&gt;.". For example "Development 1.3.0.".
    * [ ] Push the repository to GitHub (set the option *Include Tags*).
