# Setting up Rhetos for HTTPS

In order for Rhetos to work on HTTPS you need to update security elements in web.config file.

Insert following code:
```XML
<security mode="Transport">
  <transport clientCredentialType="None" />
</security>
```

Into:
```XML
<basicHttpBinding><binding> </binding></basicHttpBinding>
```

And into:
```XML
<webHttpBinding><binding> </binding></webHttpBinding>
```

Example:
```XML
<services>
  <service name="Rhetos.RhetosService">
    <clear />
    <endpoint address="" binding="basicHttpBinding" bindingConfiguration="rhetosBasicHttpBinding" name="basic" contract="Rhetos.IServerApplication" listenUriMode="Explicit">
      <identity>
        <dns value="localhost" />
        <certificateReference storeName="My" storeLocation="LocalMachine" x509FindType="FindBySubjectDistinguishedName" />
      </identity>
    </endpoint>
    <endpoint address="mex" binding="mexHttpsBinding" contract="Rhetos.IServerApplication" />
  </service>
</services>
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
