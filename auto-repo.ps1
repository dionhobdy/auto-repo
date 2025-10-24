# set title "Auto Repo" art as variable and then display it
$title = @"
 _______  __   __  _______  _______    ______    _______  _______  _______ 
|   _   ||  | |  ||       ||       |  |    _ |  |       ||       ||       |
|  |_|  ||  | |  ||_     _||   _   |  |   | ||  |    ___||    _  ||   _   |
|       ||  |_|  |  |   |  |  | |  |  |   |_||_ |   |___ |   |_| ||  | |  |
|       ||       |  |   |  |  |_|  |  |    __  ||    ___||    ___||  |_|  |
|   _   ||       |  |   |  |       |  |   |  | ||   |___ |   |    |       |
|__| |__||_______|  |___|  |_______|  |___|  |_||_______||___|    |_______|
By Dion Hobdy [https://github.com/dionhobdy/auto-repo]
"@
Write-Host $title

# add a .gitignore file if it doesn't exist
$gitignorePath = ".gitignore"
if (-not (Test-Path -Path $gitignorePath)) {
    Write-Host ".gitignore file not found. Creating one."
    New-Item -Path $gitignorePath -ItemType File -Force | Out-Null
} else {
    Write-Host ".gitignore file already exists."
}
# add this script to the .gitignore file if it's not already there
$scriptName = "auto-repo.ps1"
if (-not (Get-Content -Path $gitignorePath | Select-String -Pattern [regex]::Escape($scriptName))) {
    Add-Content -Path $gitignorePath -Value $scriptName
    Write-Host "Added '$scriptName' to .gitignore."
    # comment on the .gitignore file
    Add-Content -Path $gitignorePath -Value "# auto-repo.ps1 is an repo automation script written by Dion Hobdy [https://github.com/dionhobdy/auto-repo]" -Force
} else {
    Write-Host "'$scriptName' is already in .gitignore."
}

# create variables requesting username and repo name.
$username = Read-Host -Prompt "Enter your GitHub username"
$repoName = Read-Host -Prompt "Enter the name of the repository (no special characters. spaces permitted)"
$commitDescription = Read-Host -Prompt "Enter a commit description"
$branch = Read-Host -Prompt "Enter the branch to push to (default is 'main')"
if ([string]::IsNullOrWhiteSpace($branch)) {
    $branch = "main"
}
# check if the branch exists locally, if not, create it
$localBranches = git branch --list $branch

if (-not $localBranches) {
    Write-Host "Branch '$branch' does not exist locally. Creating it."
    git checkout -b $branch
    # set $branch to this newly created branch
    $branch = git rev-parse --abbrev-ref HEAD
}

# check if the repoName contains spaces or special characters and then make necessary adjustments or exit script
if ($repoName -match '\s') {
    Write-Host "Repository name contains special spaces. Changing spaces to hyphens."
    $repoName = $repoName -replace '\s', '-'
    Write-Host "New repository name: $repoName"
}
if ($repoName -match '[^a-zA-Z0-9\-_]') {
    Write-Host "Repository name contains special characters other than hyphens or underscores. Exiting script."
    Write-Host "Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ensure the current directory is marked as a safe directory for git operations
$currentDir = (Get-Location).Path
git config --global --add safe.directory $currentDir

# establish the GitHub API URL for checking repository existence
$apiUrl = "https://api.github.com/repos/$username/$repoName"

# check if the repository exists on GitHub
try {
    Invoke-WebRequest -Uri $apiUrl -ErrorAction Stop
    Write-Host "Repo exists!" 
} catch {
    Write-Host "Repo does not exist or is private! Exiting script."
    Write-Host "1. Create the repository on GitHub before running this script."
    Write-Host "2. Run 'git init' in this directory if you haven't already."
    Write-Host "Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# add all files to the staging area
git add .

# display changes before committing
git status

# ask user if they are sure if they want to commit changes
$confirmation = Read-Host -Prompt "Are you sure you want to commit these changes? (y/n)"

if ($confirmation -eq "y") {
    # commit the changes with the provided description
    git commit -m "$commitDescription"
    # use the inputted branch
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -ne $branch) {
        Write-Host "Switching from branch '$currentBranch' to '$branch'."
        git checkout $branch
        git branch -M $branch
    }
    # set the remote origin using the provided username and repository name
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$username/$repoName.git"
    # push the items to the remote repository
    git push -u origin $branch
    # notify user of successful push
    Write-Host "Changes have been successfully pushed to the repository '$repoName' under the user '$username'."
    # display the new changes after pushing
    git status
    Write-Host "Operation completed successfully. Exiting script."
    Write-Host "Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    # notify user that the operation was cancelled
    Write-Host "Operation cancelled. No changes were committed or pushed. Exiting script."
    Write-Host "Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}