# Captures : shots.ps1 <dossier sous agents/desert> "nom=x,y,z:cx,cy,cz" ...  (arrêt forcé au bout de 200 s)
param([string]$Out, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$S = "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad"
$G = "$S/godot/Godot_v4.7.2-stable_win64_console.exe"
$F = "D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend"
$a = @("--path", $F, "--resolution", "1280x720", "--script", "$S/agents/desert/cam_shots_desert.gd", "--", "res://scenes/levels/desert/desert.tscn", "agents/desert/$Out", "--api=http://127.0.0.1:9/api/v1") + $Rest
$p = Start-Process -FilePath $G -ArgumentList $a -WorkingDirectory $F -NoNewWindow -PassThru -RedirectStandardOutput "$S/agents/desert/shots.log" -RedirectStandardError "$S/agents/desert/shots.err"
if (-not $p.WaitForExit(200000)) { $p.Kill(); "TIMEOUT" }
"exit $($p.ExitCode)"
Select-String -Path "$S/agents/desert/shots.log", "$S/agents/desert/shots.err" -Pattern "SCRIPT ERROR|Parse Error" | Select-Object -First 10 | ForEach-Object { $_.Line }
