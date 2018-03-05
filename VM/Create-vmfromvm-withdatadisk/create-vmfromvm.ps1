function create-vmfromvm{
  param(
  [Parameter(Mandatory=$true)] 
  [String]$csvfilepath
  )
   #$csvfilepath = "d:\b.csv"
   #导入CSV文件
   $inputvalues = Import-Csv -Path $csvfilepath 
   #对CSV中的内容逐条进行处理
   foreach($myinput in $inputvalues){
    #检查新的RG是否存在，如果不存在，创建这个RG
    $rgs = Get-AzureRmResourceGroup -Location $myinput.location
    $rgmark = $false
    foreach($rg in $rgs){
      if($rg.ResourceGroupName -eq $myinput.newrgname){$rgmark = $true; break}
    }
    if(!$rgmark){
    New-AzureRmResourceGroup -Name $myinput.newrgname -Location $myinput.location}
    #检查AVS是否存在，如果不存在，创建这个AVS
    $avsname = $myinput.avsname
    $avss = Get-AzureRmAvailabilitySet -ResourceGroupName $myinput.newrgname
    $avsmark = $false
    foreach($avs in $avss)
    { if($avs.Name -eq $avsname){$avsmark = $true;break}
    }
    if(!$avsmark){$avs = New-AzureRmAvailabilitySet -ResourceGroupName $myinput.newrgname -Name $myinput.avsname -Location $myinput.location -Sku aligned -PlatformFaultDomainCount 2}
    #获得源VM的信息
    $oldvm = Get-AzureRmVM -ResourceGroupName $myinput.oldrgname -Name $myinput.vmname
    #对DISK的类型进行转换
    if($myinput.vmStorageType -eq "Standard_LRS"){$sat = "StandardLRS"}else{$sat = "PremiumLRS"}
    #获取目前订阅中所有存储账户的信息，为下面的工作做准备
    $sas = Get-AzureRmStorageAccount
    #判断是否是托管磁盘的VM
    if($oldvm.StorageProfile.OsDisk.ManagedDisk){
       #如果是，把托管磁盘的OS磁盘进行复制
       write-host true
       $osdid = $oldvm.StorageProfile.OsDisk.ManagedDisk.Id
       $oldosdiskname = $osdid.Split('/')[-1]
       $oldosdisk = Get-AzureRmDisk -ResourceGroupName $myinput.oldrgname -DiskName $oldosdiskname
       $osdiskname = $myinput.newvmname + "-os"
       $osdiskconfig = New-AzureRmDiskConfig -SkuName $sat -OsType $myinput.osType -DiskSizeGB $oldosdisk.DiskSizeGB -CreateOption Copy -SourceResourceId $osdid -Location $myinput.location
       $osdisk = New-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $osdiskname -Disk $osdiskconfig

    }else
    {   
        #如果不是，对OS的vhd文件进行复制，并生成托管磁盘的的OS disk
        write-host false
        $osduri = $oldvm.StorageProfile.OsDisk.Vhd.Uri
        $saname = $osduri.Split('/')[2].Split('.')[0] 
        $sacname = $osduri.Split('/')[3]
        $sactemp = $myinput.newvmname + 'temp' 
        $vhdname = $osduri.Split('/')[-1]
        foreach($sa in $sas){
          if($saname -eq $sa.StorageAccountName)
          { break
          }}
        $sa | New-AzureStorageContainer -Name $sactemp
        $osdiskblob = $sa | Get-AzureStorageBlob -Container $sacname -Blob $vhdname
        #复制vhd文件
        $sa | Get-AzureStorageBlob -Container $sacname -Blob $vhdname | Start-AzureStorageBlobCopy -DestContainer $sactemp
        $newosdiskblob = $sa | Get-AzureStorageBlob -Container $sactemp -Blob $vhdname
        #从复制的vhd文件创建托管磁盘
        $osdiskconfig = New-AzureRmDiskConfig -SkuName $sat -OsType $myinput.osType -DiskSizeGB ([math]::Ceiling($newosdiskblob.Length/1024/1024/1024)) -CreateOption Import -SourceUri $newosdiskblob.ICloudBlob.StorageUri.PrimaryUri.OriginalString -Location $myinput.location
        $osdiskname = $myinput.newvmname + "-os"
        $osdisk = New-AzureRmDisk -DiskName $osdiskname -ResourceGroupName $myinput.newrgname -Disk $osdiskconfig 
   }
#####################data-disk begin#######################################
    #对数据盘进行复制
    $olddatadisks = $oldvm.StorageProfile.DataDisks
    $datadisks = @()
    for($datadiski=1; $datadiski -le $olddatadisks.Count; $datadiski++ )
    {   
        #磁盘名称中加入时间信息
        $daytime = Get-Date -UFormat "%Y%m%d"
        #磁盘名称中加入随机数 
        $hash = $null 
        for ($i = 0; $i -le 5; $i++){ 
        $j = (48..57) | Get-Random -Count 1 | % {[char]$_} 
        $hash = $hash + $j }
        $datadiskname = $myinput.newvmname + "-data" + $datadiski +"-"+ $daytime +"-"+ $hash
        #根据数据盘的类型，进行复制，最后都生成托管磁盘，复制过程和OS盘类似
        if($oldvm.StorageProfile.OsDisk.ManagedDisk){
            $mydatadiskconfig = New-AzureRmDiskConfig -SkuName $sat -DiskSizeGB $olddatadisks[$datadiski-1].DiskSizeGB -CreateOption Copy -SourceResourceId $olddatadisks[$datadiski-1].ManagedDisk.Id -Location $myinput.location 
            $mydatadisk = New-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $datadiskname -Disk $mydatadiskconfig 
        }
        else{
            $dduri = $olddatadisks[$datadiski-1].Vhd.Uri
            $dsaname = $dduri.Split('/')[2].Split('.')[0] 
            $dsacname = $dduri.Split('/')[3]
            Write-Output $datadiski
            $dsactemp = $myinput.newvmname + [string]$datadiski +'temp'
            $dvhdname = $dduri.Split('/')[-1]
            foreach($dsa in $sas){
                if($dsaname -eq $dsa.StorageAccountName)
                { break
                }
            }
            $dsa | New-AzureStorageContainer -Name $dsactemp
            $ddiskblob = $dsa | Get-AzureStorageBlob -Container $dsacname -Blob $dvhdname
            $dsa | Get-AzureStorageBlob -Container $dsacname -Blob $dvhdname | Start-AzureStorageBlobCopy -DestContainer $dsactemp
            $newddiskblob = $dsa | Get-AzureStorageBlob -Container $dsactemp -Blob $dvhdname
            $ddiskconfig = New-AzureRmDiskConfig -SkuName $sat  -DiskSizeGB ([math]::Ceiling($newddiskblob.Length/1024/1024/1024)) -CreateOption Import -SourceUri $newddiskblob.ICloudBlob.StorageUri.PrimaryUri.OriginalString -Location $myinput.location
            $mydatadisk = New-AzureRmDisk -DiskName $datadiskname -ResourceGroupName $myinput.newrgname -Disk $ddiskconfig
        }
        #把生成的新磁盘，加入到磁盘数组中
        $datadisks = $datadisks + $mydatadisk
    }
#####################data-disk end#########################################
    #创建网卡
    $vnet = Get-AzureRmVirtualNetwork -Name $myinput.vnetname -ResourceGroupName $myinput.vnetrgname
    foreach($subnet in $vnet.Subnets){
        if($subnet.name -eq $myinput.subnetname){
        break
        }
    }
    #创建pip
    $vmpipname = $myinput.newvmname + "-pip"
    $vmpip = New-AzureRmPublicIpAddress -Name $vmpipname -ResourceGroupName $myinput.newrgname -Location $myinput.location -AllocationMethod Dynamic
    $vmnicname = $myinput.newvmname + "-nic"
    $vmnic = New-AzureRmNetworkInterface -Name $vmnicname -ResourceGroupName $myinput.newrgname -Location $myinput.location -SubnetId $subnet.Id -PublicIpAddressId $vmpip.Id 
    #VM的名称和size
    $newvmname = $myinput.newvmname 
    $size = $myinput.vmsize
    #创建虚拟机
    $newvm = New-AzureRmVMConfig -VMName $newvmname -VMSize $Size -AvailabilitySetId $avs.Id
    #定义OS盘 
    if($myinput.osType -eq "Linux")
    {$newvm = Set-AzureRmVMOSDisk -VM $newvm  -ManagedDiskId $osdisk.Id -CreateOption Attach -Linux  -StorageAccountType $sat}
    elseif($myinput.osType -eq "Windows")
    {$newvm = Set-AzureRmVMOSDisk -VM $newvm  -ManagedDiskId $osdisk.Id -CreateOption Attach -Windows  -StorageAccountType $sat}
    else{Write-Output "osType should be Linux or Windows";exit}
    #定义Data盘，在此处加数据盘，可以减少重启动作，但加入磁盘的顺序不可控，建议在创建好VM后再加入数据盘
    #for($i=1; $i -le $datadisks.Count; $i++ )
    #{
    #    write-output $i
    #    write-output $datadisks[$i-1].id
    #    $lun = $i + 1
    #    $newvm = Add-AzureRmVMDataDisk -VM $newvm -ManagedDiskId $datadisks[$i-1].id -Lun $lun -CreateOption Attach -StorageAccountType $sat -Name $datadisks[$i-1].name
    # }
    #添加启动监控存储账户信息
    $bdsamark = $false
    foreach($bdsa in $sas){
      if($myinput.DiagStorageAccountName -eq $bdsa.StorageAccountName){$bdsamark = $true; break}
    }
    if(!$bdsamark){
    New-AzureRmStorageAccount -ResourceGroupName $myinput.newrgname -Name $myinput.DiagStorageAccountName -SkuName Standard_LRS -Location $myinput.location
    $bdsa = Get-AzureRmStorageAccount -ResourceGroupName $myinput.newrgname -name $myinput.DiagStorageAccountName}
    #输出监控存储账户的信息
    Write-Output $bdsa.ResourceGroupName, $bdsa.StorageAccountName
    $newvm = Set-AzureRmVMBootDiagnostics $newvm -Enable -ResourceGroupName $bdsa.ResourceGroupName -StorageAccountName $bdsa.StorageAccountName
    #添加网卡
    $newvm = Add-AzureRmVMNetworkInterface -VM $newvm -Id $vmnic.id -Primary
    #创建VM
    $newvm = new-azurermvm -ResourceGroupName $myinput.newrgname -Location $myinput.location -VM $newvm 
    
    ##############################添加Data盘###############################
    $newvm = Get-AzureRmVM -ResourceGroupName $myinput.newrgname -Name $myinput.newvmname
    for($i=1; $i -le $datadisks.Count; $i++ )
    {
        write-output $i
        write-output $datadisks[$i-1].id
        Write-Output $datadisks[$i-1].name
        Write-Output $datadisks[$i-1].DiskSizeGB
        $lun = $i + 1
        $newvm = Add-AzureRmVMDataDisk -VM $newvm -ManagedDiskId $datadisks[$i-1].id -Lun $lun -CreateOption Attach -StorageAccountType $sat -Name $datadisks[$i-1].name
     }
        
    Update-AzureRmVM -VM $newvm -ResourceGroupName $myinput.newrgname
    Restart-AzureRmVM  -ResourceGroupName $myinput.newrgname -Name $myinput.newvmname 
        
    #########################################################################
 #删除过程中产生的临时vhd文件
     if(!$oldvm.StorageProfile.OsDisk.ManagedDisk)
     {
       #删除OS的临时vhd文件
       $osduri = $oldvm.StorageProfile.OsDisk.Vhd.Uri
       $saname = $osduri.Split('/')[2].Split('.')[0] 
       $sactemp = $myinput.newvmname + 'temp' 
       $vhdname = $osduri.Split('/')[-1]
       $sas = Get-AzureRmStorageAccount
       foreach($sa in $sas){
           if($saname -eq $sa.StorageAccountName)
           { break
           }
        }
        $sa | Remove-AzureStorageBlob -Container $sactemp -Blob $vhdname -Force
        $sa | Remove-AzureStorageContainer -name $sactemp -Force
        #删除Data Disk相关的临时vhd文件
        $olddatadisks = $oldvm.StorageProfile.DataDisks
        for($datadiski=1; $datadiski -le $olddatadisks.Count; $datadiski++ )
        {   $dduri = $olddatadisks[$datadiski-1].Vhd.Uri
            $dsaname = $dduri.Split('/')[2].Split('.')[0] 
            $dsactemp = $myinput.newvmname + [string]$datadiski +'temp'
            $dvhdname = $dduri.Split('/')[-1]
            foreach($dsa in $sas){
                if($dsaname -eq $dsa.StorageAccountName)
                { break
                }
            }
            $dsa | Remove-AzureStorageBlob -Container $dsactemp -Blob $dvhdname -Force
            $dsa | Remove-AzureStorageContainer -name $dsactemp -Force
            }
          }
   }
}
$csvfilepath = "d:\b.csv"
create-vmfromvm -csvfilepath $csvfilepath