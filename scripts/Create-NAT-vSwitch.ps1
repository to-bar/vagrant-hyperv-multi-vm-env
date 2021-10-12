# Creates NAT-enabled vSwitch for Hyper-V (for static IP configuration)
#
# See: https://www.petri.com/using-nat-virtual-switch-hyper-v
#
# Based on:
# 1) https://superuser.com/questions/1354658/hyperv-static-ip-with-vagrant/1379582#1379582
# 2) https://github.com/hashicorp/vagrant/issues/8384#issuecomment-548988185

Param(
    [Parameter(HelpMessage = "Name of vSwitch to be created")]
    [String]
    $SwitchName = "NAT Switch",
    # Gateway
    [Parameter(HelpMessage = "IP address to assign to vNIC, gateway for network on NAT network")]
    [String]
    $IPAddress = "192.168.20.1",
    [Parameter(HelpMessage = "Number of bits used for subnet masking")]
    [Byte]
    $PrefixLength = 24,
    # NAT network
    [Parameter(HelpMessage = "Network address of NAT network that will run on vSwitch")]
    [String]
    $NATNetworkAddressPrefix = "192.168.20.0/24",
    [Parameter(HelpMessage = "Name of NAT object")]
    [String]
    $NATName = "Vagrant on Hyper-V"
)

$ErrorActionPreference = "Stop"

# Create vSwitch
$vSwitchExists = $SwitchName -in (Get-VMSwitch | Select-Object -ExpandProperty Name)
if (-not $vSwitchExists) {
    Write-Host "Creating internal switch `"$SwitchName`" on Windows host..."

    New-VMSwitch -SwitchName $SwitchName -SwitchType Internal
}
else {
    Write-Host "Switch `"$SwitchName`" already exists, skipping"
}

# Assign IP to vNIC
$ipAddressExists = $IPAddress -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress)
if (-not $ipAddressExists) {
    Write-Host "Registering new IP gateway address `"$IPAddress`" for vSwitch `"$SwitchName`" on Windows host..."

    New-NetIPAddress -IPAddress $IPAddress -PrefixLength $PrefixLength -InterfaceAlias "vEthernet ($SwitchName)"
}
else {
    Write-Host "IP address `"$IPAddress`" already registered, skipping"
}

# Configure network address of NAT network
$natNetworkExists = $NATNetworkAddressPrefix -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix)
if (-not $natNetworkExists) {
    Write-Host "Registering new NAT adapter `"$NATName`" for network `"$NATNetworkAddressPrefix`" on Windows host..."

    New-NetNAT -Name $NATName -InternalIPInterfaceAddressPrefix $NATNetworkAddressPrefix
}
else {
    Write-Host "NAT adapter for network `"$NATNetworkAddressPrefix`" already registered, skipping"
}
