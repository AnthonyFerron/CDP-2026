# Planches de captures : sheets.ps1 <dossier> <points...> (arrêt forcé au bout de 220 s)
param([string]$Out, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$S = "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad"
$G = "$S/godot/Godot_v4.7.2-stable_win64_console.exe"
$F = "D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend"
$a = @("--path", $F, "--resolution", "1280x720", "--script", "$S/agents/desert/sheet_shots.gd", "--", $Out, "--api=http://127.0.0.1:9/api/v1") + $Rest
$p = Start-Process -FilePath $G -ArgumentList $a -WorkingDirectory $F -NoNewWindow -PassThru -RedirectStandardOutput "$S/agents/desert/sheets.log" -RedirectStandardError "$S/agents/desert/sheets.err"
if (-not $p.WaitForExit(220000)) { $p.Kill(); "TIMEOUT" }
Select-String -Path "$S/agents/desert/sheets.err" -Pattern "SCRIPT ERROR" | Select-Object -First 5 | ForEach-Object { $_.Line }
(Get-ChildItem "$S/agents/desert/$Out" -Filter *.png).Name
