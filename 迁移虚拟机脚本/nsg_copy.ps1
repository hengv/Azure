Select-AzureRmSubscription -Subscriptionid $sub1id                                                                                            
Get-AzureRmNetworkSecurityGroup -ResourceGroupName $sub1rg                                                                                    
$nsgs = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $sub1rg                                                                            
$nsgs[0]                                                                                                                                      
$nsgs[0].SecurityRules[0]                                                                                                                     
Select-AzureRmSubscription -Subscriptionid $sub2id                                                                                            
New-AzureRmNetworkSecurityGroup -ResourceGroupName bjchoice -Name $nsgs[0].Name -Location "China North"                                       
$newnsg = get-AzureRmNetworkSecurityGroup -ResourceGroupName bjchoice -Name $nsgs[0].Name                                                     
$newnsg.Name                                                                                                                                  
$newnsg.SecurityRules                                                                                                                         
$newnsg.SecurityRules = $nsgs[0].SecurityRules                                                                                                
$newnsg                                                                                                                                       
$newnsg.SecurityRules                                                                                                                         
Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $newnsg  