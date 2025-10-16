<#
  system_audit.ps1
  ----------------
  Thorough Windows machine audit: OS, CPU, RAM, GPU, disks/volumes, battery,
  network, security (TPM/SecureBoot/BitLocker), dev stack (WSL/Hyper-V/.NET/Python/Conda),
  Explorer visibility state, and WSL distros.

  Output: win_system_audit_<timestamp>.txt on Desktop
  Run:    Windows PowerShell (no admin required)
#>

$ErrorActionPreference = 'SilentlyContinue'
function NowStr { (Get-Date).ToString('yyyy-MM-ddTHHmmssK') }
$ts = NowStr
$out = Join-Path ([Environment]::GetFolderPath('Desktop')) ("win_system_audit_{0}.txt" -f $ts)
$nl = "`r`n"
function S($t){ ("`n=== {0} ===`n" -f $t) | Tee-Object -FilePath $out -Append }

"=== WINDOWS SYSTEM AUDIT ($ts) ===$nl" | Tee-Object -FilePath $out

S "Machine & OS"
$cs=Get-CimInstance Win32_ComputerSystem; $os=Get-CimInstance Win32_OperatingSystem; $bb=Get-CimInstance Win32_BaseBoard; $bios=Get-CimInstance Win32_BIOS
@(
 "Manufacturer        : $($cs.Manufacturer)",
 "Model               : $($cs.Model)",
 "Total RAM (GB)      : {0:N2}" -f ($cs.TotalPhysicalMemory/1GB),
 "OS                  : $($os.Caption) $($os.OSArchitecture)",
 "OS Version          : $($os.Version)  Build $($os.BuildNumber)",
 "Install Date        : $([Management.ManagementDateTimeconverter]::ToDateTime($os.InstallDate))",
 "Motherboard         : $($bb.Manufacturer) $($bb.Product)",
 "BIOS                : $($bios.SMBIOSBIOSVersion)"
) -join $nl | Tee-Object -FilePath $out -Append

S "CPU"
$cpu=Get-CimInstance Win32_Processor
@(
 "Name                : $($cpu.Name)",
 "Cores / Logical     : $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)",
 "Base Clock (MHz)    : $($cpu.MaxClockSpeed)"
) -join $nl | Tee-Object -FilePath $out -Append

S "Memory Modules"
Get-CimInstance Win32_PhysicalMemory | Select BankLabel,Capacity,Speed,PartNumber |
 ForEach-Object { "Bank: $($_.BankLabel)  Size: {0:N2} GB  Speed: $($_.Speed) MT/s  Part: $($_.PartNumber)" -f ($_.Capacity/1GB) } |
 Tee-Object -FilePath $out -Append

S "Graphics"
Get-CimInstance Win32_VideoController | ForEach-Object {
 "GPU: $($_.Name)  |  VRAM: {0:N2} GB  |  Driver: $($_.DriverVersion)" -f ($_.AdapterRAM/1GB)
} | Tee-Object -FilePath $out -Append

S "Storage (Physical)"
Get-CimInstance Win32_DiskDrive | Select Index,Model,InterfaceType,MediaType,Size |
 ForEach-Object { "Disk $($_.Index): $($_.Model) | Type: $($_.InterfaceType) $($_.MediaType) | Size: {0:N2} GB" -f ($_.Size/1GB) } |
 Tee-Object -FilePath $out -Append

S "Volumes"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
 ForEach-Object { "Drive $($_.DeviceID): $($_.FileSystem) | Free/Total: {0:N1}/{1:N1} GB" -f ($_.FreeSpace/1GB), ($_.Size/1GB) } |
 Tee-Object -FilePath $out -Append

S "Battery"
$bat=Get-CimInstance Win32_Battery
if ($bat){
 @("Status: $($bat.BatteryStatus)","Design Voltage (mV): $($bat.DesignVoltage)","Estimated Run Time: $($bat.EstimatedRunTime) min") -join $nl |
  Tee-Object -FilePath $out -Append
}else{"No battery detected." | Tee-Object -FilePath $out -Append}

S "Network"
Get-CimInstance Win32_NetworkAdapter -Filter "PhysicalAdapter=True" | Where-Object {$_.NetEnabled} |
 ForEach-Object {
  $cfg=Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "Index=$($_.Index)"
  "Adapter: $($_.Name) | MAC: $($_.MACAddress) | IPv4: $($cfg.IPAddress -join ', ')"
 } | Tee-Object -FilePath $out -Append

S "Security"
function TryRun([scriptblock]$b){ try { & $b } catch { $null } }
$tpm = TryRun { Get-Tpm }
$sb  = TryRun { Confirm-SecureBootUEFI }
$blv = TryRun { Get-BitLockerVolume | Select-Object -ExpandProperty ProtectionStatus }
@(
 "TPM Present/Ready    : $(if($tpm){$tpm.TpmPresent,$tpm.TpmReady -join '/'}else{'Unknown'})",
 "Secure Boot          : $(if($sb -is [bool]){$sb}else{'Unknown/Legacy BIOS'})",
 "BitLocker Status     : $(if($blv){ ($blv -join ', ') } else { 'Off/Unavailable' })"
) -join $nl | Tee-Object -FilePath $out -Append

S "Dev Stack"
$wslFeat = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmFeat  = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
@(
 "WSL Feature          : $($wslFeat.State)",
 "VM Platform          : $($vmFeat.State)",
 ".NET SDKs            : $((TryRun { (& 'dotnet' --list-sdks) -join ' | ' }) -replace '\r','')",
 "Python Version       : $((TryRun { & 'python' --version }) -replace '\r','')",
 "Conda Version        : $((TryRun { & 'conda' --version }) -replace '\r','')"
) -join $nl | Tee-Object -FilePath $out -Append

S "Explorer Visibility"
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
@(
 "HideFileExt (0=show) : " + (Get-ItemProperty -Path $adv -Name HideFileExt -ErrorAction SilentlyContinue).HideFileExt,
 "Hidden (1=show)      : " + (Get-ItemProperty -Path $adv -Name Hidden -ErrorAction SilentlyContinue).Hidden,
 "ShowSuperHidden (1)  : " + (Get-ItemProperty -Path $adv -Name ShowSuperHidden -ErrorAction SilentlyContinue).ShowSuperHidden
) -join $nl | Tee-Object -FilePath $out -Append

S "WSL Distros"
TryRun { (& wsl -l -v) } | Tee-Object -FilePath $out -Append

"`nSaved to: $out`n" | Tee-Object -FilePath $out -Append
Write-Host "`nSaved to: $out`n" -ForegroundColor Green
