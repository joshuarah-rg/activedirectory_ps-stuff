<#
    .SYNOPSIS
    Import-ADUsers.ps1

    .DESCRIPTION
    Import Active Directory users from CSV file.

    .LINK
    alitajran.com/import-ad-users-from-csv-powershell

    .NOTES
    Written by: ALI TAJRAN
    Website:    alitajran.com
    LinkedIn:   linkedin.com/in/alitajran

    .CHANGELOG
    V2.00, 02/11/2024 - Refactored script
#>


# Define the CSV file location and import the data
$Csvfile = "C:\_ADSync\export.csv"
$Users = Import-Csv $Csvfile -Delimiter ';'
$CredentialsOutput = "C:\_ADSync\Credentials.txt"

# Import the Active Directory module
Import-Module ActiveDirectory

# Loop through each user
foreach ($User in $Users) {
    
    $randomPassword = -join ((65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_})
    
    try {
        # Retrieve the Manager distinguished name
        $managerDN = if ($User.'Manager') {
            Get-ADUser -Filter "DisplayName -eq '$($User.'Manager')'" -Properties DisplayName |
            Select-Object -ExpandProperty DistinguishedName
        }

        # Define the parameters using a hashtable
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

        # Add the info attribute to OtherAttributes only if Notes field contains a value
        if (![string]::IsNullOrEmpty($User.Notes)) {
            $NewUserParams.OtherAttributes = @{info = $User.Notes }
        }

        # Check to see if the user already exists in AD
        if (Get-ADUser -Filter "SamAccountName -eq '$($User.'User logon name')'") {

            # Give a warning if user exists
            Write-Host "A user with username $($User.'User logon name') already exists in Active Directory." -ForegroundColor Yellow
        }
        else {
            # User does not exist then proceed to create the new user account
            # Account will be created in the OU provided by the $User.OU variable read from the CSV file
            New-ADUser @NewUserParams
            Write-Host "The user $($User.'User logon name') is created successfully." -ForegroundColor Green
        }
    }
    catch {
        # Handle any errors that occur during account creation
        Write-Host "Failed to create user $($User.'User logon name') - $($_.Exception.Message)" -ForegroundColor Red
    }
}