Rhetos DSL concept is the base of the Rhetos DSL platform.
It consists from declaration of the DSL keyword and the implementation behind it.
The CommonConcepts Rhetos package already implements a number of DSL concepts which can be used to build your application.

However, if you need some specific business rule or mechanism that is repetitive
the best way to implement it is to write your own Rhetos DSL concept.

The new concept can be implemented as a part of your application,
or as a stand-alone Rhetos plugin that can be shared between multiple projects.

Table of contents:

1. [What is Rhetos DSL concept](#what-is-rhetos-dsl-concept)
2. [How it works](#how-it-works)
3. [How to write a macro concept](#how-to-write-a-macro-concept)
4. [How to write a concept with code generator](#how-to-write-a-concept-with-code-generator)
5. [How to deploy created concept](#how-to-deploy-created-concept)
6. [Advanced topics](#advanced-topics)
   1. [Dependency between code generators](#dependency-between-code-generators)
7. [See also](#see-also)

## What is Rhetos DSL concept

As stated before, Rhetos DSL concept is the base of the Rhetos DSL platform.
From an application developer's perspective Rhetos DSL concept is a DSL keyword which
assumes some syntax and functionality, and can be used to declare some data structure,
business rule, etc.

From a platform developer's perspective Rhetos DSL concept is a structured way
to develop some functionality and bring it to the application developer.
This new functionality can then be used any number of times only by stating
specific keyword in the application's DSL script.

For example, let's say that we need to ensure all the phone numbers in our
application must be stated in a structured way.
We can do that by adding a regex validation to all the properties which contains
a phone number. Something like this:

```c
Module Bookstore
{
    Entity Employee
    {
        ShortString PrimaryPhoneNumber { RegexMatch "[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*" "Invalid phone number format."; }
        ShortString SecondaryPhoneNumber { RegexMatch "[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*" "Invalid phone number format."; }
        ShortString FaxNumber { RegexMatch "[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*" "Invalid phone number format."; }
        ShortString MobileNumber { RegexMatch "[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*" "Invalid phone number format."; }
    }
}
```

The DSL way of implementing the same feature is to write a new concept and use that concept,
instead of repetitive copying the same code.
After writing such a concept (let's say we call it PhoneNumber),
we can then use it in our DSL script like this:

```c
Module Bookstore
{
    Entity Employee
    {
        PhoneNumber PrimaryPhoneNumber;
        PhoneNumber SecondaryPhoneNumber;
        PhoneNumber FaxNumber;
        PhoneNumber MobileNumber;
    }
}
```

Implementing functionality this way is not only more elegant and human readable,
but also easier to test and change in the future, since the implementation is centralized.

## How it works

From a Rhetos DSL platform perspective concept is a code generator which inserts
a specific part of code to a specific place in already generated code.
One concept depends on the other, and that's how your code is structured from your DSL scripts.
Bearing that in mind, we have the following types of DSL concepts:

* concept with code generator - concept that defines a DSL keyword and has a code generator which implements functionality
* macro concept - a simple concept which does not generate code directly, instead it generates a couple of other concepts to implement some functionality
* mixed concept - combination of two types mentioned above

Choosing of what type of concept to implement depends on functionality that we want to achieve.

## How to write a macro concept

What every concept needs is definition of it's DSL syntax.
This is done by implementing IConceptInfo interface and exposing it via MEF (using Export attribute).
IConceptInfo interface is defined in Rhetos.Dsl.Interfaces assembly which is part of Rhetos core.
You also need to define a DSL keyword for your concept this is done by adding ConceptKeyword attribute
(defined in the same assembly).
Naming convention for the concept definition class is \<ConceptKeyword>Info (e.g. PhoneNumberInfo).
You can define concept definition class from scratch or inherit an existing one, depends on what your requirements are.
Let's try to write the PhoneNumber concept from previous example.
Phone numbers are stored in string properties so we will build our new concept around ShortString concept
(defined in Rhetos.Dsl.DefaultConcepts assembly).

Example:

```csharp
using System.ComponentModel.Composition;
using Rhetos.Dsl;
using Rhetos.Dsl.DefaultConcepts;

namespace MyFirstConcept
{
    [Export(typeof(IConceptInfo))]
    [ConceptKeyword("PhoneNumber")]
    public class PhoneNumberInfo : ShortStringPropertyInfo
    {
    }
}
```

This code alone does exactly the same as ShortString concept.
Now, we have to provide some additional functionality,
and that is to add regex validation of the phone number.
This is done by implementing IConceptMacro interface and exposing it via MEF (using Export attribute):

```csharp
using System.ComponentModel.Composition;
using Rhetos.Dsl;
using Rhetos.Dsl.DefaultConcepts;

namespace MyFirstConcept
{
    [Export(typeof (IConceptMacro))]
    public class PhoneNumberMacro : IConceptMacro<PhoneNumberInfo>
    {
        public IEnumerable<IConceptInfo> CreateNewConcepts(PhoneNumberInfo conceptInfo, IDslModel existingConcepts)
        {
            return new IConceptInfo[]
            {
                new RegExMatchInfo
                {
                    Property = conceptInfo,
                    RegularExpression = "[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*",
                    ErrorMessage = "Invalid phone number format."
                }
            }
        }
    }
}
```

With those two classes you have just created your first macro concept.

## How to write a concept with code generator

Defining the IConceptInfo implementation for the concept is the same as for the macro concept.
Now we have to define a code generator in which we will implement wanted functionality.
This is done by implementing IConceptCodeGenerator interface (defined in Rhetos.Compiler.Interfaces assembly).

Let's say we have to implement additional functionality for an Entity with a Deactivatable statement:
When Delete function is called, the given record **needs to be deactivated** instead of deleted.

Note that the existing Deactivatable concept simply adds a `bool Active` property, without any automation.
See the article [Implementing simple business rules](Implementing-simple-business-rules)
for more info on the Deactivatable concept.

In order to create new concept, it is required to add two NuGet packages `Rhetos` and `Rhetos.CommonConcepts`.
If the `Export` attribute is not recognized, add an assembly reference to `System.ComponentModel.Composition`.

First, we will implement ConceptInfo for this new concept:

```csharp
using System.ComponentModel.Composition;
using Rhetos.Dsl;
using Rhetos.Dsl.DefaultConcepts;

namespace Htz.RhetosConcepts
{
    [Export(typeof(IConceptInfo))]
    [ConceptKeyword("DeactivateOnDelete")]
    public class DeactivateOnDeleteInfo : IConceptInfo
    {
        [ConceptKey]
        public DeactivatableInfo Deactivatable { get; set; }
    }
}
```

Now we must implement IConceptCodeGenerator interface and add wanted functionality:

```csharp
using System;
using System.ComponentModel.Composition;
using Rhetos.Compiler;
using Rhetos.Dom.DefaultConcepts;
using Rhetos.Dsl;
using Rhetos.Extensibility;

namespace Htz.RhetosConcepts
{
    [Export(typeof(IConceptCodeGenerator))]
    [ExportMetadata(MefProvider.Implements, typeof(DeactivateOnDeleteInfo))]
    public class DeactivateOnDeleteCodeGenerator : IConceptCodeGenerator
    {
        public void GenerateCode(IConceptInfo conceptInfo, ICodeBuilder codeBuilder)
        {
            var info = (DeactivateOnDeleteInfo)conceptInfo;

            var code = String.Format(
            @"var deactivated = deleted.ToList();

            foreach(var item in deleted)
                item.Active = false;

            updated = updated.Concat(deleted).ToArray();
            updatedNew = updatedNew.Concat(deleted).ToArray();

            deleted = new Common.Queryable.{0}_{1}[]{{}};
            deletedIds = new {0}.{1}[]{{}};
            ",
                info.Deactivatable.Entity.Module.Name,
                info.Deactivatable.Entity.Name);

            codeBuilder.InsertCode(code, WritableOrmDataStructureCodeGenerator.OldDataLoadedTag, info.Deactivatable.Entity);
        }
    }
}
```

As you can see, this is where it gets a bit tricky.
In order to write a code generator you have to know exactly where to place your code
and the context in which your code will be run.
There is no other way of finding that out but to browse already generated code
(e.g.. ServerDom.Repositories.cs that can be found in Generated subfolder of your Rhetos server),
and Rhetos core source code itself.
Best way of doing this is to find similar functionality in
[CommonConcepts](https://github.com/Rhetos/Rhetos/tree/master/CommonConcepts) and work from there.
After a while you will get a hang of it and navigate through code generators and generated relatively easy.

Now that we have created a new concept **DeactivateOnDelete**, we can use it in a DSL script, for example:

```c
Entity Book
{
    ShortString Code { Unique; Required; }
    ShortString Title { Required; }
    Integer NumberOfPages;

    Deactivatable { DeactivateOnDelete };
}
```

## How to deploy created concept

To deploy a newly created Rhetos DSL concept you need to
[create a Rhetos package](Creating-a-Rhetos-package) and add your binaries to it,
or add them to an existing Rhetos package.

## Advanced topics

### Dependency between code generators

Code generator should use tags (for example `InsertCode(..., concept, tag)` or `tag.Evaluate(concept)`)
*only* for the concepts that it references directly or indirectly.
For example, a code generator for EntityInfo concept should only use tags for EntityInfo,
DataStructureInfo (base class) and for ModuleInfo in which the entity is placed,
because the EntityInfo class has a property that references ModuleInfo.

* If this rule is not followed, then Rhetos may not be aware of the dependencies
  between the code generators.
  Deployment might fail with error `Generated script does not contain tag ...`
  if the code generator that *uses* some tag is executed
  before the code generator that *adds* this tag.
* You may test if your code generators have consistent dependencies,
  by checking if deployment runs successfully with different internal ordering of concepts:
  Run the deployment once with [build configuration](Configuration-management#build-configuration) settings
  `<add key="InitialConceptsSort" value="Key" />`, then with
  `<add key="InitialConceptsSort" value="KeyDescending" />`
  *(available since Rhetos v4.0)*.
  If using Rhetos.MSBuild, see [Build configuration](Configuration-management#build-configuration)
  section for configuration settings placement.

## See also

* Read [Developing new DSL concepts](Rhetos-coding-standard#developing-new-dsl-concepts)
  in the Rhetos coding standard, for **naming convention** and **design principles**
  when developing new concepts.
