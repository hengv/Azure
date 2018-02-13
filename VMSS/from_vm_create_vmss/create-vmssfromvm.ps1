    function create-vmimage{
    param(
    [Parameter(Mandatory=$true)] 
    [String]$csvfilepath
    )

    
    #导入CSV文件
    $inputvalues = Import-Csv -Path $csvfilepath 

    #对CSV中的内容逐条进行处理
    foreach($myinput in $inputvalues){
    $rgs = Get-AzureRmResourceGroup -Location $myinput.location
    $rgmark = $false
    foreach($rg in $rgs){
      if($rg.ResourceGroupName -eq $myinput.newrgname){$rgmark = $true; break}
    }
    if(!$rgmark){
    New-AzureRmResourceGroup -Name $myinput.newrgname -Location $myinput.location}

    $oldvm = Get-AzureRmVM -ResourceGroupName $myinput.oldrgname -Name $myinput.vmname

    if($oldvm.StorageProfile.OsDisk.ManagedDisk){
       write-host true
       $osdid = $oldvm.StorageProfile.OsDisk.ManagedDisk.Id
       $oldosdiskname = $osdid.Split('/')[-1]
       $oldosdisk = Get-AzureRmDisk -ResourceGroupName $myinput.oldrgname -DiskName $oldosdiskname
       $osdiskname = $oldvm.Name + "-os"
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
        $osdiskname = $newosdiskblob.Name.Split('.')[0]
        $osdisk = New-AzureRmDisk -DiskName $osdiskname -ResourceGroupName $myinput.newrgname -Disk $osdiskconfig 
        }

        $vnet = Get-AzureRmVirtualNetwork -Name $myinput.vnetname -ResourceGroupName $myinput.vnetrgname
        
        foreach($subnet in $vnet.Subnets){
          if($subnet.name -eq $myinput.subnetname){
            break
          }
        }
        $vmpipname = $myinput.vmname + "-pip"
        $vmpip = New-AzureRmPublicIpAddress -Name $vmpipname -ResourceGroupName $myinput.newrgname -Location $myinput.location -AllocationMethod Dynamic
        $vmnicname = $myinput.vmname + "-nic"
        $vmnic = New-AzureRmNetworkInterface -Name $vmnicname -ResourceGroupName $myinput.newrgname -Location $myinput.location -SubnetId $subnet.Id -PublicIpAddressId $vmpip.Id 
    
    $tmpvmname = $myinput.vmname + "-temp"
    $size = $myinput.vmsize
    #创建虚拟机
    #定义VM大小
    $tmpvm = New-AzureRmVMConfig -VMName $tmpvmname -VMSize $Size
    #定义OS盘 
    $tmpvm = Set-AzureRmVMOSDisk -VM $tmpvm  -ManagedDiskId $osdisk.Id -CreateOption Attach -Linux -StorageAccountType StandardLRS
    #添加Data盘
    #$tmpvm = Add-AzureRmVMDataDisk -VM $tmpvm -ManagedDiskId $datadisk.Id -Lun 1 -CreateOption Attach -StorageAccountType StandardLRS
    #添加网卡
    $tmpvm = Add-AzureRmVMNetworkInterface -VM $tmpvm -Id $vmnic.id -Primary
    #创建临时VM
    $tmpvm = new-azurermvm -ResourceGroupName $myinput.newrgname -Location $myinput.location -VM $tmpvm
        
    #获取pip地址
    sleep(60)
    $pip = Get-AzureRmPublicIpAddress -ResourceGroupName $myinput.newrgname -Name $vmpipname

    #ssh到VM中，进行Generalize
    $sUser = $myinput.osaccountname
    $cPassword = $myinput.ospassword
    $sPassword = $cPassword | ConvertTo-SecureString -AsPlainText -Force 
    $sHost = $pip.IpAddress
    
    $oCredential = New-Object System.Management.Automation.PSCredential($sUser, $sPassword)
    $oSessionSSH = New-SSHSession -ComputerName $sHost -Credential $oCredential -AcceptKey 

    $stream = $oSessionSSH.Session.CreateShellStream("PS-SSH", 0, 0, 0, 0, 1000)

    $result = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for $($sUser):" -SecureAction $sPassword
    
    if ($result -eq "False"){
        $result = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password di $($sUser):" -SecureAction $sPassword
    }

    $sReturn = $stream.Read()
    $stream.WriteLine("echo abc@12345678 | passwd root --stdin")
    $stream.WriteLine("echo yes | waagent -deprovision+user")
    sleep -s 2
    $sReturn = $stream.Read()

    Write-Output $sReturn


    #在Azure平台上对VM进行Generalize
    stop-azurermvm -ResourceGroupName $myinput.newrgname -Name $tmpvmname -Force
    Set-AzureRmVM -ResourceGroupName  $myinput.newrgname -Name $tmpvmname -Generalized

    #把VM抓取成image
    $imagename = $myinput.imagename
    $newvm = get-azurermvm -ResourceGroupName $myinput.newrgname -Name $tmpvmname
    $image = New-AzureRmImageConfig -Location $myinput.Location -SourceVirtualMachineId $newvm.Id
    New-AzureRmImage -Image $image -ImageName $imagename -ResourceGroupName $myinput.newrgname

    #把相关tmp的资源删除
    remove-azurermvm -ResourceGroupName $myinput.newrgname -Name $tmpvmname -Force
    Remove-AzureRmNetworkInterface -ResourceGroupName $myinput.newrgname -Name $vmnicname -Force
    Remove-AzureRmPublicIpAddress -ResourceGroupName $myinput.newrgname -Name $vmpipname -Force
    Remove-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $osdiskname -Force
    #Remove-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $datadiskname -Force
    #$newosdiskblob = $sa | Get-AzureStorageBlob -Container temp -Blob $vhdname
    if(!$oldvm.StorageProfile.OsDisk.ManagedDisk){
    $sa | Remove-AzureStorageBlob -Container temp -Blob $vhdname -Force
    $sa | Remove-AzureStorageContainer -Name temp}
  }
   
}
function create-vmssfromimage{
param(
[Parameter(Mandatory=$true)] 
[String]$csvfilepath
 )
   #导入CSV文件
   $inputvalues = Import-Csv -Path $csvfilepath 

   #对CSV中的内容逐条进行处理
   foreach($myinput in $inputvalues){
    $loc = $myinput.location;
    $rg = $myinput.newrgname;
    $vnetrgname = $myinput.vnetrgname
    $vnetname = $myinput.vnetname
    $subnetName = $myinput.subnetname
    $imagename = $myinput.imagename
    $numberofnodes = $myinput.numberofnode
    $adminUsername = $myinput.osaccountname;
    $adminPassword = $myinput.ospassword;
    $Size = "Standard_A1"
    $vmssName =  $myinput.vmssname;
   





    $pipname = 'pip'+$vmssName
    $vmNamePrefix = $vmssName ;

    $vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetrgname;
    $subnetId = $vnet.Subnets[0].Id;

    $pubip = New-AzureRmPublicIpAddress -Force -Name $pipname `
　　    -ResourceGroupName $rg -Location $loc -AllocationMethod Static  `
　　    -DomainNameLabel $pipname;
    $pubip = Get-AzureRmPublicIpAddress -Name $pipname `
　　    -ResourceGroupName $rg;

    $frontendName = 'fe' + $vmssName
    $backendAddressPoolName = 'bepool' + $vmssName
    $probeName = 'vmssprobe' + $vmssName
    $inboundNatPoolName = 'innatpool' + $vmssName
    $lbruleName = 'lbrule' + $vmssName
    $lbName = 'lb' + $vmssName

    $frontend = New-AzureRmLoadBalancerFrontendIpConfig `
　　    -Name $frontendName -PublicIpAddress $pubip

    $backendAddressPool = New-AzureRmLoadBalancerBackendAddressPoolConfig `
　　    -Name $backendAddressPoolName

    $probe = New-AzureRmLoadBalancerProbeConfig -name $probeName `
　　    -Protocol Tcp -Port 80 -IntervalInSeconds 15 -ProbeCount 2 

    $frontendpoolrangestart = 22100
    $frontendpoolrangeend = 22200
    $backendvmport = 22
    $inboundNatPool = New-AzureRmLoadBalancerInboundNatPoolConfig `
　　    -Name $inboundNatPoolName `
　　    -FrontendIPConfigurationId $frontend.Id -Protocol Tcp `
　　    -FrontendPortRangeStart $frontendpoolrangestart `
　　    -FrontendPortRangeEnd $frontendpoolrangeend `
　　    -BackendPort $backendvmport;

    $protocol = 'Tcp'
    $feLBPort = 80
    $beLBPort = 80

    $lbrule = New-AzureRmLoadBalancerRuleConfig -Name $lbruleName `
　　    -FrontendIPConfiguration $frontend `
　　    -BackendAddressPool $backendAddressPool `
　　    -Probe $probe -Protocol $protocol `
　　    -FrontendPort $feLBPort -BackendPort $beLBPort `
　　    -IdleTimeoutInMinutes 15 -LoadDistribution SourceIP 

    $actualLb = New-AzureRmLoadBalancer -Name $lbName `
　　    -ResourceGroupName $rg `
　　    -Location $loc -FrontendIpConfiguration $frontend `
　　    -BackendAddressPool $backendAddressPool -Probe $probe 　`
　　    -LoadBalancingRule $lbrule `
　　    -InboundNatPool $inboundNatPool 

    $expectedLb = Get-AzureRmLoadBalancer -Name $lbName `
　　    -ResourceGroupName $rg

    $ipCfg = New-AzureRmVmssIPConfig -Name 'nic' `
    -LoadBalancerInboundNatPoolsId $actualLb.InboundNatPools[0].Id `
    -LoadBalancerBackendAddressPoolsId $actualLb.BackendAddressPools[0].Id `
    -SubnetId $subnetId;

    $image = Get-AzureRmImage -ResourceGroupName $rg -ImageName $imagename

    $vmss = New-AzureRmVmssConfig -Location $loc -SkuCapacity $numberofnodes `
　　    -SkuName $Size -UpgradePolicyMode 'automatic'  `
　　    | Add-AzureRmVmssNetworkInterfaceConfiguration -Name $subnetName `
　　　　    -Primary $true -IPConfiguration $ipCfg `
　　    | Set-AzureRmVmssOSProfile -ComputerNamePrefix $vmNamePrefix `
　　　　    -AdminUsername $adminUsername -AdminPassword $adminPassword `
　　    | Set-AzureRmVmssStorageProfile -OsDiskCreateOption 'FromImage' `
　　　　    -OsDiskCaching 'None' -OsDiskOsType Linux  `
　　　　    -ManagedDisk StandardLRS -ImageReferenceId $image.Id 

    New-AzureRmVmss -ResourceGroupName $rg -Name $vmssName -VirtualMachineScaleSet $vmss

    }
    }

$csvfilepath = "d:\a.csv"

create-vmimage -csvfilepath $csvfilepath
create-vmssfromimage -csvfilepath $csvfilepath
