    function create-vmimage{
    param(
    [Parameter(Mandatory=$true)] 
    [String]$csvfilepath
    )

   # $csvfilepath = "d:\a.csv"
    #导入CSV文件
    $inputvalues = Import-Csv -Path $csvfilepath 

    #对CSV中的内容逐条进行处理
  foreach($myinput in $inputvalues){
    #$myinput = $inputvalues[0]
    $rgs = Get-AzureRmResourceGroup -Location $myinput.location
    $rgmark = $false
    foreach($rg in $rgs){
      if($rg.ResourceGroupName -eq $myinput.newrgname){$rgmark = $true; break}
    }
    
    if(!$rgmark){
    New-AzureRmResourceGroup -Name $myinput.newrgname -Location $myinput.location}
    #获得源VM的信息
    $oldvm = Get-AzureRmVM -ResourceGroupName $myinput.oldrgname -Name $myinput.vmname
    #对DISK的类型进行转换
    if($myinput.vmStorageType -eq "Standard_LRS"){$sat = "Standard_LRS"}else{$sat = "Premium_LRS"}

    if($oldvm.StorageProfile.OsDisk.ManagedDisk){
       write-host "Copying OS Disk"
       $osdid = $oldvm.StorageProfile.OsDisk.ManagedDisk.Id
       $oldosdiskname = $osdid.Split('/')[-1]
       $oldosdisk = Get-AzureRmDisk -ResourceGroupName $myinput.oldrgname -DiskName $oldosdiskname
       $osdiskname = $oldvm.Name + "-os"
       $osdiskconfig = New-AzureRmDiskConfig -SkuName $sat -OsType $myinput.osType -DiskSizeGB $oldosdisk.DiskSizeGB -CreateOption Copy -SourceResourceId $osdid -Location $myinput.location
       $osdisk = New-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $osdiskname -Disk $osdiskconfig

    }else
    {write-host false
     write-output "not support VHD disk anymore"
     
        }
#####################data-disk begin#######################################
    #对数据盘进行复制
    $olddatadisks = $oldvm.StorageProfile.DataDisks
    $datadisks = @()
    for($datadiski=1; $datadiski -le $olddatadisks.Count; $datadiski++ )
    {   
        Write-Output "Copying Data Disk"
        #磁盘名称中加入时间信息
        $daytime = Get-Date -UFormat "%Y%m%d"
        #磁盘名称中加入随机数 
        $hash = $null 
        for ($i = 0; $i -le 5; $i++){ 
        $j = (48..57) | Get-Random -Count 1 | % {[char]$_} 
        $hash = $hash + $j }
        $datadiskname = $oldvm.Name + "-data" + $datadiski +"-"+ $daytime +"-"+ $hash
        #根据数据盘的类型，进行复制，最后都生成托管磁盘，复制过程和OS盘类似
        if($oldvm.StorageProfile.OsDisk.ManagedDisk){
            $mydatadiskconfig = New-AzureRmDiskConfig -SkuName $sat -DiskSizeGB $olddatadisks[$datadiski-1].DiskSizeGB -CreateOption Copy -SourceResourceId $olddatadisks[$datadiski-1].ManagedDisk.Id -Location $myinput.location 
            $mydatadisk = New-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $datadiskname -Disk $mydatadiskconfig 
        }
        else{
            write-output "not support VHD disk anymore"
           
        }
        #把生成的新磁盘，加入到磁盘数组中
        $datadisks = $datadisks + $mydatadisk
    }
#####################data-disk end#########################################

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
    $tmpvm = Set-AzureRmVMOSDisk -VM $tmpvm  -ManagedDiskId $osdisk.Id -CreateOption Attach -Linux -StorageAccountType $sat
    #添加Data盘
    #$tmpvm = Add-AzureRmVMDataDisk -VM $tmpvm -ManagedDiskId $datadisk.Id -Lun 1 -CreateOption Attach -StorageAccountType StandardLRS
    #添加网卡
    $tmpvm = Add-AzureRmVMNetworkInterface -VM $tmpvm -Id $vmnic.id -Primary
    #创建临时VM
    $tmpvm = new-azurermvm -ResourceGroupName $myinput.newrgname -Location $myinput.location -VM $tmpvm
    $tmpvm = Get-AzureRmVM -ResourceGroupName $myinput.newrgname -Name $tmpvmname
        
    #添加数据盘
    for($i=1; $i -le $datadisks.Count; $i++ )
    {
        $lun = $i + 1
        $tmpvm = Add-AzureRmVMDataDisk -VM $tmpvm -ManagedDiskId $datadisks[$i-1].id -Lun $lun -CreateOption Attach -StorageAccountType $sat -Name $datadisks[$i-1].name
     }
        
    Update-AzureRmVM -VM $tmpvm -ResourceGroupName $myinput.newrgname
    Restart-AzureRmVM  -ResourceGroupName $myinput.newrgname -Name $tmpvmname  
    
    #获取pip地址
    $pip = Get-AzureRmPublicIpAddress -ResourceGroupName $myinput.newrgname -Name $vmpipname

    #ssh到VM中，进行Generalize
    sleep(60)
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
    write-output "deleting tempvm os disk"
    Remove-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $osdiskname -Force
    write-output $datadisks.Count
    for($i=1; $i -le $datadisks.Count; $i++ )
    {
        write-output "deleting tempvm data disk"
        write-output $i
        write-output $datadisks[$i-1].id
        Write-Output $datadisks[$i-1].name
        Write-Output $datadisks[$i-1].DiskSizeGB
        Remove-AzureRmDisk -ResourceGroupName $myinput.newrgname -DiskName $datadisks[$i-1].name -Force
    }
    
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
    $Size = $myinput.vmsize
    $vmssName =  $myinput.vmssname;
    #对DISK的类型进行转换
    if($myinput.vmStorageType -eq "Standard_LRS"){$sat = "Standard_LRS"}else{$sat = "Premium_LRS"}





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
　　　　    -ManagedDisk $sat -ImageReferenceId $image.Id 

    New-AzureRmVmss -ResourceGroupName $rg -Name $vmssName -VirtualMachineScaleSet $vmss

    }
    }

$csvfilepath = "d:\a.csv"

create-vmimage -csvfilepath $csvfilepath
create-vmssfromimage -csvfilepath $csvfilepath
