# Lance Godot sur la worktree de la Plaine avec une limite de temps : run_godot.ps1 <journal> <secondes> <arguments...>
param([string]$Log, [int]$Seconds, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$S = "C:\Users\lebos\AppData\Local\Temp\claude\D--Anthony-Documents-GitHub-CDP-2026\859f48d8-d83e-4666-9a42-4295b9c6e433\scratchpad"
$F = "D:\Anthony\Documents\GitHub\CDP-2026\.claude\worktrees\agent-ac34b1fd3f91b5f89\frontend"
# Depuis la PR #12, le jeu parle au serveur : chaque lancement vise une adresse locale morte, jamais la production.
if ($Rest -notcontains "++") { $Rest += "++" }
if (-not ($Rest -match "^--api=")) { $Rest += "--api=http://127.0.0.1:9/api/v1" }
$arguments = @("--path", $F) + $Rest
$process = Start-Process -FilePath "$S\godot\Godot_v4.7.2-stable_win64_console.exe" -ArgumentList $arguments -RedirectStandardOutput $Log -RedirectStandardError "$Log.err" -NoNewWindow -PassThru
if (-not $process.WaitForExit($Seconds * 1000)) {
	Stop-Process -Id $process.Id -Force
	"DÉLAI DÉPASSÉ ($Seconds s)" | Out-File -Append -Encoding utf8 $Log
}
