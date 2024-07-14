$Postfächer = Get-Mailbox -ResultSize Unlimited
foreach ($Postfach in $Postfächer) {
    $Richtlinie = Get-RetentionPolicy | Where-Object {$_.Mailbox -eq $Postfach.Name}
    if (-not $Richtlinie) {
        Set-Mailbox -Identity $Postfach.Name -RetentionPolicy "Default Archive and Retention Policy"
    }
}