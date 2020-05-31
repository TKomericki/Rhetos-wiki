# Setting up Rhetos application for HTTPS

In order for Rhetos WCF web application to work on HTTPS you need to update
the binding security elements in the application's *Web.config* file:

1. Insert the following snippet into the existing `binding` elements (or update if it already exists):

    ```XML
    <security mode="Transport">
      <transport clientCredentialType="None" />
    </security>
    ```

   Insert into `<basicHttpBinding><binding> ... </binding></basicHttpBinding>`

   and into`<webHttpBinding><binding> ... </binding></webHttpBinding>`

2. If the web application uses Windows authentication,
   modify clientCredentialType to `clientCredentialType="Windows"`.

Example result:

```XML
<bindings>
  <basicHttpBinding>
    <binding name="rhetosBasicHttpBinding" maxReceivedMessageSize="104857600">
      <readerQuotas maxArrayLength="104857600" maxStringContentLength="104857600" />
      <security mode="Transport">
        <transport clientCredentialType="None" />
      </security>
    </binding>
  </basicHttpBinding>
  <webHttpBinding>
    <binding name="rhetosWebHttpBinding" maxReceivedMessageSize="104857600">
      <readerQuotas maxArrayLength="104857600" maxStringContentLength="104857600" />
      <security mode="Transport">
        <transport clientCredentialType="None" />
      </security>
    </binding>
  </webHttpBinding>
</bindings>
```
