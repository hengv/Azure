    function create-vhdVmFromVhdVm{
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
    New-AzureRmResourceGroup -Name $myinput.newrgname -Location $myinput.location }

    $avsname = $myinput.avsname
    $avss = Get-AzureRmAvailabilitySet -ResourceGroupName $myinput.newrgname
    $avsmark = $false
    foreach($avs in $avss)
    { if($avs.Name -eq $avsname){$avsmark = $true;break}
    }
    if(!$avsmark){$avs = New-AzureRmAvailabilitySet -ResourceGroupName $myinput.newrgname -Name $myinput.avsname -Location $myinput.location -PlatformFaultDomainCount 2}

    $oldvm = Get-AzureRmVM -ResourceGroupName $myinput.oldrgname -Name $myinput.vmname

    $osduri = $oldvm.StorageProfile.OsDisk.Vhd.Uri
    $saname = $osduri.Split('/')[2].Split('.')[0]  
    $vhdname = $osduri.Split('/')[-1]
    $sas = Get-AzureRmStorageAccount
    foreach($sa in $sas){
        if($saname -eq $sa.StorageAccountName)
        { break
        }
    }

    $newctrname = $myinput.newCtrName
    $sa | New-AzureStorageContainer -Name $newctrname
    $osdiskblob = $sa | Get-AzureStorageBlob -Container vhds -Blob $vhdname

    $sa | Get-AzureStorageBlob -Container vhds -Blob $vhdname | Start-AzureStorageBlobCopy -DestContainer $newctrname

    $newosdiskblob = $sa | Get-AzureStorageBlob -Container $newctrname -Blob $vhdname

    $newosdiskuri = $newosdiskblob.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri
        
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
    $newosdiskname = $newvmname + "OS"
    #创建虚拟机
    #定义VM大小
    $newvm = New-AzureRmVMConfig -VMName $newvmname -VMSize $Size -AvailabilitySetId $avs.Id
    #定义OS盘 
    $newvm = Set-AzureRmVMOSDisk -VM $newvm -Name $newosdiskname -VhdUri $newosdiskuri -CreateOption Attach -Linux 
    #添加网卡
    $newvm = Add-AzureRmVMNetworkInterface -VM $newvm -Id $vmnic.id -Primary
    #创建临时VM
    $newvm = new-azurermvm -ResourceGroupName $myinput.newrgname -Location $myinput.location -VM $newvm 
    
}
   
}

$csvfilepath = "d:\b.csv"

create-vhdVmFromVhdVm -csvfilepath $csvfilepath
