function swap-vmsslbip {
param(
    [Parameter(Mandatory=$true)] 
    [String]$loc,

    [Parameter(Mandatory=$true)] 
    [String]$rg,

    [Parameter(Mandatory=$true)] 
    [String]$vmssName01,

    [Parameter(Mandatory=$true)] 
    [String]$vmssName02
)

    $subhash = $null
    for ($i = 0; $i -le 4; $i++){
        $j = (97..122) | Get-Random -Count 1 | % {[char]$_}
        $subhash = $subhash + $j
    }
    $tempipname = $subhash + 'temppip'

    $vmss1 = get-azurermvmss -ResourceGroupName $rg -vmscalesetname $vmssname01
    $vmss2 = get-azurermvmss -ResourceGroupName $rg -VMScaleSetName $vmssName02

    $vmss1lbname = $vmss1.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools[0].Id.Split('/')[8]
    $vmss2lbname = $vmss2.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools[0].Id.Split('/')[8]

    $vmss1lb = Get-AzureRmLoadBalancer -ResourceGroupName $rg -Name $vmss1lbname 
    $vmss2lb = Get-AzureRmLoadBalancer -ResourceGroupName $rg -Name $vmss2lbname

    $temppip = New-AzureRmPublicIpAddress -Name $tempipname -ResourceGroupName $rg -Location $loc -AllocationMethod Static

    $vmss1lbipid = $vmss1lb.FrontendIpConfigurations[0].PublicIpAddress.Id
    $vmss2lbipid = $vmss2lb.FrontendIpConfigurations[0].PublicIpAddress.Id

    $vmss1lb.FrontendIpConfigurations[0].PublicIpAddress.Id = $temppip.Id

    Set-AzureRmLoadBalancer -LoadBalancer $vmss1lb 

    $vmss2lb.FrontendIpConfigurations[0].PublicIpAddress.Id = $vmss1lbipid

    Set-AzureRmLoadBalancer -LoadBalancer $vmss2lb

    $vmss1lb.FrontendIpConfigurations[0].PublicIpAddress.Id = $vmss2lbipid

    Set-AzureRmLoadBalancer -LoadBalancer $vmss1lb

    Remove-AzureRmPublicIpAddress -ResourceGroupName $rg -Name $tempipname -Force
}


$loc = 'chinanorth';
$rg = 'hwvmss01';

$vmssName01 = "hwvmss01335"
$vmssName02 = "hwvmss01335"

swap-vmsslbip -loc $loc -rg $rg -vmssName01 $vmssName01 -vmssName02 $vmssName02

