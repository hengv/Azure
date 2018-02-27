

本目录有三个文件：

b.csv，create-vhdvmfromvhdvm.ps1，create-vhdvmfromvhdvmdiffsa.ps1

其中b.csv是配置文件，create-vhdvmfromvhdvm.ps1和create-vhdvmfromvhdvmdiffsa.ps1两个文件读取b.csv这个配置文件中的参数进行vm的复制。

参数说明：

location：chinanort或chinaeast

oldrgname：源VM的资源组名称

vmname：源VM的名称

vnetrgname：新VM将要加入的VNET的资源组名称

vnetname：新VM将要加入的VNET的名称

subnetname：新VM将要加入的Subnet名称

newrgname：新VM的资源组名称，如果没有将新建

newvmname：新VM的名称

DiagStorageAccountName：新VM诊断的存储账户名称，如果没有这个存储账户，将新建

vmsize：新VM的型号

vmStorageType：新VM的存储类型，Standard_LRS或Premium_LRS

osType：Linux或Windows

avsname：Availability Set的名称，如果没有将新建

create-vhdvmfromvhdvm.ps1将把源VM的OS disk和Data Disk进行复制，并在指定的Vnet及Subnet中创建NIC，在指定的资源组中创建指定名称的VM。其中OS Disk和Data Disk都复制到源VM的OS Disk和Data Disk相同的存储账户中。但将新建一个Container，Container的名称是VM名称+日期+6位随机数。如果VM名称长度太长，总长度是24个字节。复制过程可以不关机，但不建议读写磁盘。当然关机复制最安全。

create-vhdvmfromvhdvmdiffsa.ps1和create-vhdvmfromvhdvm.ps1类似，不同之处在于，考虑到每个存储账户只能容纳最大40个Disk，这个脚本将把复制的Disk放到一个新的存储账户中。存储账户的名称命名规则和前面提到的Container的名称命名规则相同。