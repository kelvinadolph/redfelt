# Update Website Script

Write-Host "Generating website pages..."
& .\generate_site.ps1

Write-Host "Staging changes to Git..."
git add .

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMessage = "Update site content $timestamp"

Write-Host "Committing changes..."
git commit -m "$commitMessage"

Write-Host "Pushing to GitHub..."
git push

Write-Host "Done! Website updated."
Pause
