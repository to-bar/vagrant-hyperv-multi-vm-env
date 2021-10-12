# Changes network switch of specified VM
#
# See: https://www.thomasmaurer.ch/2016/01/change-hyper-v-vm-switch-of-virtual-machines-using-powershell

Param(
    [Parameter(Mandatory, HelpMessage = "Name of target vSwitch")]
    [String]
    $SwitchName,
    [Parameter(Mandatory, HelpMessage = "Name of VM to be connected to vSwitch")]
    [String]
    $VMName
)

$ErrorActionPreference = "Stop"

$currentSwitchName = Get-VM $vmName | Get-VMNetworkAdapter | Select-Object -ExpandProperty SwitchName

if ($currentSwitchName -ne $SwitchName) {
    Write-Host "Changing switch from `"$currentSwitchName`" to `"$SwitchName`" for VM `"$vmName`""
    Get-VM $vmName | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName $SwitchName
}
else {
    Write-Host "VM `"$vmName`" already configured to use switch `"$SwitchName`", skipping"
}
