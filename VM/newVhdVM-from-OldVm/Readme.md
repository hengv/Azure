

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