
本目录内由两个文件：

diffsa.csv，，create-vhdvmfromvhdvmdiffsa.ps1

其中diffsa.csv是配置文件，create-vhdvmfromvhdvmdiffsa.ps1脚本读取b.csv这个配置文件中的参数进行vm的复制。

参数说明：

location：chinanorth或chinaeast

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

SameSA：yes或no。表明是否是同一个存储账户。如果是yes，后面两个参数将没有意义。这种情况下，新的VM的vhd文件将建在相同存储账户的不同container内。如果是no，新的VM的vhd文件将建在另外一个存储账户中，存储账户的信息由下面两个参数决定

randomSaName：yes或no。表明存储账户的名称是否随机生成。如果是yes，后面一个参数将没有意义。这种情况下，新的VM的vhd文件将建在一个名称为：VM名称+时间+随机数的存储账户中。如果是no，新的VM的vhd文件将创建在名称由后面一个参数指定的存储账户中

SAName：存储账户名称，如果前面两个参数为no，新的VM的vhd文件将创建到存储账户名为这个参数的存储账户中

create-vhdvmfromvhdvmdiffsa.ps1将把源VM的OS disk和Data Disk进行复制，并在指定的Vnet及Subnet中创建NIC，在指定的资源组中创建指定名称的VM。考虑到每个存储账户只能容纳最大40个Disk，这个脚本将把复制的Disk放到一个新的存储账户中。存储账户的名称命名规则和container的命名规则为：名称是VM名称+日期+6位随机数。如果VM名称长度太长，总长度是24个字节。复制过程可以不关机，但不建议读写磁盘。当然关机复制最安全。

