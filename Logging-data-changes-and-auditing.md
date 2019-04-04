# Logging data changes and auditing

Logging can be enabled on any entity. For system log, Rhetos server uses Common.Log table. When enabled, logging automatically records all changes made on the entity. It also records changed data and information about the user. Logging is implemented through SQL triggers which makes it possible to record changes made outside the Rhetos server.

System log can be extended with more actions, other than recording changes.

Additionally, for entities whose value may change over time (eg. Employee may change its address), you can set “HistoryEntity” functionality which will record historical data in {EntityName}_History table. This functionality enables you to access entity values on a given date.

Common.Log table contains following columns:

| Column name | Description |
| --- | --- |
| ID uniqueidentifier | Internal PK |
| Created datetime | Log entry creation time |
| User nvarchar(256) | This is usually account which runs Rhetos server |
| Workstation nvarchar(256) | This is usually workstation which runs Rhetos server |
| ContextInfo nvarchar(256) | If logged action has been done through Rhetos server, this column will contain username of end user and its PC name or IP in the following format “Rhetos:domain\usename,PCname” |
| Action nvarchar(256) | Logged action: "Insert", "Update" or "Delete" |
| TableName nvarchar(256) | Name of the entity whose values have been changed |
| ItemId uniqueidentifier | ID of changed item |
| Description nvarchar(max) | Contains serialized XML of changed data. It only contains old values while the new values can be found in the actual table. |,

More about using logging can be found under [Implementing simple business rules](https://github.com/Rhetos/Rhetos/wiki/Implementing-simple-business-rules#Logging)