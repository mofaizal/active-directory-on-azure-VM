## Setup AD on Azure VM 

```
CD workloads\
```



### Login to AD VM via Bastion Host
1. Azure Portal 
2. Look for avd-ad-resources - Resource Group
3. Click Connect and Select Bastion host 
4. Enter username <Refer TFVAR file>
5. Open Microsoft Edge browser and download Azure AD Connect  https://www.microsoft.com/en-us/download/details.aspx?id=47594 
6. Install Azure AD Connect and Components follow the step by step guide here : https://lazyadmin.nl/it/install-azure-ad-connect/ 
7. Setup / Configure Azure Connect 
8. Click Express Setting
9.  Enter Azure AD Global Admin username and password
10. Enter AD user name / PWD 
11. Select UPN tick box (bottom of the screen)
12. 

Create Username & Group 

```
Import-Module ActiveDirectory

$path="DC=avd,DC=local"
$username="avdlevelupuser"
$n=Read-Host "Enter Number"
$count=1..$n
foreach ($i in $count)
{ New-AdUser -Name $username$i -GivenName $username$i -Path $path -Enabled $True -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString "AVDtest123456!" -AsPlainText -force) -passThru }
```
