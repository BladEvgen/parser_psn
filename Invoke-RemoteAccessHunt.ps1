#Requires -Version 3.0

[CmdletBinding()]
param(
    [int]$LookbackHours = 24,
    [string]$OutRoot = "$env:SystemDrive\IR"
)

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Case  = Join-Path $OutRoot ("RAHunt_{0}_{1}" -f $env:COMPUTERNAME, $Stamp)
$Raw   = Join-Path $Case 'raw'
$Since = (Get-Date).AddHours(-1 * [math]::Abs($LookbackHours))
New-Item -ItemType Directory -Path $Raw -Force | Out-Null

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$script:Report   = New-Object System.Collections.ArrayList
$script:Findings = New-Object System.Collections.ArrayList
function R   { param([string]$t='') [void]$script:Report.Add($t) }
function RH  { param([string]$t) R ''; R ('=' * 70); R $t; R ('=' * 70) }
function Add-F { param([ValidateSet('FOUND','POSSIBLE','INFO')]$L,$Area,$Detail)
               [void]$script:Findings.Add([pscustomobject]@{Level=$L;Area=$Area;Detail=$Detail}) }

function RTable {
    param($Data,[string[]]$Props,[string]$Empty='(none)')
    if (-not $Data) { R "  $Empty"; return }
    $rows = @($Data | Select-Object $Props)
    $w = @{}; foreach ($p in $Props){ $w[$p] = ($p.Length, (($rows | ForEach-Object { ("" + $_.$p).Length }) | Measure-Object -Maximum).Maximum | Measure-Object -Maximum).Maximum }
    R ("  " + (($Props | ForEach-Object { $_.PadRight($w[$_]) }) -join '  '))
    R ("  " + (($Props | ForEach-Object { ('-' * $w[$_]) }) -join '  '))
    foreach ($r in $rows){ R ("  " + (($Props | ForEach-Object { ("" + $r.$_).PadRight($w[$_]) }) -join '  ')) }
}

function Csv { param($Data,$Name) if ($Data){ @($Data) | Export-Csv -Path (Join-Path $Raw $Name) -NoTypeInformation -Encoding UTF8 } }

function Hit { param($t) Write-Host "   [+] $t" -ForegroundColor Yellow }
function Bad { param($t) Write-Host "   [!] $t" -ForegroundColor Red }
function Ok  { param($t) Write-Host "   [-] $t" -ForegroundColor DarkGreen }
function Sec { param($t) Write-Host ""; Write-Host ("== {0} " -f $t).PadRight(70,'=') -ForegroundColor Cyan }

Clear-Host
Write-Host "Remote Access Hunt v3" -ForegroundColor White
Write-Host ("Host {0}  User {1}  Admin {2}  Lookback {3}h" -f $env:COMPUTERNAME,$env:USERNAME,$IsAdmin,$LookbackHours)
if (-not $IsAdmin){ Bad "Not elevated - results incomplete. Re-run as administrator." }

