# Importieren der Benutzernamen aus der CSV-Datei
$users = Import-Csv -Path "Pfad_zur_CSV_Datei.csv"

# Durchlaufen jedes Benutzers in der CSV-Datei und Deaktivieren des Kontos
foreach ($user in $users) {
    # Deaktivieren des AD-Kontos
    Disable-ADAccount -Identity $user.SamAccountName
}