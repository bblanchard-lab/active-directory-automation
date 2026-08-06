# 1. Définition du chemin automatique vers le fichier CSV
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$cheminFichier = "$PSScriptRoot\utilisateurs.csv"

# 2. Importation des données des utilisateurs
$listeUtilisateurs = Import-Csv -Path $cheminFichier -Encoding utf8

# Définition de la racine de ton domaine AD (bblanchard.lab)
$DN_Racine = "DC=bblanchard,DC=lab"

# 3. Boucle de traitement et validation de la lecture des données
foreach ($user in $listeUtilisateurs) {
    
    # Étape A : Définir le nom et le chemin de l'OU du département (TI, RH, Ventes)
    $nomOU = $user.Departement
    $cheminOU = "OU=$nomOU,$DN_Racine"
    
    # Étape B : Vérifier si l'OU existe déjà, sinon la créer
    try {
        Get-ADOrganizationalUnit -Identity $cheminOU -ErrorAction Stop
    } 
    catch {
        Write-Host "Création de l'OU : $nomOU" -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name $nomOU -Path $DN_Racine
    }

    # Étape C : Créer l'utilisateur dans la bonne OU
    try {
        # On vérifie si le compte existe déjà pour éviter les erreurs de doublons
        Get-ADUser -Identity $user.Username -ErrorAction Stop
        Write-Host "L'utilisateur $($user.Username) existe déjà." -ForegroundColor Cyan
    }
    catch {
        # Si le compte n'existe pas, on le génère avec les infos du CSV
        New-ADUser -Name "$($user.Prenom) $($user.Nom)" `
                   -GivenName $user.Prenom `
                   -Surname $user.Nom `
                   -SamAccountName $user.Username `
                   -UserPrincipalName "$($user.Username)@bblanchard.lab" `
                   -Path $cheminOU `
                   -Enabled $true
                   
        Write-Host "Utilisateur créé : $($user.Username) (Departement: $nomOU)" -ForegroundColor Green
    }
}