R ("Remote Access Hunt - report")
R ("Host      : {0}" -f $env:COMPUTERNAME)
R ("Generated : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
R ("Lookback  : last {0}h (since {1})" -f $LookbackHours,$Since.ToString('yyyy-MM-dd HH:mm'))
R ("Elevated  : {0}" -f $IsAdmin)

$Sig = @(
 @{N='TeamViewer';   Exe='teamviewer','teamviewer_service','tv_w32','tv_x64'; D='^TeamViewer'; Port=5938}
 @{N='AnyDesk';      Exe='anydesk';                       D='^AnyDesk';        Port=6568}
 @{N='RustDesk';     Exe='rustdesk';                      D='^RustDesk';       Port=21116}
 @{N='Chrome Remote Desktop'; Exe='remoting_host','remote_assistance_host'; D='Chrome Remote Desktop'; Port=0}
 @{N='VNC';          Exe='winvnc','uvnc_service','tvnserver','vncserver','vncserverui','winvnc4'; D='(UltraVNC|TightVNC|RealVNC|TigerVNC|VNC Server|VNC Viewer)'; Port=5900}
 @{N='Ammyy Admin';  Exe='aa_v3','ammyy';                 D='Ammyy';           Port=0}
 @{N='Splashtop';    Exe='srservice','srserver','srfeature','strwinclt'; D='Splashtop'; Port=0}
 @{N='ScreenConnect/ConnectWise'; Exe='screenconnect.clientservice','screenconnect.windowsclient'; D='(ScreenConnect|ConnectWise Control)'; Port=0}
 @{N='Atera';        Exe='ateraagent','agentpackagemonitoring'; D='Atera';     Port=0}
 @{N='Parsec';       Exe='parsecd','parsec';              D='^Parsec';         Port=0}
 @{N='DWService';    Exe='dwagent','dwagsvc';             D='(DWAgent|DWService)'; Port=0}
 @{N='Supremo';      Exe='supremo','supremoservice','supremohelper'; D='Supremo'; Port=0}
 @{N='LiteManager';  Exe='romserver','romfusclient','romviewer'; D='LiteManager'; Port=5650}
 @{N='Radmin';       Exe='rserver3','famtrayicon';        D='^Radmin';         Port=4899}
 @{N='Remote Utilities'; Exe='rutserv','rfusclient';      D='Remote Utilities'; Port=5655}
 @{N='NoMachine';    Exe='nxservice','nxnode','nxplayer'; D='NoMachine';       Port=4000}
 @{N='Mesh/MeshCentral'; Exe='meshagent';                 D='(MeshCentral|Mesh Agent)'; Port=0}
 @{N='NinjaOne RMM'; Exe='ninjarmmagent','ninjarmm-cli';  D='(NinjaRMM|NinjaOne)'; Port=0}
 @{N='Syncro/Kabuto';Exe='syncro','kabuto';               D='(Syncro|Kabuto)'; Port=0}
 @{N='Action1';      Exe='action1_agent','a1_agent';      D='Action1';         Port=0}
 @{N='GoTo (Assist/MyPC)'; Exe='g2comm','g2svc','g2host','goto opener'; D='(GoToAssist|GoTo Opener|GoToMyPC)'; Port=0}
 @{N='LogMeIn';      Exe='lmiguardiansvc','ramaint','logmein'; D='^LogMeIn';   Port=0}
 @{N='Zoho Assist';  Exe='za_service','za_access','za_connect'; D='Zoho Assist'; Port=0}
 @{N='AeroAdmin';    Exe='aeroadmin';                     D='AeroAdmin';       Port=0}
 @{N='Quick Assist'; Exe='quickassist';                   D='Quick Assist';    Port=0}
 @{N='Remote Assistance'; Exe='msra';                     D='__none__';        Port=0}
)
$ExeSet  = ($Sig | ForEach-Object { $_.Exe }) | Select-Object -Unique
$NameOf  = @{}; foreach($s in $Sig){ foreach($e in $s.Exe){ $NameOf[$e]=$s.N } }
function ToolByExe { param($base) $b=("$base").ToLower(); if($NameOf.ContainsKey($b)){$NameOf[$b]}else{$null} }

$ExtNameRx = 'remote desktop|remote control|chrome remote|remote support|teamviewer|anydesk|\bvnc\b|getscreen|screen sharing'
$KnownExtId = @{
 'gbchcmhmhahfdphkhkmpfmihenigjmpp'='Chrome Remote Desktop'
 'inomeogfingihgjfjlpeplalcfajhgai'='Chrome Remote Desktop (legacy)'
 'lfboplenmmjcmjbkeeaegfeojfapmhic'='Chrome Remote Desktop (host)'
}
$NativeHostRx = 'remote_desktop|chrome_remote|teamviewer|anydesk|getscreen'

Sec 'System & AD remnants'
$cs=Get-CimInstance Win32_ComputerSystem; $os=Get-CimInstance Win32_OperatingSystem
RH 'SYSTEM & AD'
R ("  OS         : {0} (build {1})" -f $os.Caption,$os.BuildNumber)
R ("  PartOfDomain: {0}   Domain/Workgroup: {1}" -f $cs.PartOfDomain,$cs.Domain)
if ($cs.PartOfDomain){ Hit "Currently domain-joined: $($cs.Domain)"; Add-F FOUND 'AD' "Domain-joined: $($cs.Domain)" }
$dc=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History' -EA SilentlyContinue).DCName
if ($dc){ Hit "Old GPO/DC reference: $dc"; R "  AD remnant : GPO history references DC '$dc'"; Add-F POSSIBLE 'AD' "Old GPO/DC reference: $dc" }
else { R "  AD remnant : none"; if(-not $cs.PartOfDomain){ Ok "No AD now; no obvious old-domain remnants." } }
secedit /export /cfg (Join-Path $Raw 'secpol.inf') /quiet 2>$null | Out-Null

Sec 'Remote-control software (process / service / binary / installed)'
$procs = Get-CimInstance Win32_Process
Csv ($procs | Select ProcessId,Name,ExecutablePath,CommandLine | Sort Name) 'processes.csv'
$pHits = foreach($p in $procs){ $t=ToolByExe ($p.Name -replace '\.exe$',''); if($t){ [pscustomobject]@{Tool=$t;PID=$p.ProcessId;Path=$p.ExecutablePath} } }

$svc = Get-CimInstance Win32_Service
Csv ($svc | Select Name,DisplayName,State,StartMode,StartName,PathName | Sort Name) 'services.csv'
$sHits = foreach($s in $svc){ $t=$null; foreach($e in $ExeSet){ if($s.PathName -match ("\\"+[regex]::Escape($e)+"\.exe")){ $t=$NameOf[$e] } }; if($t){ [pscustomobject]@{Tool=$t;Service=$s.Name;State=$s.State;Path=$s.PathName} } }

$scanRoots = @("$env:ProgramData","$env:APPDATA","$env:LOCALAPPDATA","$env:PUBLIC","$env:USERPROFILE\Downloads","$env:TEMP","$env:ProgramFiles","${env:ProgramFiles(x86)}") | Where-Object { $_ } | Select-Object -Unique
$dHits = foreach($r in $scanRoots){ Get-ChildItem $r -Recurse -Include '*.exe' -Depth 4 -EA SilentlyContinue | Where-Object { (ToolByExe $_.BaseName) } |
         ForEach-Object { [pscustomobject]@{Tool=(ToolByExe $_.BaseName);Path=$_.FullName;Written=$_.LastWriteTime} } }
Csv $dHits 'binaries.csv'

$uninst=@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
$installed = Get-ItemProperty $uninst | Where-Object { $_.DisplayName } | Select DisplayName,DisplayVersion,Publisher,InstallDate
Csv ($installed | Sort DisplayName) 'installed.csv'
$iHits = foreach($s in $Sig){ if($s.D -ne '__none__'){ $installed | Where-Object { $_.DisplayName -match $s.D } | ForEach-Object { [pscustomobject]@{Tool=$s.N;Name=$_.DisplayName;Version=$_.DisplayVersion} } } }

RH 'REMOTE-CONTROL SOFTWARE'
R '  Running processes:';   RTable $pHits 'Tool','PID','Path'           '(none running now)'
R ''; R '  Services:';      RTable $sHits 'Tool','Service','State','Path' '(none)'
R ''; R '  Binaries on disk:'; RTable $dHits 'Tool','Written','Path'      '(none in common locations)'
R ''; R '  Installed programs:'; RTable $iHits 'Tool','Version','Name'    '(none)'

foreach($x in $pHits){ Hit "Process: $($x.Tool) (PID $($x.PID))"; Add-F FOUND 'Process' "$($x.Tool) running: $($x.Path)" }
foreach($x in $sHits){ Hit "Service: $($x.Tool) [$($x.State)]"; Add-F FOUND 'Service' "$($x.Tool): $($x.Service) [$($x.State)]" }
foreach($x in $dHits){ Hit "Binary : $($x.Tool) -> $($x.Path)"; Add-F FOUND 'Binary' "$($x.Tool): $($x.Path)" }
foreach($x in $iHits){ Hit "Installed: $($x.Name)"; Add-F FOUND 'Installed' "$($x.Name) $($x.Version)" }
if (-not ($pHits -or $sHits -or $dHits -or $iHits)){ Ok "No known third-party remote tool found." }

Sec 'Browser remote desktop (extensions + native hosts)'
$browsers = @(
 @{B='Chrome'; Root="$env:LOCALAPPDATA\Google\Chrome\User Data"}
 @{B='Edge';   Root="$env:LOCALAPPDATA\Microsoft\Edge\User Data"}
 @{B='Brave';  Root="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"}
 @{B='Yandex'; Root="$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data"}
)
$extHits = New-Object System.Collections.ArrayList
foreach($br in $browsers){
 if(-not (Test-Path $br.Root)){ continue }
 $extDirs = Get-ChildItem (Join-Path $br.Root '*\Extensions\*') -Directory -EA SilentlyContinue
 foreach($ed in $extDirs){
   $extId = $ed.Name
   $man = Get-ChildItem $ed.FullName -Recurse -Filter manifest.json -EA SilentlyContinue | Select-Object -First 1
   $name=''; $raw=''
   if($man){ $raw = Get-Content $man.FullName -Raw -EA SilentlyContinue
             try{ $name = (ConvertFrom-Json $raw).name }catch{} }
   $isRemote = $KnownExtId.ContainsKey($extId) -or ($raw -match $ExtNameRx) -or ($name -match $ExtNameRx)
   if($isRemote){
     $label = if($KnownExtId.ContainsKey($extId)){$KnownExtId[$extId]}elseif($name -and $name -notmatch '^__MSG'){$name}else{'(remote-desktop extension)'}
     [void]$extHits.Add([pscustomobject]@{Browser=$br.B;Id=$extId;Name=$label;Path=$ed.FullName})
   }
 }
}
$nmHosts = New-Object System.Collections.ArrayList
$nmKeys = @(
 'HKCU:\Software\Google\Chrome\NativeMessagingHosts\*','HKLM:\Software\Google\Chrome\NativeMessagingHosts\*',
 'HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\*','HKLM:\Software\Microsoft\Edge\NativeMessagingHosts\*'
)
foreach($k in $nmKeys){ Get-Item $k -EA SilentlyContinue | ForEach-Object {
   if($_.PSChildName -match $NativeHostRx){ [void]$nmHosts.Add([pscustomobject]@{Host=$_.PSChildName;Manifest=(Get-ItemProperty $_.PSPath).'(default)'}) } } }
$crdDir = "$env:ProgramData\Google\Chrome Remote Desktop"
if(Test-Path $crdDir){ [void]$nmHosts.Add([pscustomobject]@{Host='chrome_remote_desktop_hostdir';Manifest=$crdDir}) }

Csv $extHits 'browser_extensions.csv'
Csv $nmHosts 'native_messaging_hosts.csv'
$crdHost = (Test-Path "$env:LOCALAPPDATA\Google\Chrome Remote Desktop\host*") -or `
           (Test-Path "$env:ProgramFiles\Google\Chrome Remote Desktop") -or `
           (@($svc | Where-Object { $_.Name -eq 'chromoting' }).Count -gt 0) -or `
           (@($procs | Where-Object { $_.Name -eq 'remoting_host.exe' }).Count -gt 0)
$crdExt = @($extHits | Where-Object { $_.Name -match 'Chrome Remote' }).Count -gt 0
RH 'BROWSER REMOTE DESKTOP'
R '  Remote-desktop browser extensions:'; RTable $extHits 'Browser','Name','Id' '(none)'
R ''; R '  Native messaging hosts (browser <-> local agent):'; RTable $nmHosts 'Host','Manifest' '(none)'
if($crdExt){
  R ''
  R ("  Chrome Remote Desktop HOST on THIS machine: {0}" -f $crdHost)
  if($crdHost){ R '  => This machine CAN be remotely controlled via CRD (host present).' }
  else { R '  => Only the CRD client/extension is here, no host: this account likely controls OTHER machines,'; R '     OR the host was removed. To see incoming control, run on the machine where the mouse moved.' }
}
foreach($x in $extHits){ Hit "Browser ext: $($x.Browser) / $($x.Name)"; Add-F FOUND 'BrowserExt' "$($x.Browser): $($x.Name) [$($x.Id)]" }
foreach($x in $nmHosts){ Hit "Native host: $($x.Host)"; Add-F FOUND 'NativeHost' "$($x.Host) -> $($x.Manifest)" }
if($crdExt){ if($crdHost){ Add-F FOUND 'CRD' 'Chrome Remote Desktop HOST present - machine is controllable' } else { Add-F POSSIBLE 'CRD' 'CRD client/extension only, no host on this machine' } }
if(-not ($extHits.Count -or $nmHosts.Count)){ Ok "No browser-based remote desktop (extension or native host)." }

# ===========================================================================
Sec 'Tool connection logs (who connected)'
$logT=@(
 @{T='TeamViewer';P=@("$env:ProgramFiles\TeamViewer\Connections_incoming.txt","${env:ProgramFiles(x86)}\TeamViewer\Connections_incoming.txt")}
 @{T='AnyDesk';   P=@("$env:ProgramData\AnyDesk\connection_trace.txt","$env:APPDATA\AnyDesk\connection_trace.txt")}
 @{T='RustDesk';  P=@("$env:APPDATA\RustDesk\log")}
)
RH 'TOOL CONNECTION LOGS'
$anyLog=$false
foreach($l in $logT){ foreach($p in $l.P){ if(Test-Path $p){ $anyLog=$true
   Copy-Item $p (Join-Path $Case ("LOG_{0}_{1}" -f $l.T,(Split-Path $p -Leaf))) -Force -EA SilentlyContinue
   R ("  {0}: {1}" -f $l.T,$p)
   if(-not (Get-Item $p).PSIsContainer){ Get-Content $p -Tail 12 | ForEach-Object { R "      $_" } }
   Hit "$($l.T) connection log copied: $p"; Add-F FOUND 'ToolLog' "$($l.T) incoming log: $p" } } }
if(-not $anyLog){ R '  (no native tool logs present)'; Ok "No tool connection logs found." }

Sec 'RDP / built-in remote (real status)'
$fDeny=(Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -EA SilentlyContinue).fDenyTSConnections
$rdpEnabled = ($fDeny -eq 0)
$rdpListen  = @(Get-NetTCPConnection -LocalPort 3389 -State Listen -EA SilentlyContinue).Count -gt 0
$rdpSess=@(); try{ $rdpSess=Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational';Id=21,22,25;StartTime=$Since} -EA Stop }catch{}
$rdpAuth=@(); try{ $rdpAuth=Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational';Id=1149;StartTime=$Since} -EA Stop }catch{}
$rdpRemoteSess = $rdpSess | Where-Object { $_.Message -match 'Source Network Address:\s*((?!LOCAL)\S+)' -and $_.Message -notmatch 'Source Network Address:\s*LOCAL' }
$rdpLocalSess  = @($rdpSess).Count - @($rdpRemoteSess).Count
$rdpRemoteHits = (@($rdpAuth).Count -gt 0) -or (@($rdpRemoteSess).Count -gt 0)
RH 'RDP / BUILT-IN REMOTE'
R ("  RDP enabled : {0}   Listening :3389 : {1}" -f $rdpEnabled,$rdpListen)
R ("  Session events : {0} (remote: {1}, local/console: {2})   Incoming auth (1149): {3}" -f @($rdpSess).Count,@($rdpRemoteSess).Count,$rdpLocalSess,@($rdpAuth).Count)
Csv (($rdpSess+$rdpAuth) | Select TimeCreated,Id,@{n='Message';e={($_.Message -replace "`r?`n",' | ')}}) 'rdp_events.csv'
if ($rdpEnabled -and $rdpRemoteHits){ Bad "RDP enabled WITH remote session/auth activity"; Add-F FOUND 'RDP' "RDP enabled + remote: $(@($rdpRemoteSess).Count) sessions / $(@($rdpAuth).Count) incoming auth" }
elseif ($rdpRemoteHits){ Hit "Incoming RDP activity present"; Add-F FOUND 'RDP' "Remote RDP: $(@($rdpRemoteSess).Count) sessions / $(@($rdpAuth).Count) auth" }
elseif ($rdpEnabled){ R "  Note: $(@($rdpSess).Count) session events are LOCAL console logons/unlocks - NOT remote."; Hit "RDP enabled, but session events look local (no incoming auth) - hardening risk, weak as evidence"; Add-F POSSIBLE 'RDP' "RDP enabled; $(@($rdpSess).Count) local session events, 0 remote" }
else { Ok "RDP disabled (default) - running TermService alone is normal." }

Sec 'Event logs (service install / Quick Assist / WinRM)'
function Ev { param($Log,$Ids) try{ Get-WinEvent -FilterHashtable @{LogName=$Log;Id=$Ids;StartTime=$Since} -EA Stop }catch{} }
$e7045=Ev 'System' 7045
$rmmInst=$e7045 | Where-Object { $m=$_.Message; ($ExeSet|Where-Object{ $m -match [regex]::Escape($_) }) -or ($Sig.N|Where-Object{ $m -match [regex]::Escape($_) }) }
$qa=Ev 'Microsoft-Windows-QuickAssist/Operational' @(1,2,3,4,5,100,101)
$winrm=Ev 'Microsoft-Windows-WinRM/Operational' @(91,168,169)
RH 'EVENT LOGS'
R ("  Service installs (7045) : {0}  (remote-tool matches: {1})" -f @($e7045).Count, @($rmmInst).Count)
R ("  Quick Assist : {0}    WinRM remote-mgmt : {1}" -f @($qa).Count, @($winrm).Count)
Csv ($e7045 | Select TimeCreated,@{n='Message';e={($_.Message -split "`n")[0]}}) 'service_installs.csv'
if($rmmInst){ foreach($e in $rmmInst){ Bad "Tool service installed at $($e.TimeCreated)"; Add-F FOUND 'EventLog' "Remote-tool service install at $($e.TimeCreated)" } } else { Ok "No remote-tool service-install event." }
if($qa){ Hit "Quick Assist activity"; Add-F FOUND 'EventLog' "Quick Assist events: $(@($qa).Count)" }
if($winrm){ Hit "WinRM remote-management activity"; Add-F FOUND 'EventLog' "WinRM events: $(@($winrm).Count)" }

Sec 'Network (meaningful connections only)'
$tcp=Get-NetTCPConnection -EA SilentlyContinue
RH 'NETWORK'
if($tcp){
 $toolPorts = ($Sig|Where-Object{$_.Port -gt 0}|ForEach-Object{$_.Port}) + 3389,5900,5901,5938,6568,7070 | Select-Object -Unique
 $isLocal = { param($a) ($a -match '^(127\.|169\.254|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)') -or ($a -in '::1','::','0.0.0.0','') }
 $est = $tcp | Where-Object { $_.State -eq 'Established' -and $_.RemotePort -gt 0 -and -not (& $isLocal $_.RemoteAddress) } |
        ForEach-Object { [pscustomobject]@{Proc=(Get-Process -Id $_.OwningProcess -EA SilentlyContinue).ProcessName;LocalPort=$_.LocalPort;RemoteAddress=$_.RemoteAddress;RemotePort=$_.RemotePort} }
 $toolConn = $est | Where-Object { $toolPorts -contains $_.RemotePort -or (ToolByExe $_.Proc) }
 R '  External established connections on remote-tool ports / by remote tools:'
 RTable $toolConn 'Proc','RemoteAddress','RemotePort' '(none)'
 R ''; R ("  Other external established connections: {0} (raw\\network.csv)" -f (@($est).Count - @($toolConn).Count))
 Csv ($est | Sort Proc) 'network.csv'
 if($toolConn){ foreach($c in $toolConn){ Hit "Net: $($c.Proc) -> $($c.RemoteAddress):$($c.RemotePort)"; Add-F FOUND 'Network' "$($c.Proc) -> $($c.RemoteAddress):$($c.RemotePort)" } }
 else { Ok "No external connection on a remote-tool port." }
} else { R '  Get-NetTCPConnection unavailable'; netstat -ano > (Join-Path $Raw 'netstat.txt') }

Sec 'Autostart & execution evidence'
$runKeys=@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')
$runEntries = foreach($k in $runKeys){ if(Test-Path $k){ (Get-Item $k).Property | ForEach-Object { [pscustomobject]@{Key=$k;Name=$_;Value=(Get-ItemProperty $k).$_} } } }
Csv $runEntries 'autostart.csv'
$autoHits = $runEntries | Where-Object { $v=$_.Value; $ExeSet | Where-Object { $v -match ("\\"+[regex]::Escape($_)+"\.exe") } }
$pf=Get-ChildItem "$env:SystemRoot\Prefetch\*.pf" -EA SilentlyContinue
Csv ($pf | Select Name,LastWriteTime | Sort LastWriteTime) 'prefetch.csv'
$pfHits = $pf | Where-Object { ToolByExe (($_.BaseName -split '-')[0]) } | ForEach-Object { [pscustomobject]@{Tool=(ToolByExe (($_.BaseName -split '-')[0]));LastRun=$_.LastWriteTime} }
$wmi = Get-CimInstance -Namespace root\subscription -ClassName __EventConsumer -EA SilentlyContinue | Where-Object { $_.Name -notmatch '^(SCM Event Log Consumer|BVTConsumer|TSEventConsumer)$' }
Csv ($wmi | Select Name,__CLASS,@{n='Detail';e={$_.CommandLineTemplate}}) 'wmi_consumers.csv'
RH 'AUTOSTART & EXECUTION'
R '  Run-key autostarts matching a remote tool:'; RTable $autoHits 'Name','Value' '(none)'
R ''; R '  Prefetch (past execution, survives uninstall):'; RTable $pfHits 'Tool','LastRun' '(none)'
R ''; R ("  Non-default WMI event consumers: {0}" -f @($wmi).Count)
foreach($a in $autoHits){ Hit "Autostart: $($a.Value)"; Add-F FOUND 'Autostart' "$($a.Value)" }
foreach($p in $pfHits){ Hit "Prefetch: $($p.Tool) ran at $($p.LastRun)"; Add-F FOUND 'Execution' "$($p.Tool) executed $($p.LastRun)" }
if($wmi){ Add-F POSSIBLE 'Autostart' "Non-default WMI consumers: $(@($wmi).Count)" }
if(-not ($autoHits -or $pfHits)){ Ok "No remote-tool autostart or execution trace." }

$found=$Findings|Where-Object Level -eq 'FOUND'; $poss=$Findings|Where-Object Level -eq 'POSSIBLE'
RH 'VERDICT'
if($found){ R ("  FOUND ({0}):" -f @($found).Count); $found|ForEach-Object{ R ("    [{0}] {1}" -f $_.Area,$_.Detail) } }
if($poss){ R ''; R ("  POSSIBLE ({0}) - manual review:" -f @($poss).Count); $poss|ForEach-Object{ R ("    [{0}] {1}" -f $_.Area,$_.Detail) } }
if(-not ($found -or $poss)){ R "  CLEAN - no remote-access indicators in this window."; R "  Tip: re-run with -LookbackHours 72 and check off-box firewall/Wi-Fi logs." }

if (@($script:Report).Count -eq 0){
  [void]$script:Report.Add("Remote Access Hunt - report (fallback)")
  [void]$script:Report.Add("Host: $env:COMPUTERNAME   Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
  [void]$script:Report.Add("")
  foreach($f in @($script:Findings)){ [void]$script:Report.Add(("[{0}] {1} - {2}" -f $f.Level,$f.Area,$f.Detail)) }
  if(@($script:Findings).Count -eq 0){ [void]$script:Report.Add("CLEAN - no remote-access indicators.") }
}
Set-Content -Path (Join-Path $Case 'REPORT.txt') -Value ($script:Report -join "`r`n") -Encoding UTF8
@($script:Findings) | ConvertTo-Json -Depth 4 | Out-File (Join-Path $Case 'findings.json') -Encoding UTF8
@($script:Findings) | Export-Csv (Join-Path $Case 'findings.csv') -NoTypeInformation -Encoding UTF8

Sec 'VERDICT'
if($found){ Bad ("FOUND: {0}" -f @($found).Count); $found|ForEach-Object{ Write-Host ("   [{0}] {1}" -f $_.Area,$_.Detail) -ForegroundColor Red } }
if($poss){ Hit ("POSSIBLE: {0}" -f @($poss).Count); $poss|ForEach-Object{ Write-Host ("   [{0}] {1}" -f $_.Area,$_.Detail) -ForegroundColor Yellow } }
if(-not ($found -or $poss)){ Ok "CLEAN - no remote-access indicators in this window." }
Write-Host ""
Write-Host ("Readable report : {0}\REPORT.txt" -f $Case) -ForegroundColor White
Write-Host ("Findings (json) : {0}\findings.json" -f $Case) -ForegroundColor White
Write-Host ("Serialized data : {0}\raw\*.csv" -f $Case) -ForegroundColor White
