
 

function new-vmssfromimage {
param(
    [Parameter(Mandatory=$true)] 
    [String]$loc,

    [Parameter(Mandatory=$true)] 
    [String]$rg,

    [Parameter(Mandatory=$true)] 
    [String]$vnetname,

    [Parameter(Mandatory=$true)] 
    [String]$subnetName,

    [Parameter(Mandatory=$true)] 
    [String]$imagename,

    [Parameter(Mandatory=$true)] 
    [Int]$numberofnodes,

    [Parameter(Mandatory=$true)] 
    [String]$adminUsername,

    [Parameter(Mandatory=$true)] 
    [String]$adminPassword,

    [Parameter(Mandatory=$true)] 
    [String]$vmssName, 

    [Parameter(Mandatory=$true)] 
    [String]$Size



)

    $pipname = 'pip'+$vmssName
    $vmNamePrefix = $vmssName ;

    $vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $rg;
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

    $vmss = get-azurermvmss -ResourceGroupName $rg -VMScaleSetName $vmssName 
    $autosettingname = $vmssName + 'autoscale'

    $rule1 = New-AzureRmAutoscaleRule -MetricName "Percentage CPU" -MetricResourceId $vmss.Id -Operator GreaterThan -MetricStatistic Average -Threshold 60 -TimeGrain 00:01:00 -TimeWindow 00:05:00 -ScaleActionCooldown 00:05:00 -ScaleActionDirection Increase -ScaleActionValue 1
    $rule2 = New-AzureRmAutoscaleRule -MetricName "Percentage CPU" -MetricResourceId $vmss.Id -Operator LessThan -MetricStatistic Average -Threshold 30 -TimeGrain 00:01:00 -TimeWindow 00:05:00 -ScaleActionCooldown 00:05:00 -ScaleActionDirection Decrease -ScaleActionValue 1
    $autopro1 = New-AzureRmAutoscaleProfile -Name myprofile1 -DefaultCapacity 3 -MaximumCapacity 3 -MinimumCapacity 3 -RecurrenceFrequency Week -ScheduleDays Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday -ScheduleHours 06 -ScheduleMinutes 00 -ScheduleTimeZone "China Standard Time" -Rules $rule1,$rule2
    $autopro2 = New-AzureRmAutoscaleProfile -Name myprofile2 -DefaultCapacity 2 -MaximumCapacity 2 -MinimumCapacity 2 -RecurrenceFrequency Week -ScheduleDays Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday -ScheduleHours 20 -ScheduleMinutes 00 -ScheduleTimeZone "China Standard Time" -Rules $rule1,$rule2

    Add-AzureRmAutoscaleSetting -Location $loc -Name $autosettingname -ResourceGroup $rg -TargetResourceId $vmss.Id -AutoscaleProfiles $autopro1,$autopro2
}



$loc = 'chinanorth';
$rg = 'hwvmss01';
$vnetname = $rg + 'vnet'
$subnetName = 'vlan1'
$imagename = "hwvmss01335-335"
$numberofnodes = 2
$adminUsername = 'xxxx';
$adminPassword = "xxxx";
$Size = "Standard_A1"

$time = Get-Date
$vmssName =  $rg + ($time.DayOfYear+1);

new-vmssfromimage -loc $loc -rg $rg -vnetname $vnetname -subnetName $subnetName -imagename $imagename `
 -numberofnodes $numberofnodes -adminUsername $adminUsername -adminPassword $adminPassword -vmssName $vmssName -Size $Size 
 