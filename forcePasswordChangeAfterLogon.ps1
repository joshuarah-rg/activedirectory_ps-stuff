# Aktiviert ALLE Benutzerkonten einer OU
# Verpflichtet die Nutzer jener OU dazu ihr Passwort zu ändern.

$organizationalUnit = "Distinguished Name" # Hier den Distinguished Name der OU angeben

Get-ADUser -Filter * -SearchBase $organizationalUnit | Set-ADUser -Enabled $true -ChangePasswordAtLogon $true