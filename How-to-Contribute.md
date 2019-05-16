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
Contributions are done by [creating a fork]((https://help.github.com/articles/fork-a-repo/)) from the **[Rhetos-wiki](https://github.com/Rhetos/Rhetos-wiki) repository**, and submitting the pull requests there.

How to write documentation:

* The wiki pages are written in [markdown format](https://guides.github.com/features/mastering-markdown/).
  * Use an offline text editor with **spell checker** and **markdown lint tool** to make sure there are no issues with the test formatting. For example, use *VS Code* with plugins: "Spell Right", "markdownlint" and "Markdown All in One" to write the documents.
  * Skip the first-level heading in the article, because the GitHub wiki adds it automatically.
* Rhetos **DSL code snippets (.rhe)** should be written as a
  [fenced code block](https://help.github.com/articles/creating-and-highlighting-code-blocks/),
  marked with "c" language identifier.
  This will get us at least a minimal syntax highlighting that shows comments and strings.

Please see the specific guidelines for [Writing tutorial articles](Writing-tutorial-articles).

## Framework and plugins development

When deciding on what to change and how to implement the change, use our [Issues list](https://github.com/Rhetos/Rhetos/issues) for **ideas**, **community requests** and **discussion on the implementation details**. Additionally, [Roadmap](Rhetos-platform-roadmap) contains information on our long-term goals and the general direction of development.

Contributions are done by [creating a fork]((https://help.github.com/articles/fork-a-repo/)) from the source repository (Rhetos or any [plugin](https://github.com/Rhetos)), and submitting the pull request after completing the changes. The first time you make a pull request, you may be asked to sign a Contributor Agreement.

Before submitting a pull request:

* Please run the unit tests before submitting the pull request.
  Rhetos contains two types of unit tests: standard unit tests (in Rhetos.sln), and integration tests (in CommonConceptsTest.sln) that can be run only after a successful deployment.
* Check if you code conforms to the [Rhetos coding standard](Rhetos-coding-standard).
* Some changes that could break the backward compatibility should be implemented with a legacy-support option:
  [Backward compatible feature implementation](Backward-compatible-feature-implementation-in-Rhetos-and-CommonConcepts)
