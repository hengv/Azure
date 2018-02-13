function new-choicevm{
param(

[Parameter(Mandatory=$true)]
[String]$sub1id,

[Parameter(Mandatory=$true)]
[String]$sub1rg,

[Parameter(Mandatory=$true)]
[String]$sub2id,

[Parameter(Mandatory=$true)]
[String]$sub2rg,

[Parameter(Mandatory=$true)]
[String]$vmname,

[Parameter(Mandatory=$true)]
[String]$vmsize
) 

$vm = get-azurermvm -ResourceGroupName $sub1rg -Name $vmname

Select-AzureRmSubscription -Subscriptionid $sub1id 

$nicid = $vm.NetworkProfile.NetworkInterfaces[0].Id
$nic = Get-AzureRmNetworkInterface -ResourceGroupName $sub1rg -Name $nicid.Split('/')[-1]
$dip = $nic.IpConfigurations[0].PrivateIpAddress
$osdisk = $vm.StorageProfile.OsDisk.Vhd
$datadisk0 = $vm.StorageProfile.DataDisks[0].vhd
$datadisk1 = $vm.StorageProfile.DataDisks[1].vhd

$avs = get-AzureRmAvailabilitySet -ResourceGroupName $sub2rg -Name $vm.AvailabilitySetReference.Id.Split('/')[-1]

Select-AzureRmSubscription -Subscriptionid $sub2id 

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName bjchoice -Name bjchoice-vnet
$pip = New-AzureRmPublicIpAddress -Name $vmname -ResourceGroupName $sub2rg -Location "China North" -AllocationMethod Dynamic 
$newnic = New-AzureRmNetworkInterface -Name $nic.Name -ResourceGroupName $sub2rg -Location "China North" -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress $nic.IpConfigurations[0].PrivateIpAddress 

$newavs = New-AzureRmAvailabilitySet -ResourceGroupName $sub2rg -Name $avs.Name -Location "China North" -PlatformUpdateDomainCount 5 -PlatformFaultDomainCount 2 -Managed 

$newvm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize -AvailabilitySetId $newavs.Id
$newvm = Add-AzureRmVMNetworkInterface -VM $newvm -Primary -Id $newnic.Id

$sub2sa = Get-AzureRmStorageAccount -ResourceGroupName $sub2rg -Name $sub2saname
$diskblobs = $sub2sa | Get-AzureStorageBlob -Container $vm.Name

foreach($diskblob in $diskblobs){
    if($diskblob.name -eq $osdisk.Uri.Split('/')[-1]){
        $osdiskname = $vmname + '-' + 'osdisk'
        $size = [int]($diskblob.ICloudBlob.Properties.length/1024/1024/1024) + 1
        $tmpdisk = New-AzureRmDiskConfig -SkuName StandardLRS -OsType Linux -Location "China North" -CreateOption Import -SourceUri $diskblob.ICloudBlob.StorageUri.PrimaryUri.OriginalString -DiskSizeGB $size
        $newosdisk = New-AzureRmDisk -ResourceGroupName $sub2rg -DiskName $osdiskname -Disk $tmpdisk
        $newvm = Set-AzureRmVMOSDisk -VM $newvm  -ManagedDiskId $newosdisk.Id -CreateOption Attach -Linux -StorageAccountType StandardLRS
        break
    }
}
$i = 0
foreach($diskblob in $diskblobs){
    if($diskblob.name -eq $osdisk.Uri.Split('/')[-1]){
        continue
    }
    $datadiskname = $vmname + '-' + 'datadisk' + $i
    $size = [int]($diskblob.ICloudBlob.Properties.length/1024/1024/1024) + 1
    $tmpdisk = New-AzureRmDiskConfig -SkuName StandardLRS -OsType Linux -Location "China North" -CreateOption Import -SourceUri $diskblob.ICloudBlob.StorageUri.PrimaryUri.OriginalString -DiskSizeGB $size
    $newdatadisk = New-AzureRmDisk -ResourceGroupName $sub2rg -DiskName $datadiskname -Disk $tmpdisk
    $lun = $i + 1
    $newvm = Add-AzureRmVMDataDisk -VM $newvm -ManagedDiskId $newdatadisk.Id -Name $datadiskname -Lun $lun -CreateOption Attach 
    $i++
    Write-Output $i
}

$newvm = new-azurermvm -ResourceGroupName $sub2rg -Location "China North" -VM $newvm 


}

$sub1rg = "xxxx"
$sub1id = "xxxx"
$sub2rg = "xxxx"
$sub2id = "xxxx"
$sub2saname = "xxxx"
$vmsize = "Standard_D4"
$vmname 

Select-AzureRmSubscription -Subscriptionid $sub1id
$vms = get-azurermvm -ResourceGroupName $sub1rg

$vmname = $vms[9].Name

new-choicevm -sub1id $sub1id -sub1rg $sub1rg -sub2id $sub2id -sub2rg $sub2rg -vmname $vmname -vmsize $vmsize 



