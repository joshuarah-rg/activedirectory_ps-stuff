# Globale Variablen
$Path = "C:\Pfad"

# Importieren der Benutzerliste aus der CSV-Datei
$BenutzerListe = Import-Csv -Path $Path

# Durchlaufen der Benutzerliste und Ausführen der Befehle
foreach ($Benutzer in $BenutzerListe) {
    # Ermitteln der Mailbox-Datenbank des alten Benutzers
    $MailboxDatenbank = (Get-Mailbox -Identity $Benutzer.AlterBenutzer).Database
    
    # E-Mail-Aliasse vom alten Konto abrufen
    $alteMailbox = Get-Mailbox -Identity $Benutzer.AlterBenutzer
    $aliase = $alteMailbox.EmailAddresses

    # Deaktivieren des alten Benutzerpostfachs
    Disable-Mailbox -Identity $Benutzer.AlterBenutzer -Confirm:$false

    # Warten, bis das Postfach vollständig deaktiviert ist
    Start-Sleep -Seconds 5

    # Verbinden des Postfachs mit einem neuen Benutzerkonto
    Connect-Mailbox -Identity $Benutzer.AlterBenutzer -Database $MailboxDatenbank -User $Benutzer.NeuerBenutzer 

    # E-Mail-Aliasse zum neuen Konto hinzufügen
    Set-Mailbox -Identity $Benutzer.NeuerBenutzer -EmailAddresses $aliase


}

# Aufbau der CSV-Datei:
# Spalte 1: AlterUser
# Spalte 2: NeuerUser