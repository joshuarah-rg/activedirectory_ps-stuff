# Globale Variablen
$Path = "In File.csv"
$OutPath = "Out File.txt"

# Laden des Exchange-SnapIn's
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

# Importieren der Benutzerliste aus der CSV-Datei
$BenutzerListe = Import-Csv -Path $Path -Delimiter ';'

# Durchlaufen der Benutzerliste
foreach ($Benutzer in $BenutzerListe) {

    Write-Host "`n`nVerarbeite Benutzer: $($Benutzer.AlterBenutzer)" # Aktuellen Benutzer anzeigen

    # Ermitteln der Mailbox-GUID
    try {
    $Mailbox = Get-Mailbox -Identity $Benutzer.AlterBenutzer -ErrorAction Stop
    $Mailbox_UID = $Mailbox.ExchangeGUID
    Write-Host "Mailbox GUID: $Mailbox_UID"
    }
    
    catch {
    $ErrorMessage = "`n>>> Fehler bei Erfassung der GUID für das Postfach: $($Benutzer.AlterBenutzer)"
    Write-Host $ErrorMessage
    $ErrorMessage | Out-File -FilePath $OutPath -Append
    }


    # Ermitteln der Postfach-Datenbank
    try {
    $MailboxID = Get-Mailbox -Identity $($Benutzer.AlterBenutzer)
    $MailboxDatenbank = $MailboxID.Database
    Write-Host "Mailbox-Datenbank gefunden: $MailboxDatenbank"
    }

    catch {
    $DatabaseError = "`n>>> Fehler bei Feststellung der Datenbank für das Postfach: $($Benutzer.AlterBenutzer)"
    Write-Host $DatabaseError
    $DatabaseError | Out-File -FilePath $OutPath -Append
    }


    # Deaktivieren des alten Benutzerpostfachs
    try {
    Disable-Mailbox -Identity $Benutzer.AlterBenutzer -Confirm:$false -ErrorAction Stop
    Write-Host "Altes Postfach deaktiviert"
    }

    catch {
    $DeactivationError = "`n>>> Fehler bei Deaktivierung des Postfaches: $($Benutzer.AlterBenutzer)"
    Write-Host $DeactivationError
    $DeactivationError | Out-File -FilePath $OutPath -Append
    }
    
    # Umformen der GUID
    $MailboxIdentity = [Microsoft.Exchange.Configuration.Tasks.MailboxIdParameter]::Parse($Mailbox_UID)

           
    # Abwarten bis Postfach vollständig getrennt 
    while ((Get-Mailbox -Identity $MailboxIdentity).MailboxStatus -ne 'Disabled')
    {
    Update-StoreMailboxState -Database $MailboxDatenbank -Identity $Mailbox_UID -Confirm:$false
    Start-Sleep -Seconds 5
    }


    # Verbinden des Postfachs mit einem neuen Benutzerkonto
    try {
    Connect-Mailbox -Identity $MailboxGUID -Database $MailboxDatenbank -User $Benutzer.NeuerBenutzer 
    Write-Host "Postfach mit neuem Benutzerkonto verbunden"
    }

    catch {
    $ConnectError = "`n>>> Fehler bei Verbinden des Postfaches $($Benutzer.AlterBenutzer) mit neuem Benutzer $($Benutzer.NeuerBenutzer)"
    Write-Host $ConnectError
    $ConnectError | Out-File -FilePath $OutPath -Append
    }
}

# Aufbau der CSV-Datei:
# Spalte 1: AlterUser@domain.com
# Spalte 2: NeuerUser@domain.com