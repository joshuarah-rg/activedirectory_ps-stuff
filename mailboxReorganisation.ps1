# Globale Variablen
$Path = "Pfad zur CSV"

# Importieren der Benutzerliste aus der CSV-Datei
$BenutzerListe = Import-Csv -Path $Path -Delimiter ';'

# Durchlaufen der Benutzerliste und Ausfuehren der Befehle
foreach ($Benutzer in $BenutzerListe) {

    Write-Host "Verarbeite Benutzer: $($Benutzer.AlterBenutzer)" # Aktuellen Benutzer anzeigen

    # Ermitteln der Mailbox-Datenbank des alten Benutzers
    $MailboxDatenbank = (Get-Mailbox -Identity $Benutzer.AlterBenutzer).Database
    Write-Host "Mailbox-Datenbank gefunden: $MailboxDatenbank"

    # Deaktivieren des alten Benutzerpostfachs
    Disable-Mailbox -Identity $Benutzer.AlterBenutzer -Confirm:$false
    Write-Host "Altes Postfach deaktiviert"


    # Warten, bis das Postfach vollstaendig deaktiviert ist
    Start-Sleep -Seconds 5

    # Verbinden des Postfachs mit einem neuen Benutzerkonto
    Connect-Mailbox -Identity $Benutzer.AlterBenutzer -Database $MailboxDatenbank -User $Benutzer.NeuerBenutzer 
    Write-Host "Postfach mit neuem Benutzerkonto verbunden"


}

# Aufbau der CSV-Datei:
# Spalte 1: AlterUser@domain.com
# Spalte 2: NeuerUser@domain.com