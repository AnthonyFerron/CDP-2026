# Lance un test Godot dans la worktree : t.ps1 <script.gd> <log> [-Window] [-Limit secondes] [args utilisateur...]
param([string]$Script, [string]$Log = "test", [switch]$Window, [int]$Limit = 240, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$S = "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad"
$G = "$S/godot/Godot_v4.7.2-stable_win64_console.exe"
$F = "D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend"
$out = "$S/agents/desert/$Log.log"
$args2 = @()
if (-not $Window) { $args2 += "--headless" } else { $args2 += @("--resolution", "1280x720") }
$args2 += @("--path", $F, "--fixed-fps", "60", "--script", $Script)
$args2 += "--"; if ($Rest) { $args2 += $Rest }; if (-not ($Rest -contains "--api=http://127.0.0.1:9/api/v1")) { $args2 += "--api=http://127.0.0.1:9/api/v1" }
$p = Start-Process -FilePath $G -ArgumentList $args2 -WorkingDirectory $F -NoNewWindow -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
if (-not $p.WaitForExit($Limit * 1000)) { $p.Kill(); "TIMEOUT apres $Limit s" }
"exit $($p.ExitCode)"
Select-String -Path $out, "$out.err" -Pattern "ECHEC|RESULTAT|SCRIPT ERROR|Parse Error" | Select-Object -First 80 | ForEach-Object { $_.Line }
