
��Ŀ¼���������ļ���

diffsa.csv����create-vhdvmfromvhdvmdiffsa.ps1

����diffsa.csv�������ļ���create-vhdvmfromvhdvmdiffsa.ps1�ű���ȡb.csv��������ļ��еĲ�������vm�ĸ��ơ�

����˵����

location��chinanorth��chinaeast

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

SameSA��yes��no�������Ƿ���ͬһ���洢�˻��������yes����������������û�����塣��������£��µ�VM��vhd�ļ���������ͬ�洢�˻��Ĳ�ͬcontainer�ڡ������no���µ�VM��vhd�ļ�����������һ���洢�˻��У��洢�˻�����Ϣ������������������

randomSaName��yes��no�������洢�˻��������Ƿ�������ɡ������yes������һ��������û�����塣��������£��µ�VM��vhd�ļ�������һ������Ϊ��VM����+ʱ��+������Ĵ洢�˻��С������no���µ�VM��vhd�ļ��������������ɺ���һ������ָ���Ĵ洢�˻���

SAName���洢�˻����ƣ����ǰ����������Ϊno���µ�VM��vhd�ļ����������洢�˻���Ϊ��������Ĵ洢�˻���

create-vhdvmfromvhdvmdiffsa.ps1����ԴVM��OS disk��Data Disk���и��ƣ�����ָ����Vnet��Subnet�д���NIC����ָ������Դ���д���ָ�����Ƶ�VM�����ǵ�ÿ���洢�˻�ֻ���������40��Disk������ű����Ѹ��Ƶ�Disk�ŵ�һ���µĴ洢�˻��С��洢�˻����������������container����������Ϊ��������VM����+����+6λ����������VM���Ƴ���̫�����ܳ�����24���ֽڡ����ƹ��̿��Բ��ػ������������д���̡���Ȼ�ػ������ȫ��

