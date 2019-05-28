# List of DSL concepts

Contents:

1. [Data model and relationships](#data-model-and-relationships)
2. [Simple business logic](#simple-business-logic)
3. [Calculations](#calculations)
4. [Filters](#filters)
5. [Reports](#reports)
6. [Complex concepts](#complex-concepts)
7. [Server actions](#server-actions)
8. [Claims and permissions](#claims-and-permissions)
9. [SQL objects](#sql-objects)

## Data model and relationships

* **Module** `<name>` - Generates C# namespace and database schema, where the rest of the objects are located at.
* **DataStructure** `<Module>.<name>` - Basic concept for any data structure (e.g. Entity, Browse, Computed, ...) which may contain properties. It is usually not used in DSL script.
* **Entity** `<Module>.<name>` - Data entered by user. Creates C# class and database table. Inherits DataStructure concept.

Simple data types:

* **Binary** `<DataStructure> <field name>`
* **Bool** `<DataStructure> <field name>`
* **Date** `<DataStructure> <field name>`
* **DateTime** `<DataStructure> <field name>`
* **Decimal** `<DataStructure> <field name>`
* **Guid** `<DataStructure> <field name>`
* **Integer** `<DataStructure> <field name>`
* **Money** `<DataStructure> <field name>`
* **ShortString** `<DataStructure> <field name>` - 256 characters max.
* **LongString** `<DataStructure> <field name>` - unlimited length.

Complex data types:

* **Reference** `<DataStructure>.<field name> <referenced data structure>` - Lookup field. Used as type of referenced class in the object model. Represents database FK, having "ID" suffix appended at the column name.
  * **Reference** `<DataStructure>.<field name>` - Simplified syntax in case when the field name is same as the name of the referenced entity.
* **Currency** `<DataStructure>.<field name> <DateQuery> <BankQuery> <RateTypeQuery>` - Complex field containing following data: amount in foreign currency, currency code, amount in local currency and rate.

**Property** means basic concept which is inherited by all abovementioned simple and complex data types, which can be used as any data field.

More concepts:

* **Detail** `<Reference>` - Marks entity as detail of the referenced entity and sets CascadeDelete and SqlIndex.
* **Extends** `<Extension DataStructure>.<base DataStructure>` - Marks first data structure as extension of base data structure. Usually used to extend entity with additional calculated data or to extend legacy entities with the data entered by user. Concept means that extension has the same primary key (ID) value as base records. Extension has to return one record by every base data record.
* **Browse** `<Module>.<name> <original data structure>` - Data structure used to read certain data fields from original data structure. Old name is "SnowFlake".
  * **Take** `<Browse> <field name or references path>` - Creates property on the browse data structure using field name of the original data structure. Beside field naming it can be set by reference path, separated by dot too.
    * Path must be within the quotation marks.
    * If the paths is set, field name will be automatically generated connecting the field from the path (e.g. Take 'Parent.Class.Name'; => ShortString ParentClassName).
    * Beside reference, as path is it possible to use Base (navigation from extension to base class), `Extends_<Extension name>` (navigation from base to extension) and ID (as Guid property).
    * Browse structure can have Reference field (Take Parent, e.g.), which gets Guid ID from the referenced structure (ParentID) and navigation property (Parent). It recommended to use just Guid field (e.g. Take 'Parent.ID';) instead.
  * **Take** `<Browse> <field name> '<reference path>'` - Explicitly sets name of created field at the browse structure.
  * **From** `<Browse Property> <field name or reference path>` - Possible to use referenced data, extended data or base structure data.
    * It is recommended to use Take concept instead From because of simplicity.
* **LegacyEntity** `<Module>.<name> <table> <view>` - Data structure which reads data from the view, used to integrate old entities from existing systems inside Rhetos. Table is used so other Rhetos entities could reference LegacyEntity. Table has to have uniqueidentifier ID field with default `NEWID()` and unique index. LegacyEntity is writeable from Rhetos. If the view is not updateable, it is possible to add instead-of triggers for storing using SqlTrigger.
  * **LegacyEntity** `<Module>.<name> <table>` - Creates view with entity name and according instead-of triggers for data recording.
  * **LegacyProperty**
  * **LegacyPropertyReadOnly**
* **LinkedItems**
* **Implements** `<DataStructure>.<interface type>` - Implementing given interface on the object model data structure.
* **PropertyFrom** `<destination DataStructure> <source Property>` - Copies field from another data structure. Transferring related Required and SqlIndex concepts.
* **AllPropertiesFrom** `<destination DataStructure> <source DataStructure>` - Copies all fields from another data structure as PropertyFrom. Transferring related Extends concept.
* **AllPropertiesWithCascadeDeleteFrom** `<destination DataStructure> <source DataStructure>` - Copies all fields from another data structure as AllPropertiesFrom. Transfers related CascadeDelete concepts (e.g. Detail).
* **LookupVisible** `<Property>` - Sets given property as default browse structure for entity lookup (name of browse structure is "`<EntityName>`Lookup"). If default browse structure is not existent, it will be created. LookupVisible can be used on the reference, which in that case adds Guid to the browse structure and on all LookupVisible fields from the referenced entity. Default browse can be still added manually together with the rest of the fields.
  * **REMARK:** This concept is implemented inside OmegaCommonConcepts package. It is required to include that package during deployment.
* **Clustered** Created cluster SqlIndex and SqlIndexMultiple.
* **Polymorphic** - Defining common interface which implements more entities. Documentation: <https://github.com/Rhetos/Rhetos/wiki/Polymorphic-concept>

## Simple business logic

* **Required** `<Property>` - Required field that must be filled by user.
* **SystemRequired** `<Property>` - System field which must be filled by system internally.
* **Unique** - `<Property>` - Two records cannot have same value inside this field.
  * **Unique** `<DataStructure> <Property1> <Property2>`
  * **Unique** `<DataStructure> <Property1> <Property2> <Property3>`
  * **UniqueMultiple** `<DataStructure> <field names separated by comma>` - One string contains n fields.
* **MaxLength** `<Property>` - Limited string length in ShortString or LongString field. Limits higher range.
* **MinLength** `<Property>` - Limited string length in ShortString or LongString field. Limits lower range.
* **Range** `<PropertyFrom> <PropertyTo>` - Value of the first field has to be less or equal to the second field (fields have to be of the same type).
  * **DateRange** `<PropertyFrom> <PropertyTo>` - Derivation of Range which creates Date Field in case they are not existent.
  * **DateTimeRange** `<PropertyFrom> <PropertyTo>` - Derivation of Range which creates DateTime fields in case they are not existent.
  * **IntegerRange** `<PropertyFrom> <PropertyTo>` - Derivation of range which creates Integer fields in case they are not existent.
* **RegExMatch** `<Property>` - Text must match given regex expression.
* **AutoCode** `<ShortString property>` - Generates integer codes with the given prefix. This concept includes Unique and Index.
  * **AutoCodeForEach** `<ShortString property> <grouping property>` - Generates integer codes with the given prefix, using independent count for each group.
* **Logging** `<entity>` - Includes logging all entity changes. It is required to set the properties from which changes should be tracked.
  * **Log** `<Logging <Property>` - Sets properties which changes are tracked.
  * **AllProperties** `<Logging>` - Enables logging on all properties.
* **CascadeDelete** `<Reference>` - During the delete process, all related entities will be deleted.
* **PessimisticLocking** `<Entity>` - Sets server check during entity recording so the user can save data only if there is no ExclusiveLock on the data record or if the user is owner of the lock. During editing entity detail, it is required only to set the lock to the master entity.
  * To set the lock, client application must use Common.SetLock and Common.ReleaseLock actions. It also can use those actions on the entities which do not have the PessimisticLocking on but then the conflict protection depends only on check at the client, having risk of some another application not respecting those locks.
  * Common.SetLock and ReleaseLock server actions, accept ResourceType as parameter, (e.g. "Material.Asset") and ResourceID (Guid).
* **CreationTime** `<DateTime property>` - Stores records creation time.
* **ModificationTimeOf** `<DateTime property> <Modified property>` - Stores time of the update for the given field at the same entity.
* **Deactivatable** `<Entity>` - Enables deactivation of the entity:
  * Adds **Bool Active** property which sets the mark if the entity is active or not. Default values are those so the client doesn't have to be aware of that field: During the data recording, default value is true, while during the update process, default value is the old value.
  * Creates composable filter **ActiveItems** with the optional **ItemID** parameter. Filter returns all active records with the given ID record depending on the status of the entity. Useful for implementation of lookup.
    * Because of the bug at the new REST API, while having "filters" as parameter, it is required to specify full filter name (assembly qualified name): "Rhetos.Dom.DefaultConcepts.ActiveItems, Rhetos.Dom.DefaultConcepts.Interfaces".
  * GenericRepository has ability to InsertOrUpdateOrDeleteOrDeactivate which can be used to deactivate deleted records.
  * **DenyUserEdit** `<Entity>` - Entity with hardcoded data. It is not allowed to make changes using web interface (REST/SOAP).
  * **DenyUserEdit** `<Property>` - Not allowed to edit field values using web interface (REST/SOAP). Remark: It is considered not good practice to combine fields at the same entity, which user can and cannot edit. It is recommended to separate those calculated fields on the entity extension.

## Calculations

Basic calculation types:

* **Computed** `<Module>.<name> <repository => C# script ... Result[]>`
* **SqlQueryable** `<Module>.<name> <SQL script>` - Queryable calculation, defined inside SQL script. Creates new database view by the given script. This concept should be used with SqlDependsOn concept, so the database objects could be created at required order.

Additional concepts:

* **QueryableExtension** `<Module>.<name> <source DataStructure> <(IQueryable<source> source, repository) => ... IQueryable<Result>>` - Extension concept which defines easier calculations like aggregate data on the header of the document, financial consequence of document item and similar. Types which are returned by expression should have ID field (`=sourceItem.ID`) and Base (`=sourceItem`).
* **ExternalReference** `<Module>.<type or assembly>` - Adds required dll reference for compilation of the object model. Dll can be set on two ways:
  * (Recommended) By C# type which is used (set assembly qualified name). Assembly Qualified Name should not contain Version, Culture or PublicKeyToken if it is custom dll. It should contain only if it is .NET framework type.
  * By dll name (e.g. 'rhetos.MyFunctions.dll').
* **UseExecutionContext** `<calculation>` - Enables IExecutionContext parameter for calculations.

Saving calculated data:

* **Persisted** `<Module.<name> <source DataStructure>` - Creates database table which will contain data from the source. Source can be some of the calculations or any other data structure (e.g. Browse).
* **AllProperties** `<Persisted>` - Enables persistence of all calculated properties. Additionally transfers indexes and cascade delete defines and Extends concept.
* **KeepSynchronized** `<Persisted>`
* **KeepSynchronized** `<Persisted> safe filter: (IE<DS> items, repository) => IE<DS> Items'` - Saves updates only for the records which are filtered.
* **ComputeForNewBaseItems**

Defining interdependent calculations so the **KeepSynchronized** can know when to update cached data:

* **ChangesOnBaseItem** `<calculation>` If the calculation is extension of some entity, then some calculated records depend on the related base entity
* **ChangesOnLinkedItems** `<calculation <reference property>` - If calculation is extension of some entity, then some calculated records depend on entities which are referenced by base document.
  * E.g. if you are calculating additional data about the document and that data depends on some document item (e.g. item number or total amount) then it is required to reference the property of that item. That will result in recalculation of some items on the related document which is referenced by the item.
* **ChangesOnChangedItems** `<calculation> <entity> <filter name> <entity[] changedItems => .. filter parameters>` - Programmable concept for defining related calculated items. Filter has to be implemented in the data structure of the calculation and persisted data structure which will contain saved calculation. FilterAll and System.Guid[] are commonly used filters supported by all entities.
  * E.g. if some change of entity needs to be recalculated, it can be used this way: `ChangesOnChangedItems Test.Item 'FilterAll' changedItems => new FilterAll()';`
  * E.g. ChangesOnLinkedItems should be implemented by ChangesOnChangedItems this way: `ChangesOnChangedItems Test.Item 'System.Guid[]' 'changedItems => changedItems.Where(item => item.HeaderID.HasValue).Select(item => item.HeaderID.Value).Distinct().ToArray()';`

## Filters

* **FilterBy** `<DataStructure>.'<Parameter>''(repository, parameter) => ... filtered DataStructure[]'`
* **ComposableFilterBy** `<DataStructure>.'<Parameter>''(IQ<DataStructure> items, repository, parameter) => ... filtered IQ<DS>items'`

Additional concepts:

* **ItemFilter** `<DataStructure>.'<FilterName>''item => ... bool'` - helper concept for simplified definition of simple filters (Creates ComposableFilterBy).
* **Parameter** - Data structure used as filter parameter. Usually represents filter name too. Although any data structure can be used as filter parameter, this helper concept is useful for more descriptive DSL writing.
* **UseExecutionContext** `<FilterBy>` - Enables IExecutionContext as additional filter parameter.
* **FilterByReferenced** `<DetailDataStructure>.'<Parameter>'<Parent reference>'IE<Detail> => .. additional filter or sort from group with the same parent'` - Creates filter on the detail structure which returns data related to the filter on the parent structure. Assuming parent structure already has that filter defined.
* **FilterByLinkedItems** `<ParentDataStructure>.'<Parameter>'<detail reference>'` - Creates filter on the parent structure which returns data related to the filter on the detail structure. Assuming detail structure already has defined filter.

Beside these explicitly defined filters, generic filters are available trough REST service and SOAP web interfaces on all concept which are queryable. (Entity, Browse, SqlQueryable, QueryableExtension, ...)

## Reports

* **TemplaterReport** `<Module>.<name>'file path'` - Spire template report.
  * Enables generating and downloading of report trough SOAP interface (DownloadReportCommand).
  * **REMARK:** This concept is not implemented inside CommonConcepts package. It is required to include "TemplaterReport" DSL package.
  * Report is also a data structure. Properties on the report represent report parameters.
  * File path should be formed like: 'package name\file name', because file could end up in subfolder.
  * Supported file types are doc, docx, xls and xlsx.
  * Supports download in original and pdf format.
* **Data Sources** `<Report>.'comma separated data structures'` - Provide data sources in ordered list. It is not required to provide module name.
  * Each provided data source should have filter implementation with parameter named same as the report.
  * It is recommended to use FilterByBase, FilterByReferenced and FilterByLinkedItems how to avoid redundant writing of similar filter on related structures (e.g. documents and related items which are shown on the report).
* **DataSource** `<Report>.'order' <DataStructure>` - Not required to use, it is simpler through DataSources macro concept .
* **ConvertFormat** `<Report>.'format'` - Subset of functionalities from TemplaterReport: only data download without file generating. On the object model repository, only GetReportData function is generated. This concept can be used with DataSources.
* **ReportFile** `<Module>.<name> '(object[][] reportData, string convertFormat, executionContext) => .. code for generating Rhetos.Dom.DefaultConcepts.ReportFile {string Name, byte[] Content}'` - Similar like TemplaterReport, only instead of Spire template, custom file generating code is used from downloaded data. This concept is implemented in CommonConcepts package.

## Complex concepts

* **Hierarchy** `<DataStructure>.<Name>` - Generates recursive reference to itself. Sets name of Reference property. Additionally generates and maintains persistent data to quickly handle given hierarchy.
  * Calculated data containing fields: Level (depth of each element in the tree), LeftIndex and RightIndex (for quick tree search).
  * Calculated data can be used from the entity as extension (e.g. item.Extension: `<EntityName><HierarchyName>`Hierarchy.Level).
  * On the given entity, ComposableFilter "`<HierarchyName>`HierarchyDescendants" with ID (Guid) parameter is generated, which can be used for quick access of all direct and indirect child records. Also filter "`<HierarchyName>`HierarchyAncestors" is being generated, for accessing all direct and indirect parents.
* **Hierarchy** `<DataStructure>.<Name> <PathName> <PathProperty> <PathSeparator>` - With standard Hierarchy functionality, this concepts additionally calculates path for data record.
  * Path is generated with values from PathProperty. PathProperty can be name of the property or path to some referenced data (like Browse).
  * Path is saved within existing extension (Extension_`<EntityName><HierarchyName>`Hierarchy, inside property with the given name `<PathName>`.
* **SingleRoot** `<Hierarchy>` - Limits insert to only one root record.
* **History** `<Entity>` - Includes logging of old entity version inside new entity with suffix "_History".
* **AllProperties** `<History>` - Includes logging of old versions for all properties.
* **History** `<Property>` - Includes logging of old versions for selected property. If History concept is added to the property, it doesn't have to be added on the entity itself. This concept can be added to more properties.
  
## Server actions

* **Action** `<Module>.<name> <parameter, repository, userInfo) => {...C# script }>` - Server action which runs C# script. Can be started trough REST and SOAP interfaces. It can have parameters: Action which is DataStructure, so it can have properties added to it, which are used as C# script parameters.
* **UseExecutionContext**  `<Action>` - Enables using of additional IExecutionContext argument: (parameter, repository, userInfo, executionContext) => ...

## Claims and permissions

* **DenySave** `<DataStructure>.<filter name> <message> <Property>` - Restricts data recording for the given property by included filter (filter has to return incorrect data).
* **Lock** `<DataStructure>.<filter name> <message> <property>` - Restricts editing or deleting data for the given property by included filter (filter should return locked records).
* **CustomClaim** `'<custom resource name>''<custom action or claim right>'` - Additional claim which can be given to the selected users and domain groups through standard permissions interface, checked by IAuthorizationManager. Should be defined outside Module structure. E.g. `CustomClaim 'ProjectName.HomePage' 'AllMenuItemsVisible';`
* **RowPermissions** - Restricts access for selected users by defined subset data of some entity. Documentation: <https://github.com/Rhetos/Rhetos/wiki/RowPermissions-concept>
  
## SQL objects

This concepts are used only as workaround, for features that are not directly supported in Rhetos:

* **SqlProcedure** `<Module>.<Name> <ProcedureArguments> <ProcedureSource>`
* **SqlTrigger** `<DataStructure>.<Name> <Events> <TriggerSource>`
* **SqlFunction** `<Module>.<Name> <Arguments> <RETURNS ... AS ... function source>`
* **SqlView** `<Module>.<Name> <ViewSource>`
* **SqlIndex**
* **SqlIndexMultiple**
* **SqlDefault** - Sets default constraint to the related database column. This concept is used only for internal functionality implemented in SQL procedures and triggers. This concept cannot be used as default field value within data recording through Rhetos server, because server always records NULL value for empty field value.
* **SqlObject** `<Module>.<Name> <CreateSQL> <RemoveSQL>` - Way of generating other unsupported objects, e.g. full-text search. Documentation: <https://github.com/Rhetos/Rhetos/wiki/SqlObject-concept.>
  
Rhetos framework does not parse SQL scripts, so it cannot define order of creating SQL views and triggers. To achieve that, these concepts should be used:

* **SqlDependsOn** - Defines concept interdependence so the objects can be created by required order during deployment. Target can be module, entity or property.
* **SqlDependsOnView**
* **SqlDependsOnFunction**
* **SqlDependsOnSqlObject**
* **PrerequisiteAllProperties**
* **AutodetectSqlDependencies** `<Module>` - Detects and generated dependencies (SqlDependsOn) for SqlQueryable, SqlView, SqlFunction, SqlProcedure, SqlTrigger and LegacyEntity view. It may be applied to any of those objects or to a whole module.
* **AutodetectSqlDependencies** `<Sql*>`
