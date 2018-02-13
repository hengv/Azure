    function create-vmfromvm{
    param(
    [Parameter(Mandatory=$true)] 
    [String]$csvfilepath
    )
    #$csvfilepath = "d:\b.csv"
    #导入CSV文件
    $inputvalues = Import-Csv -Path $csvfilepath 
    #$myinput = $inputvalues[0]
    #对CSV中的内容逐条进行处理
    foreach($myinput in $inputvalues){
    $rgs = Get-AzureRmResourceGroup -Location $myinput.location
    $rgmark = $false
    foreach($rg in $rgs){
      if($rg.ResourceGroupName -eq $myinput.newrgname){$rgmark = $true; break}
    }
    if(!$rgmark){
    New-AzureRmResourceGroup -Name $myinput.newrgname -Location $myinput.location}

    $avsname = $myinput.avsname
    $avss = Get-AzureRmAvailabilitySet -ResourceGroupName $myinput.newrgname
    $avsmark = $false
    foreach($avs in $avss)
    { if($avs.Name -eq $avsname){$avsmark = $true;break}
    }
    if(!$avsmark){$avs = New-AzureRmAvailabilitySet -ResourceGroupName $myinput.newrgname -Name $myinput.avsname -Location $myinput.location -Managed -PlatformFaultDomainCount 2}

    $oldvm = Get-AzureRmVM -ResourceGroupName $myinput.oldrgname -Name $myinput.vmname

    if($oldvm.StorageProfile.OsDisk.ManagedDisk){
       write-host true
       $osdid = $oldvm.StorageProfile.OsDisk.ManagedDisk.Id
       $oldosdiskname = $osdid.Split('/')[-1]
       $oldosdisk = Get-AzureRmDisk -ResourceGroupName $myinput.oldrgname -DiskName $oldosdiskname
       $osdiskname = $myinput.newvmname + "-os"
       $osdiskconfig = New-AzureRmDiskConfig -SkuName StandardLRS -OsType $myinput.osType -DiskSizeGB $oldosdisk.DiskSizeGB -CreateOption Copy -SourceResourceId $osdid -Location $myinput.location
       $osdisk = New-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $osdiskname -Disk $osdiskconfig

    }else
    {write-host false
        $osduri = $oldvm.StorageProfile.OsDisk.Vhd.Uri
        $saname = $osduri.Split('/')[2].Split('.')[0]  
        $vhdname = $osduri.Split('/')[-1]
        $sas = Get-AzureRmStorageAccount
        foreach($sa in $sas){
          if($saname -eq $sa.StorageAccountName)
          { break
          }
        }
        $sa | New-AzureStorageContainer -Name temp
        $osdiskblob = $sa | Get-AzureStorageBlob -Container vhds -Blob $vhdname

        $sa | Get-AzureStorageBlob -Container vhds -Blob $vhdname | Start-AzureStorageBlobCopy -DestContainer temp

        $newosdiskblob = $sa | Get-AzureStorageBlob -Container temp -Blob $vhdname

        $osdiskconfig = New-AzureRmDiskConfig -SkuName StandardLRS -OsType $myinput.osType -DiskSizeGB ([math]::Ceiling($newosdiskblob.Length/1024/1024/1024)) -CreateOption Import -SourceUri $newosdiskblob.ICloudBlob.StorageUri.PrimaryUri.OriginalString -Location $myinput.location
        $osdiskname = $myinput.newvmname + "-os"
        $osdisk = New-AzureRmDisk -DiskName $osdiskname -ResourceGroupName $myinput.newrgname -Disk $osdiskconfig 
        }

        $vnet = Get-AzureRmVirtualNetwork -Name $myinput.vnetname -ResourceGroupName $myinput.vnetrgname
        
        foreach($subnet in $vnet.Subnets){
          if($subnet.name -eq $myinput.subnetname){
            break
          }
        }
        $vmpipname = $myinput.newvmname + "-pip"
        $vmpip = New-AzureRmPublicIpAddress -Name $vmpipname -ResourceGroupName $myinput.newrgname -Location $myinput.location -AllocationMethod Dynamic
        $vmnicname = $myinput.newvmname + "-nic"
        $vmnic = New-AzureRmNetworkInterface -Name $vmnicname -ResourceGroupName $myinput.newrgname -Location $myinput.location -SubnetId $subnet.Id -PublicIpAddressId $vmpip.Id 
    
    $newvmname = $myinput.newvmname 
    $size = $myinput.vmsize
    #创建虚拟机
    #定义VM大小
    $newvm = New-AzureRmVMConfig -VMName $newvmname -VMSize $Size -AvailabilitySetId $avs.Id
    #定义OS盘 
    $newvm = Set-AzureRmVMOSDisk -VM $newvm  -ManagedDiskId $osdisk.Id -CreateOption Attach -Linux -StorageAccountType StandardLRS
    #添加Data盘
    #$newvm = Add-AzureRmVMDataDisk -VM $newvm -ManagedDiskId $datadisk.Id -Lun 1 -CreateOption Attach -StorageAccountType StandardLRS
    #添加网卡
    $newvm = Add-AzureRmVMNetworkInterface -VM $newvm -Id $vmnic.id -Primary
    #创建临时VM
    $newvm = new-azurermvm -ResourceGroupName $myinput.newrgname -Location $myinput.location -VM $newvm 
    
    if(!$oldvm.StorageProfile.OsDisk.ManagedDisk){
    $sa | Remove-AzureStorageBlob -Container temp -Blob $vhdname -Force
    $sa | Remove-AzureStorageContainer -Name temp}    
 }
   
}

$csvfilepath = "d:\b.csv"

create-vmfromvm -csvfilepath $csvfilepath
