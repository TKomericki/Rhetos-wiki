# Logging

Rhetos contains two different technologies for logging:
a **system log** to monitor the state of the application,
and a **data log** for audit trail.

* If you need an external log that can be easily shipped to other systems
  (files, *Azure Application Insights* and similar), then use the **system log**.
  It is already used for internal system monitoring and diagnostics.
* If you need the log entries to be (loosely) connected to the business objects in the application,
  or the ability to read the log inside the application,
  than the best choice is probably the **data log**.
  It is often used in Rhetos applications for auditing features.

Contents:

1. [System log](#system-log)
2. [Logging data changes and auditing](#logging-data-changes-and-auditing)
3. [Other similar features](#other-similar-features)

## System log

The generated Rhetos application has system logging integrated in many internal components.
It provides **global error reporting**, **performance diagnostics**,
and a **detailed trace log** for debugging.

The system log uses [NLog](https://nlog-project.org/), a popular 3rd party library,
and it can be configured to different level of detail for different system components.
It supports many targets such as files or Azure Application Insights.
See the NLog documentation for available options: <https://nlog-project.org/config/?tab=targets>

In your Rhetos application you can:

1. Define custom event types for your log: `var logger = context.LogProvider.GetLogger("my event type")`,
   and [write](https://github.com/Rhetos/Rhetos/blob/master/Source/Rhetos.Logging.Interfaces/ILogger.cs)
   log entries: `logger.Write(...)`.
2. Configure logging in `Web.config` to create rules on when and where to send those events.
   Review the `nlog` section in your Rhetos application's *Web.config* file for some examples.

Here are explained some examples from the default configuration of the `<nlog>` section
in Rhetos application's `Web.config` file.
Uncomment any existing rule or add new rules as needed.

| Web.config `<nlog>` rule | Description |
| --- | --- |
| `<logger name="*" minLevel="Info" writeTo="MainLog" />` | Write errors and warnings to RhetosServer.log. Enabled by default. |
| `<logger name="ProcessingEngine CommandsWithServerError" minLevel="Trace" writeTo="TraceCommandsXml" />` | On internal server error write a full server request description to RhetosServerCommandsTrace.xml. Enabled by default. |
| `<logger name="ProcessingEngine CommandsWithClientError" minLevel="Trace" writeTo="TraceCommandsXml" />` | On client error (incorrect data or invalid request) write a full server request description to RhetosServerCommandsTrace.xml. Disabled by default. |
| `<logger name="*" minLevel="Trace" writeTo="TraceLog" />` | Write all events to RhetosServerTrace.log. Use this option only for a short time, because it generates a lot of data and can hinder the server performance. |
| `<logger name="ProcessingEngine Request" minLevel="Trace" writeTo="TraceLog" />` | Write a short description of each server request to RhetosServerTrace.log |

If you need to analyze a difficult issue in the application,
but the system log does not contain a useful information,
try the following options:

* Increate the level of detail for the system log to maximum:
  In `Web.config` *temporarily* uncomment the line with
  `<logger name="*" minLevel="Trace" writeTo="TraceLog" />`
  (this will reduce the application's performance),
  reproduce the issue in your application,
  then review the generated log file `Logs\RhetosServerTrace.log`.
* Try debugging the application in Visual Studio
  (even remote debugging is possible).
  See the [Debugging](Debugging) article for more details.

## Logging data changes and auditing

Logging can be enabled on any entity to generated an **audit trail**.
For the audit trail Rhetos application uses *Common.Log* table.
When enabled, logging automatically records all changes made on the entity.
It also records the changed data and information about the user.
Logging is implemented through SQL triggers which makes it possible to record changes
made outside the Rhetos application.

* More about using the **Logging** concept can be found under
  [Implementing simple business rules](Implementing-simple-business-rules#Logging).

The data log can be extended with more actions, other than recording the data changes.
For example, a **custom log entry** can be added by
[executing the action](Action-concept#execute-an-action) "Common.AddToLog",
with the following parameters: "ShortString Action, ShortString TableName, Guid ItemId, LongString Description"
(only the Action parameter is required).

When **reading the log data**, *always* use the view **Common.LogReader**,
instead of reading from Common.Log directly.

* LogReader ensures that reading log will not block any write operations (WITH NOLOCK).
  This is important if the database does not use read committed snapshot,
  to allow other users to work while analyzing the log.
* LogReader can include archived logs from other tables or databases.

*Common.LogReader* returns the following columns:

| Column name | Description |
| --- | --- |
| ID uniqueidentifier | Internal primary key. |
| Action nvarchar(256) | Logged action, for example "Insert", "Update", "Delete" or other. |
| TableName nvarchar(256) | Name of the entity that have been modified. (optional) |
| ItemId uniqueidentifier | ID of changed item. (optional) |
| Description nvarchar(max) | Contains serialized XML of changed data. It only contains old values while the new values can be found in the actual table. (optional) |
| Created datetime | Log entry creation time. |
| User nvarchar(256) | A **system account** that made the data modification. This is usually account which runs the Rhetos web application. |
| Workstation nvarchar(256) | This is usually workstation which runs the Rhetos web application. |
| ContextInfo nvarchar(256) | If logged action has been done through a Rhetos application, this column will contain username of the **end user** and its PC name or IP in the following format “Rhetos:{username},{host}". |

Note that there are two different columns with information on user account: **User** and **ContextInfo**.

* *User* is the account that accessed the database, this is usually the account that runs
  the Rhetos web application, executes the deployment process or a user that directly
  accessed the database with SQL Server Management Studio, for example.
* *ContextInfo* is a description of the end user that was using the application
  when the log entry was created.
* If the **impersonation** is used (see plugins
  [WindowsAuthImpersonation](https://github.com/Rhetos/WindowsAuthImpersonation)
  and [AspNetFormsAuthImpersonation](https://github.com/Rhetos/AspNetFormsAuthImpersonation))
  ContextInfo will contain both the original and the impersonated
  user name in format "{original user} as {impersonated user}".

## Other similar features

Alternatively, for entities whose value may change over time
(for example, an employee may change the address),
you can enable [History entity](Temporal-data-and-change-history)
functionality which will record historical data in a separate table.
This functionality enables you to access entity values on a given date,
or even allow users to modify the temporal data (retroactive changes).
