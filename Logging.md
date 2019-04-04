# Logging

Rhetos contains two different technologies used for logging:
a **system log** to monitor the state of the application,
and a **data log** for audit trail.

Contents:

1. [System log](#system-log)
2. [Logging data changes and auditing](#logging-data-changes-and-auditing)
3. [Similar features](#similar-features)

## System log

The generated web application has system logging integrated in many internal components,
in order to provide **global error reporting**, **performance diagnostics**,
or a **detailed trace log** for debugging.

The system log uses [NLog](https://nlog-project.org/), a popular 3rd party library,
and it can be configured to different level of detail for different system components.
It supports many targets such as files or Azure Application Insights.

See the [Debugging](Debugging) article for more related information.

## Logging data changes and auditing

Logging can be enabled on any entity to generated an **audit trail**.
For the audit trail Rhetos server uses *Common.Log* table.
When enabled, logging automatically records all changes made on the entity.
It also records the changed data and information about the user.
Logging is implemented through SQL triggers which makes it possible to record changes made outside the Rhetos server application.

* More about using the **Logging** concept can be found under [Implementing simple business rules](https://github.com/Rhetos/Rhetos/wiki/Implementing-simple-business-rules#Logging).

The data log can be extended with more actions, other than recording the data changes.
For example, a **custom log entry** can be added by
[executing the action](Action-concept#execute-an-action) "Common.AddToLog",
with the following parameters: "ShortString Action, ShortString TableName, Guid ItemId, LongString Description"
(only the Action parameter is required).

When **reading data** from the Common.Log, *always* use the view **Common.LogReader**, instead of reading from Common.Log directly.

* LogReader ensures that reading log will not block any write operations (WITH NOLOCK). This is important if the database does not use read committed snapshot, to allow other users to work while analyzing the log.
* LogReader can include archived logs from other tables or databases.

The Common.Log table contains following columns:

| Column name | Description |
| --- | --- |
| ID uniqueidentifier | Internal PK |
| Created datetime | Log entry creation time. |
| User nvarchar(256) | A system account that made the data modification. This is usually account which runs Rhetos server. |
| Workstation nvarchar(256) | This is usually workstation which runs Rhetos server. |
| ContextInfo nvarchar(256) | If logged action has been done through Rhetos server, this column will contain username of end user and its PC name or IP in the following format “Rhetos:{username},{host}". |
| Action nvarchar(256) | Logged action: "Insert", "Update", "Delete" or other.  |
| TableName nvarchar(256) | Name of the entity whose values have been changed. |
| ItemId uniqueidentifier | ID of changed item. |
| Description nvarchar(max) | Contains serialized XML of changed data. It only contains old values while the new values can be found in the actual table. |

If the **impersonation** is used (see plugins
[WindowsAuthImpersonation](https://github.com/Rhetos/WindowsAuthImpersonation)
and [AspNetFormsAuthImpersonation](https://github.com/Rhetos/AspNetFormsAuthImpersonation))
ContextInfo will contain both the original and the impersonated user name in format "{original user} as {impersonated user}".

## Similar features

Alternatively, for entities whose value may change over time (eg. Employee may change its address), you can enable [History entity](Temporal-data-and-change-history) functionality which will record historical data in {EntityName}_History table. This functionality enables you to access entity values on a given date.
