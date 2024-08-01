# Pfade zu wichtigen Dateien
$Csvfile = "C:\_ADSync\export.csv"
$Users = Import-Csv $Csvfile -Delimiter ';'
$CredentialsOutput = "C:\_ADSync\Credentials.txt"

# Importieren des Active Directory Moduls
Import-Module ActiveDirectory

# Loop through each user
foreach ($User in $Users) {
    
    $randomPassword = -join ((65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_})
    
    try {
        # Definieren des Managers
        $managerDN = if ($User.'Manager') {
            Get-ADUser -Filter "DisplayName -eq '$($User.'Manager')'" -Properties DisplayName |
            Select-Object -ExpandProperty DistinguishedName
        }

        # Parameter über eine Hashtabelle definieren
        $NewUserParams = @{
            Name                  = "$($User.'Last name'), $($User.'First name')"
            GivenName             = $User.'First name'
            Surname               = $User.'Last name'
            DisplayName           = $User.'Display name'
            SamAccountName        = $User.'User logon name'
            UserPrincipalName     = $User.'User principal name'
            StreetAddress         = $User.'Street'
            City                  = $User.'City'
            State                 = $User.'State/province'
            PostalCode            = $User.'Zip/Postal Code'
            Country               = $User.'Country/region'
            Title                 = $User.'Job Title'
            Department            = $User.'Department'
            Company               = $User.'Company'
            Manager               = $managerDN
            Path                  = $User.'OU'
            Description           = $User.'Description'
            Office                = $User.'Company'
            OfficePhone           = $User.'Telephone number'
            EmailAddress          = $User.'E-mail'
            MobilePhone           = $User.'Mobile'
            AccountPassword       = (ConvertTo-SecureString "$randomPassword" -AsPlainText -Force)
            Enabled               = if ($User.'Account status' -eq "Enabled") { $true } else { $false }
            ChangePasswordAtLogon = $true # Set the "User must change password at next logon"
        }

        # Speichern des Passwortes je User
        $PasswordOut = "`nUser: $($User.'User principal name') | Passwort: $randomPassword"
        $PasswordOut | Out-File -FilePath $CredentialsOutput -Append

        # Hinzufügen des Attributes <mailNickname> zur BenutzerEntität über die Variable <alias>
        $NewUserParams.OtherAttributes = @{mailNickname = $User.alias }

        # Hinzufügen des Attributes <employeeNumber> zur BenutzerEntität über die Variable <personalnummer>
        $NewUserParams.OtherAttributes = @{employeeNumber = $User.personalnummer}

        # Info Attribut setzen, sofern es nicht leer ist
        if (![string]::IsNullOrEmpty($User.Notes)) {
            $NewUserParams.OtherAttributes = @{info = $User.Notes }
        }

        # Überprüfen, ob der Benutzer bereits existiert
        if (Get-ADUser -Filter "SamAccountName -eq '$($User.'User logon name')'") {

            # Warnung, wenn der Benutzer bereits existiert
            Write-Host "A user with username $($User.'User logon name') already exists in Active Directory." -ForegroundColor Yellow
        }
        else {
            # Wenn kein gleichlautender Benutzer existiert mit Erstellung fortfahren
            New-ADUser @NewUserParams
            Write-Host "The user $($User.'User logon name') is created successfully." -ForegroundColor Green
        }
    }
    catch {
        # Error-Resilienz
        Write-Host "Failed to create user $($User.'User logon name') - $($_.Exception.Message)" -ForegroundColor Red
    }
}