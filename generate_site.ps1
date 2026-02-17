# Configuration
$contentDirs = @{
    "Canada"   = "Canada";
    "U.S"      = "USA";
    "Europe"   = "Europe";
    "Culture"  = "Culture";
    "Asia"     = "World";
    "NewsBias" = "News Bias"
}

# Ensure order matches user preference
$dirOrder = @("Canada", "U.S", "Europe", "Culture", "Asia", "NewsBias")

$validExts = @(".jpg", ".jpeg", ".png", ".webp", ".gif")

# NOTE: CSS and JS braces {{ }} must be escaped for PowerShell -f operator
$htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{0} - Twitter Archive</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

<nav>
    <a href="index.html">
        <img src="logo.png" alt="Logo" class="nav-logo">
    </a>
    <a href="index.html" class="{2}">Home</a>
    {1}
</nav>

<main>
    <h1>{3}</h1>
    {4}
</main>

<div id="lightbox" class="lightbox" onclick="this.style.display='none'">
    <span class="close">&times;</span>
    <img class="lightbox-content" id="lightbox-img">
</div>

<script>
    function openLightbox(src) {{
        document.getElementById('lightbox').style.display = 'flex';
        document.getElementById('lightbox-img').src = src;
    }}
</script>

</body>
</html>
"@

function Get-DateFromFilename($filename) {
    # Format: Screenshot_20260101-014038.jpg
    try {
        if ($filename -match "Screenshot_(\d{8}-\d{6})") {
            return [datetime]::ParseExact($matches[1], "yyyyMMdd-HHmmss", $null)
        }
    }
    catch {
        # Ignore errors
    }
    return [datetime]::MinValue
}

function Generate-NavLinks($currentPage) {
    $links = @()
    foreach ($d in $dirOrder) {
        if (Test-Path $d) {
            $displayName = $contentDirs[$d]
            $activeClass = if ($currentPage -eq $d) { "active" } else { "" }
            $links += "<a href=`"$d.html`" class=`"$activeClass`">$displayName</a>"
        }
    }
    return $links -join "`n    "
}

function Generate-Page($folderName) {
    $displayName = $contentDirs[$folderName]
    $images = @()

    $files = Get-ChildItem -Path $folderName | Where-Object { $validExts -contains $_.Extension.ToLower() }
    
    foreach ($file in $files) {
        $date = Get-DateFromFilename $file.Name
        if ($date -eq [datetime]::MinValue) {
            $date = $file.LastWriteTime
        }
        
        $images += [PSCustomObject]@{
            Filename = $file.Name
            Path     = "$folderName/" + $file.Name
            Date     = $date
            Category = $displayName
        }
    }

    # Sort descending
    $images = $images | Sort-Object Date -Descending

    $cardsHtml = '<div class="grid">'
    foreach ($img in $images) {
        $dateStr = $img.Date.ToString("MMMM dd, yyyy")
        $cardsHtml += @"
        <div class="card">
            <div class="card-content">
                <div class="card-date">$dateStr</div>
            </div>
            <img src="$($img.Path)" class="card-image" onclick="openLightbox('$($img.Path)')" alt="$($img.Filename)">
        </div>
"@
    }
    $cardsHtml += '</div>'

    if ($images.Count -eq 0) { $cardsHtml = "<p>No images found.</p>" }
    
    $navLinks = Generate-NavLinks $folderName
    # {0}=Title, {1}=NavLinks, {2}=ActiveHome, {3}=PageTitle, {4}=Content (Cards)
    $pageContent = $htmlTemplate -f $displayName, $navLinks, "", $displayName, $cardsHtml
    
    $outputPath = "$folderName.html"
    Set-Content -Path $outputPath -Value $pageContent -Encoding UTF8
    Write-Host "Generated $outputPath"
    
    return $images
}

# Main Execution
Write-Host "Starting site generation..."

$allImages = @()

foreach ($folder in $dirOrder) {
    if (Test-Path $folder) {
        $imgs = Generate-Page $folder
        $allImages += $imgs
    }
    else {
        Write-Host "Warning: Folder '$folder' not found."
    }
}

# Generate Home
# Home is now just the static image
$homeContentHtml = '<img src="ScottAdams.jpg" alt="Welcome" class="hero-image">'

$navLinks = Generate-NavLinks "Home"
# {0}=Title, {1}=NavLinks, {2}=ActiveHome, {3}=PageTitle, {4}=Content (Static Image)
$homeContent = $htmlTemplate -f "Home", $navLinks, "active", "", $homeContentHtml

Set-Content -Path "index.html" -Value $homeContent -Encoding UTF8
Write-Host "Generated index.html"
Write-Host "Done!"
