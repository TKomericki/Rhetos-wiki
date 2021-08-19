Contributions are very welcome!
There are many ways to contribute and participate in our community.

* Asking and answering questions on issues list
* Writing tutorials and other wiki articles
* Framework and plugins development

## Questions, bug reports and features requests

Our [Issues list](https://github.com/Rhetos/Rhetos/issues) is a place to **ask questions**, discuss the existing issues, report a bug or request a new feature.

When creating a new issue, you will be asked to select the issue type: question, bug or feature.

## Writing tutorials and other wiki articles

Tutorials are the most needed content in our community.
If you are looking for inspiration on topics to write on, check out the **planned documentation**
under [Learning resources](https://github.com/Rhetos/Rhetos/issues/118), or any open issues with the [documentation](https://github.com/Rhetos/Rhetos/labels/documentation) tag.

Our documentation is stored on GitHub [wiki](https://github.com/Rhetos/Rhetos/wiki) pages.
Contributions are done by [creating a fork](https://help.github.com/articles/fork-a-repo/)
from the repository at <https://github.com/Rhetos/Rhetos-wiki>,
and submitting the pull requests there.

* [Clone](https://help.github.com/en/articles/cloning-a-repository) your online copy (fork) of the Rhetos-wiki repository on your disk, edit the documentation files in a text editor, commit and push the changes, then create the pull request when done.

How to write documentation:

* The wiki pages are written in [markdown format](https://guides.github.com/features/mastering-markdown/).
  * Use an offline text editor with **spell checker** and **markdown lint tool**
    to make sure there are no issues with the text formatting.
  * We recommend using **VS Code** with installed plugins:
   "Spell Right", "markdownlint" and "Markdown All in One".
  * Skip the first-level heading in the article, because the GitHub wiki adds it automatically.
* Rhetos **DSL code snippets (.rhe)** should be written as a
  [fenced code block](https://help.github.com/articles/creating-and-highlighting-code-blocks/),
  marked with "c" language identifier.
  This will provide at least a minimal syntax highlighting that shows comments and strings.

Please see the additional guidelines for [Writing tutorial articles](Writing-tutorial-articles).

## Framework and plugins development

When deciding on what to change and how to implement the change, use our [Issues list](https://github.com/Rhetos/Rhetos/issues) for **ideas**, **community requests** and **discussion on the implementation details**. Additionally, [Roadmap](Rhetos-platform-roadmap) contains information on our long-term goals and the general direction of development.

Contributions are done by [creating a fork]((https://help.github.com/articles/fork-a-repo/)) from the source repository (Rhetos or any [plugin](https://github.com/Rhetos)), and submitting the pull request after completing the changes. The first time you make a pull request, you may be asked to sign a Contributor Agreement.

Before submitting a pull request:

* Check if your code conforms to the [Rhetos coding standard](Rhetos-coding-standard).
* Open command prompt and run `CleanBuildDeployTest.bat`, and check the the last output line
  is `CleanBuildDeployTest.bat SUCCESSFULLY COMPLETED.`
  * This batch script runs a clean build and all unit tests.
  * Before running the script, edit `Source\Rhetos\RhetosPackages.config` to contain
    line `<package id="Rhetos.CommonConceptsTest" source="..\..\CommonConcepts\CommonConceptsTest" />`.
  * Note that Rhetos contains two types of unit tests: standard unit tests (in Rhetos.sln),
    and integration tests (in CommonConceptsTest.sln). This batch script will build and deploy
    the test application in `Source\Rhetos` subfolder, in order to run the integration tests.
* Some changes that could break the backward compatibility should be implemented with a legacy-support option:
  [Backward compatible feature implementation](Backward-compatible-feature-implementation-in-Rhetos-and-CommonConcepts)

## See also

* [Release management](Release-management)