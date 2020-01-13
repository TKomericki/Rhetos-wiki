# Installing IIS Features on Windows 8 and Windows 10

*Disclaimer: This article is based on
[Installing IIS Features on Windows 8 and Windows 10](https://docs.microsoft.com/en-us/previous-versions/dynamicsnav-2016/hh167503(v=nav.90)#installing-iis-features-on-windows-8-and-windows-10)
for Microsoft Dynamics.
See the original article for instructions on other environments.
There is no need to install NET 3.5 features on IIS, only NET 4.x features are needed.*

Steps:

1. On the **Start** page, choose **Control Panel**, and then choose **Programs**.
2. Under **Programs and Features**, choose **Turn Windows features on or off**.
   The Windows features dialog box appears.
3. Expand the root-level item **.NET Framework 4.x Advanced Services**, and then do the following:
   * Select **ASP.NET 4.x**.
   * Expand **WCF Services**, and then select **HTTP Activation**.
4. Expand the root-level item **Internet Information Services**, expand **World Wide Web Services**,
   and then do the following:
   * Expand **Application Development Features**, and select the following features:
     * **.NET Extensibility 4.x**
     * **ASP.NET 4.x**
     * **ISAPI Extensions**
     * **ISAPI Filters**
   * Expand **Common HTTP Features**, and then select the **Static Content** feature.
   * Expand **Security**, and then select the following features:
     * **Request Filtering**
     * **Windows Authentication**
5. Under **Internet Information Services**, expand **Web Management Tools**, and then select **IIS Management Console**.
6. Choose the **OK** button to complete the installation.
7. To verify that the web server has been installed correctly, start your browser, and then type **<http://localhost>** in the address.
8. The default web site opens and should display an IIS 8 image.
