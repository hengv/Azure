<<<<<<< HEAD


��Ŀ¼�������ļ���

b.csv��create-vhdvmfromvhdvm.ps1��create-vhdvmfromvhdvmdiffsa.ps1

����b.csv�������ļ���create-vhdvmfromvhdvm.ps1��create-vhdvmfromvhdvmdiffsa.ps1�����ļ���ȡb.csv��������ļ��еĲ�������vm�ĸ��ơ�

����˵����

location��chinanort��chinaeast

oldrgname��ԴVM����Դ������

vmname��ԴVM������

vnetrgname����VM��Ҫ�����VNET����Դ������

vnetname����VM��Ҫ�����VNET������

subnetname����VM��Ҫ�����Subnet����

newrgname����VM����Դ�����ƣ����û�н��½�

newvmname����VM������

DiagStorageAccountName����VM��ϵĴ洢�˻����ƣ����û������洢�˻������½�

vmsize����VM���ͺ�

vmStorageType����VM�Ĵ洢���ͣ�Standard_LRS��Premium_LRS

osType��Linux��Windows

avsname��Availability Set�����ƣ����û�н��½�

create-vhdvmfromvhdvm.ps1����ԴVM��OS disk��Data Disk���и��ƣ�����ָ����Vnet��Subnet�д���NIC����ָ������Դ���д���ָ�����Ƶ�VM������OS Disk��Data Disk�����Ƶ�ԴVM��OS Disk��Data Disk��ͬ�Ĵ洢�˻��С������½�һ��Container��Container��������VM����+����+6λ����������VM���Ƴ���̫�����ܳ�����24���ֽڡ����ƹ��̿��Բ��ػ������������д���̡���Ȼ�ػ������ȫ��

create-vhdvmfromvhdvmdiffsa.ps1��create-vhdvmfromvhdvm.ps1���ƣ���֮ͬ�����ڣ����ǵ�ÿ���洢�˻�ֻ���������40��Disk������ű����Ѹ��Ƶ�Disk�ŵ�һ���µĴ洢�˻��С��洢�˻����������������ǰ���ᵽ��Container����������������ͬ��
=======
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
>>>>>>> d042af255236dd27bde9c91bfaf2ce54e1abc3e6
