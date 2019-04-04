Rhetos CommonConcepts package contains some simple business rules that are common in many applications.
Then can often be used by simply declaring them on an entity or a property.

Contents:

1. [Property value constraints](#property-value-constraints)
2. [Deny data modifications](#deny-data-modifications)
3. [Automatically generated data](#automatically-generated-data)
4. [Logging data changes and auditing](#logging-data-changes-and-auditing)
5. [Other features](#other-features)
6. [See also](#see-also)

## Property value constraints

Property value constraints are simple business rules that can be declared beside the property in the .rhe script.
The following concepts are available in CommonConcepts package:

* `MinValue` - Limit the smallest allowed value of the property.
* `MaxValue` - Limit the largest allowed value of the property.
* `MinLength` - Limit the smallest allowed length of the string.
* `MaxLength` - Limit the largest allowed length of the string.
* `RegExMatch` - Use a regular expression to validate the property value.
* `Required` - a property value must be entered when saving a records.
  * There are two subvariant of this concept:
    * `SystemRequired` - The user does not need to enter the property value, but it's value should be entered (perhaps automatically by some other business rules).
    * `UserRequired` - User (or client applications) needs to provide the property value.
  * Note: Required properties are still created with nullable types in C# and database. Then validation in implemented in Save method.

For more complex data validations a specific filter can be developed. Such validations are built in two steps:

1. Create a filter on the entity. In the example below, the filter FinishBeforeStart returns every Employee with invalid data (WorkFinished is before WorkStarted).
2. Create a validation for that filter with the message for the used. The validation will return the error message to the user it he or she tries to enter the invalid data.

```C
Entity Employee
{
    Integer IdentificationNumber;
    ShortString LastName { Required; }
    ShortString FirstName { Required; }
    ShortString Jmbg { RegExMatch "\d{13}" "Must contain 13 digits."; }
    DateTime WorkStarted { Required; }
    DateTime WorkFinished;
    Integer TestPeriod { MinValue 1; MaxValue 12; }
    ShortString Iban { Required; MinLength 21; MaxLength 21; }

    ItemFilter FinishBeforeStart 'employee => employee.WorkFinished != null
        && employee.WorkFinished.Value < employee.WorkStarted.Value';
    InvalidData FinishBeforeStart 'It is not allowed to enter a WorkFinished time before the WorkStarted time.';
}
```

## Deny data modifications

The following business rules are similar to data validations, but actually act more like action permissions.
Instead of of checking if a certain data value *is valid or not*, they just block certain operations depending on the context.
Examples of the following concepts are available in a unit testing DSL script
[Validations.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/Validations.rhe).

* `Lock` - Deny update and delete of the entity records, for records in a certain state (provided by a filter).
* `LockProperty` - Deny update of a property, for records in a certain state.
* `LockExcept` - Deny update (except for properties from the provided list) and delete of the entity records, for records in a certain state.
* `DenyUserEdit` on an entity - Client application is not allowed to directly insert, update or delete the entity records (no condition).
* `DenyUserEdit` on a property - Client application is not allowed to directly insert or update the property. On insert and update it is only allowed to send a *null* value (it will be interpreted as "no change" on update), or a previous value.

Similar features and alternatives:

1. If some data operation should be denied based on *which user* that is performing it, you should probably use [Row permissions](RowPermissions-concept) instead of the concepts listed above.
2. If you need a similar operation, but not listed above (for example to deny deleting records in a certain state), it would best to create you own concept based on the implementation of similar one. A more pragmatic option is to directly insert a C# code snippet into the entity's Save method (by using low-level concepts SaveMethod with Initialization or OnSaveValidate), and check it the Save operation should be blocked. Some code samples are available in [DataStructure.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/DataStructure.rhe) script, with a realistic example at `OnSaveValidate DenyChangeOfLockedName`.

## Automatically generated data

* `DefaultValue` - Generate the default property value when inserting a new record.
* `AutoCode` - A property marked with AutoCode will automatically increase by one for each new record. When inserting a new record, the initially entered value is interpreted as a format for generating the code. It supports the following formatting:
  * Multiple digits with with leading zeros: for example, if "+++" is entered, a three-digit number will be created (001, 002, 003, ...)
  * Prefix: for example, if "BOOK+" is entered, the generated codes will be BOOK1, BOOK2, BOOK3, ....
  * Combination of the above.
  * If the entered value is not a valid format (it does not end with a "+"), then it is save as is provided. This allows saving new codes directly when a user/client need to specify the code.
  * `AutoCode`, `DenyUserEdit` and `DefaultValue` are often used on the same property to indicate that the property code are automatically generated, user cannot enter it's own code or code format, and the DefaultValue provide the number format (if it not simple 1, 2, 3, ...).
  * `AutoCode` supports Integer and ShortString property types.
* `AutoCodeForEach` - Same as `AutoCode`, but the numbers are starting from 1 within each group of records. The group is defined by some another property value.
* `CreationTime` - Automatically enters time when the records was created.
* `ModificationTimeOf` - Automatically enters time when some given property was last updated.

Code examples for **DefaultValue** are available in DSL script [DefaultValueTest.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/DefaultValueTest.rhe) script.

Code examples for **AutoCode**, **CreationTime** and **ModificationTimeOf** are available in DSL script [SimpleBusinessLogic.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/SimpleBusinessLogic.rhe) script.

## Logging data changes and auditing

* `Logging` - Creates a database trigger that monitors all inserts, updates and deletes, and writes them to `Common.Log` table.
* `Log` - Extends the trigger to track modified or deleted values for a given property.
* `AllProperties` - Extends the trigger to track modified or deleted values for all entity's properties.

Examples:

```C
Module Demo
{
    Entity Person
    {
        ShortString FirstName;
        ShortString LastName;
        LongString Description;

        Logging
        {
            Log Demo.Person.FirstName;
            Log Demo.Person.LastName;
            // 'Description' property is long and not interesting, so we don't want to log it's values.
        }
    }

    Entity Animal
    {
        ShortString Name;
        Decimal MaxSpeed;

        Logging { AllProperties; }
    }
}
```

See [Logging data changes and auditing](Logging#logging-data-changes-and-auditing) for more information.

## Other features

* `Deactivatable` - Allows tracking of active and deactivated records.
  * Internally, it adds a `Bool Active` property to the entity with the default value True.
  * It creates a composable filter `Rhetos.Dom.DefaultConcepts.ActiveItems`,
    with an optional parameter `ItemID`.
    It returns all active items and additionally the item with the given ID.
    This is a common patter for lookup that needs to display the current item whether it is active or not.
  * Code example is available in DSL script [SimpleBusinessLogic.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/SimpleBusinessLogic.rhe).

* `PessimisticLocking` - Enables automatic verification of explicit client locks when saving a record. A user can change a records only when there is no ExclusiveLock from another user on this record. When editing detail records, only master needs to be locked.
  * A client application can manage the locks with actions Common.SetLock and Common.ReleaseLock, with parameters ResourceType (full entity name) and ResourceID (GUID).
  * Code example is available in DSL script [PessimisticLocking.rhe](https://github.com/Rhetos/Rhetos/blob/master/CommonConcepts/CommonConceptsTest/DslScripts/PessimisticLocking.rhe).

## See also

Examples of many DSL concepts are available in the unit testing setup DSL script in the Rhetos framework source folder [CommonConcepts\CommonConceptsTest\DslScripts](https://github.com/Rhetos/Rhetos/tree/master/CommonConcepts/CommonConceptsTest/DslScripts).
