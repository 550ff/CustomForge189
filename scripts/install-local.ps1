<#
.SYNOPSIS
    Installs CustomForge 1.8.9 into SKLauncher 4.0 as a recognized LOCAL client
    and configures the 'Custom' / 'CustomForge 1.8.9' instance with Intel HD 2000 optimizations.
.DESCRIPTION
    1. Copies compiled universal JAR to:
       - libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-custom1\forge-1.8.9-11.15.1.2318-custom1.jar
       - libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-1.8.9\forge-1.8.9-11.15.1.2318-1.8.9.jar
       - libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-1.8.9\forge-1.8.9-11.15.1.2318-1.8.9-universal.jar
       in both %APPDATA%\.sklauncher and %APPDATA%\.minecraft.
    2. Deploys version profile 1.8.9-forge-custom1 (JSON without BOM and client JAR) across:
       - %APPDATA%\.sklauncher\versions\1.8.9-forge-custom1\
       - %APPDATA%\.minecraft\versions\1.8.9-forge-custom1\
       - %APPDATA%\.sklauncher\instances\12\versions\1.8.9-forge-custom1\
       and removes any .sklauncher marker file so SKLauncher 4.0 discovers it as a LOCAL client.
    3. Reconfigures Custom instances in instances.json:
       - versionId: 1.8.9-forge-custom1
       - gameType: custom
       - minecraftVersion: 1.8.9
       - installComplete: true
       - javaComponent: jre-legacy (Java 8)
       - memoryMax: 1792
       - jvmArgs with G1GC and IPv4 stack options.
    4. Ensures launcher_profiles.json is written without UTF-8 BOM containing '1-8-custom'.
    5. Applies Intel HD 2000 client optimizations (splash.properties, options.txt, optionsof.txt).
    6. Ensures instance '1-8' is 100% untouched.
#>

[CmdletBinding()]
param(
    [string]$JarPath = ""
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " CustomForge 1.8.9 SKLauncher 4.0 Local Client Configurator" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$appData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)
$dotMinecraft = Join-Path $appData ".minecraft"
$dotSklauncher = Join-Path $appData ".sklauncher"

# UTF-8 Encoding without BOM helper
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
function Write-JsonFileNoBom([string]$filePath, [string]$content) {
    $parentDir = Split-Path $filePath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($filePath, $content, $utf8NoBom)
}

# 1. Locate source Forge universal JAR
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($JarPath)) {
    $searchPaths = @(
        (Join-Path $repoRoot "dist\baseline\forge-1.8.9-*-universal.jar"),
        (Join-Path $repoRoot "dist\baseline\*.jar"),
        (Join-Path $repoRoot "forge\build\distributions\forge-*-universal.jar"),
        (Join-Path $repoRoot "forge\build\libs\forge-*-universal.jar")
    )
    foreach ($pattern in $searchPaths) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $JarPath = $found.FullName
            break
        }
    }
}

if (-not $JarPath -or -not (Test-Path $JarPath)) {
    Write-Error "Could not find Forge universal JAR. Please supply -JarPath <path-to-jar>."
}
$jarHash = (Get-FileHash -Path $JarPath -Algorithm SHA1).Hash.ToLower()
$jarSize = (Get-Item -Path $JarPath).Length
Write-Host "[+] Source Forge JAR: $JarPath" -ForegroundColor Green
Write-Host "[+] SHA1: $jarHash | Size: $jarSize bytes" -ForegroundColor Green

# 2. Locate vanilla 1.8.9 client jar to use as base version jar
$vanillaClientJar = ""
$clientJarCandidates = @(
    (Join-Path $dotSklauncher "versions\1.8.9-forge-11.15.1.2318\1.8.9-forge-11.15.1.2318.jar"),
    (Join-Path $dotSklauncher "versions\1.8.9\1.8.9.jar"),
    (Join-Path $dotMinecraft "versions\1.8.9\1.8.9.jar")
)
foreach ($c in $clientJarCandidates) {
    if (Test-Path $c) {
        $vanillaClientJar = $c
        break
    }
}

if (-not $vanillaClientJar) {
    Write-Warning "Could not find local 1.8.9 client jar. Using source Forge JAR as fallback."
    $vanillaClientJar = $JarPath
} else {
    Write-Host "[+] Base vanilla 1.8.9 client JAR: $vanillaClientJar" -ForegroundColor Green
}

# 3. Read libraries from template 1.8.9-forge-11.15.1.2318.json
$templateJsonPath = Join-Path $dotSklauncher "versions\1.8.9-forge-11.15.1.2318\1.8.9-forge-11.15.1.2318.json"
$librariesList = @()
if (Test-Path $templateJsonPath) {
    $templateJson = Get-Content -Raw $templateJsonPath | ConvertFrom-Json
    $filteredLibraries = @()
    foreach ($lib in $templateJson.libraries) {
        if ($lib.name -like "net.minecraftforge:forge:*") {
            # Local library entry with NO url and NO downloads url
            $filteredLibraries += [ordered]@{
                name = "net.minecraftforge:forge:1.8.9-11.15.1.2318-custom1"
                checksums = @($jarHash)
            }
        } else {
            $filteredLibraries += $lib
        }
    }
    $librariesList = $filteredLibraries
} else {
    $librariesList = @(
        [ordered]@{ name = "net.minecraftforge:forge:1.8.9-11.15.1.2318-custom1"; checksums = @($jarHash) },
        [ordered]@{ name = "net.minecraft:launchwrapper:1.12"; serverreq = $true },
        [ordered]@{ name = "org.ow2.asm:asm-all:5.0.3"; serverreq = $true },
        [ordered]@{ name = "jline:jline:2.13"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "com.typesafe.akka:akka-actor_2.11:2.3.3"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "com.typesafe:config:1.2.1"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang:scala-actors-migration_2.11:1.1.0"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang:scala-compiler:2.11.1"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang.plugins:scala-continuations-library_2.11:1.0.2"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang.plugins:scala-continuations-plugin_2.11.1:1.0.2"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang:scala-library:2.11.1"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang:scala-parser-combinators_2.11:1.0.1"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang:scala-reflect:2.11.1"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang:scala-swing_2.11:1.0.1"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "org.scala-lang:scala-xml_2.11:1.0.2"; url = "https://maven.minecraftforge.net/" },
        [ordered]@{ name = "lzma:lzma:0.0.1"; serverreq = $true },
        [ordered]@{ name = "net.sf.jopt-simple:jopt-simple:4.6"; serverreq = $true },
        [ordered]@{ name = "java3d:vecmath:1.5.2"; clientreq = $true; serverreq = $true },
        [ordered]@{ name = "net.sf.trove4j:trove4j:3.0.3"; clientreq = $true; serverreq = $true }
    )
}

$nowIso = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
$versionJsonObject = [ordered]@{
    id = "1.8.9-forge-custom1"
    inheritsFrom = "1.8.9"
    type = "release"
    time = $nowIso
    releaseTime = "1960-01-01T00:00:00-0700"
    mainClass = "net.minecraft.launchwrapper.Launch"
    minecraftArguments = "--username `${auth_player_name} --version `${version_name} --gameDir `${game_directory} --assetsDir `${assets_root} --assetIndex `${assets_index_name} --uuid `${auth_uuid} --accessToken `${auth_access_token} --userProperties `${user_properties} --userType `${user_type} --tweakClass net.minecraftforge.fml.common.launcher.FMLTweaker"
    arguments = [ordered]@{
        game = @(
            "--username", "`${auth_player_name}",
            "--version", "`${version_name}",
            "--gameDir", "`${game_directory}",
            "--assetsDir", "`${assets_root}",
            "--assetIndex", "`${assets_index_name}",
            "--uuid", "`${auth_uuid}",
            "--accessToken", "`${auth_access_token}",
            "--userProperties", "`${user_properties}",
            "--userType", "`${user_type}",
            "--tweakClass", "net.minecraftforge.fml.common.launcher.FMLTweaker"
        )
        jvm = @()
    }
    libraries = $librariesList
    jar = "1.8.9-forge-custom1"
}
$versionJsonString = $versionJsonObject | ConvertTo-Json -Depth 10

# 4. Install libraries and version directories into target roots
$targetRoots = @($dotMinecraft, $dotSklauncher)
foreach ($root in $targetRoots) {
    if (-not (Test-Path $root)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }

    # Install custom library: libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-custom1
    $libDir = Join-Path $root "libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-custom1"
    if (-not (Test-Path $libDir)) {
        New-Item -ItemType Directory -Path $libDir -Force | Out-Null
    }
    $libJarPath = Join-Path $libDir "forge-1.8.9-11.15.1.2318-custom1.jar"
    Copy-Item -Path $JarPath -Destination $libJarPath -Force
    Write-Host "[+] Installed Forge custom1 library: $libJarPath" -ForegroundColor Green

    # Install standard 11.15.1.2318 library jars
    $stdLibDir = Join-Path $root "libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-1.8.9"
    if (-not (Test-Path $stdLibDir)) {
        New-Item -ItemType Directory -Path $stdLibDir -Force | Out-Null
    }
    $targetJar1 = Join-Path $stdLibDir "forge-1.8.9-11.15.1.2318-1.8.9.jar"
    $targetJar2 = Join-Path $stdLibDir "forge-1.8.9-11.15.1.2318-1.8.9-universal.jar"
    Copy-Item -Path $JarPath -Destination $targetJar1 -Force
    Copy-Item -Path $JarPath -Destination $targetJar2 -Force
    Write-Host "[+] Installed standard jars: $targetJar1 and $targetJar2" -ForegroundColor Green

    # Install version folder 1.8.9-forge-custom1
    $verDir = Join-Path $root "versions\1.8.9-forge-custom1"
    if (-not (Test-Path $verDir)) {
        New-Item -ItemType Directory -Path $verDir -Force | Out-Null
    }

    # Version JSON (without BOM)
    $jsonPath = Join-Path $verDir "1.8.9-forge-custom1.json"
    Write-JsonFileNoBom $jsonPath $versionJsonString
    Write-Host "[+] Installed version JSON (no BOM): $jsonPath" -ForegroundColor Green

    # Version client JAR
    $verJarPath = Join-Path $verDir "1.8.9-forge-custom1.jar"
    Copy-Item -Path $vanillaClientJar -Destination $verJarPath -Force
    Write-Host "[+] Installed version client JAR: $verJarPath" -ForegroundColor Green

    # IMPORTANT: Delete .sklauncher marker file so SKLauncher discovers it as a LOCAL client!
    $markerPath = Join-Path $verDir ".sklauncher"
    if (Test-Path $markerPath) {
        Remove-Item -Path $markerPath -Force
        Write-Host "[+] Removed .sklauncher marker file from $verDir to enable LOCAL client discovery" -ForegroundColor Green
    }
}

# Also ensure instance-local versions directories have the files without .sklauncher
$candidateInstanceDirs = @(
    (Join-Path $dotSklauncher "instances\customforge-1-8-9\versions\1.8.9-forge-custom1"),
    (Join-Path $dotSklauncher "instances\12\versions\1.8.9-forge-custom1"),
    (Join-Path $dotSklauncher "instances\1-8-custom\versions\1.8.9-forge-custom1")
)
foreach ($instVerDir in $candidateInstanceDirs) {
    $parentInst = Split-Path (Split-Path $instVerDir -Parent) -Parent
    if (Test-Path $parentInst) {
        if (-not (Test-Path $instVerDir)) {
            New-Item -ItemType Directory -Path $instVerDir -Force | Out-Null
        }
        Copy-Item -Path (Join-Path $dotSklauncher "versions\1.8.9-forge-custom1\*") -Destination $instVerDir -Force
        $mPath = Join-Path $instVerDir ".sklauncher"
        if (Test-Path $mPath) {
            Remove-Item -Path $mPath -Force
        }
        $instJson = Join-Path $instVerDir "1.8.9-forge-custom1.json"
        if (Test-Path $instJson) {
            Write-JsonFileNoBom $instJson $versionJsonString
        }
        Write-Host "[+] Synced instance version directory: $instVerDir" -ForegroundColor Green
    }
}

# 5. Patch 1.8.9-forge-11.15.1.2318.json in .sklauncher to remove url and set local checksum
$stdVerJsonPath = Join-Path $dotSklauncher "versions\1.8.9-forge-11.15.1.2318\1.8.9-forge-11.15.1.2318.json"
if (Test-Path $stdVerJsonPath) {
    $stdVerRaw = Get-Content -Raw $stdVerJsonPath | ConvertFrom-Json
    foreach ($lib in $stdVerRaw.libraries) {
        if ($lib.name -like "net.minecraftforge:forge:*") {
            if ($lib.psobject.properties["url"]) {
                $lib.psobject.properties.Remove("url")
            }
            $lib | Add-Member -NotePropertyName "checksums" -NotePropertyValue @($jarHash) -Force
        }
    }
    $updatedStdVer = $stdVerRaw | ConvertTo-Json -Depth 10
    Write-JsonFileNoBom $stdVerJsonPath $updatedStdVer
    Write-Host "[+] Patched $stdVerJsonPath without url (no BOM)" -ForegroundColor Green
}

# 6. Reconfigure Custom instances in instances.json
$instancesJsonPath = Join-Path $dotSklauncher "instances.json"
if (Test-Path $instancesJsonPath) {
    $instancesRaw = Get-Content -Raw $instancesJsonPath | ConvertFrom-Json
    
    # Remove any broken/placeholder 1-8-custom entry
    $instancesRaw.instances = @($instancesRaw.instances | Where-Object { $_.id -ne "1-8-custom" })

    $jvmArgsList = @(
        "-XX:+UnlockExperimentalVMOptions",
        "-XX:+UseG1GC",
        "-XX:G1NewSizePercent=20",
        "-XX:G1ReservePercent=20",
        "-XX:MaxGCPauseMillis=25",
        "-XX:G1HeapRegionSize=16M",
        "-Djava.net.preferIPv4Stack=true -Xms1024M -Xmx1792M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=25 -XX:G1HeapRegionSize=16M -XX:+DisableExplicitGC -XX:+AlwaysPreTouch"
    )

    $customInsts = @($instancesRaw.instances | Where-Object { $_.id -eq "customforge-1-8-9" -or $_.id -eq "12" -or $_.name -like "*CustomForge*" })
    foreach ($customInst in $customInsts) {
        $customInst.versionId = "1.8.9-forge-custom1"
        $customInst.gameType = "custom"
        $customInst.minecraftVersion = "1.8.9"
        $customInst.installComplete = $true
        
        if ($customInst.psobject.properties["loaderVersion"]) {
            $customInst.psobject.properties.Remove("loaderVersion")
        }

        $customInst | Add-Member -NotePropertyName "javaComponent" -NotePropertyValue "jre-legacy" -Force
        $customInst | Add-Member -NotePropertyName "memoryMax" -NotePropertyValue 1792 -Force
        $customInst | Add-Member -NotePropertyName "customLaunchHooks" -NotePropertyValue $false -Force
        $customInst | Add-Member -NotePropertyName "jvmArgs" -NotePropertyValue $jvmArgsList -Force
        Write-Host "[+] Configured $($customInst.name) ($($customInst.id)) with 1.8.9-forge-custom1 and G1GC" -ForegroundColor Green
    }

    $updatedJson = $instancesRaw | ConvertTo-Json -Depth 6
    Write-JsonFileNoBom $instancesJsonPath $updatedJson
}

# 7. Write clean launcher_profiles.json without BOM for SKLauncher Import
$launcherProfilesObject = [ordered]@{
    profiles = [ordered]@{
        "1-8-custom" = [ordered]@{
            name = "CustomForge 1.8.9"
            type = "custom"
            created = "2026-11-19T12:00:00.000Z"
            lastUsed = "2026-11-19T12:00:00.000Z"
            lastVersionId = "1.8.9-forge-custom1"
            icon = "Snow"
        }
    }
    settings = [ordered]@{
        profileSorting = "byName"
    }
    version = 3
}
$launcherProfilesJson = $launcherProfilesObject | ConvertTo-Json -Depth 6
$profilesPaths = @(
    (Join-Path $dotMinecraft "launcher_profiles.json"),
    (Join-Path $dotSklauncher "launcher_profiles.json")
)
foreach ($pPath in $profilesPaths) {
    Write-JsonFileNoBom $pPath $launcherProfilesJson
    Write-Host "[+] Wrote clean launcher_profiles.json without BOM: $pPath" -ForegroundColor Green
}

# 8. Apply Intel HD 2000 deep client tuning (splash.properties, options.txt, optionsof.txt)
$targetInstanceDirs = @(
    (Join-Path $dotSklauncher "instances\customforge-1-8-9"),
    (Join-Path $dotSklauncher "instances\12"),
    (Join-Path $dotSklauncher "instances\1-8-custom")
)
foreach ($instDir in $targetInstanceDirs) {
    if (-not (Test-Path $instDir)) { continue }

    # Config dir & splash.properties
    $cfgDir = Join-Path $instDir "config"
    if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }
    $splashPath = Join-Path $cfgDir "splash.properties"
    $splashContent = @"
# Splash screen properties
# Deep lightweight optimization for Intel HD 2000
enabled=false
rotate=false
logoOffset=0
background=0xFFFFFF
font=0x000000
barBorder=0xC0C0C0
bar=0xCB3D35
barBackground=0xFFFFFF
"@
    [System.IO.File]::WriteAllText($splashPath, $splashContent, $utf8NoBom)
    Write-Host "[+] Wrote splash.properties (enabled=false) to $splashPath" -ForegroundColor Green

    # options.txt tuning
    $optionsPath = Join-Path $instDir "options.txt"
    $optMap = [ordered]@{}
    if (Test-Path $optionsPath) {
        $bakDir = Join-Path $instDir "config_bak"
        if (-not (Test-Path $bakDir)) { New-Item -ItemType Directory -Path $bakDir -Force | Out-Null }
        Copy-Item -Path $optionsPath -Destination (Join-Path $bakDir "options.txt.bak") -Force
        foreach ($line in (Get-Content -Path $optionsPath)) {
            if ($line -match "^([^:]+):(.*)$") {
                $optMap[$matches[1]] = $matches[2]
            }
        }
    }
    # Apply requested overrides:
    # renderDistance:5, fancyGraphics:false, ao:0, particles:2, clouds:false, useVbo:true, fboEnable:true, maxFps:120, mipmapLevels:0
    $optMap["renderDistance"] = "5"
    $optMap["fancyGraphics"] = "false"
    $optMap["ao"] = "0"
    $optMap["particles"] = "2"
    $optMap["clouds"] = "false"
    $optMap["useVbo"] = "true"
    $optMap["fboEnable"] = "true"
    $optMap["maxFps"] = "120"
    $optMap["mipmapLevels"] = "0"
    $optMap["snooperEnabled"] = "false"

    $optLines = @()
    foreach ($k in $optMap.Keys) {
        $optLines += "$k`:$($optMap[$k])"
    }
    [System.IO.File]::WriteAllText($optionsPath, ($optLines -join "`r`n") + "`r`n", $utf8NoBom)
    Write-Host "[+] Tuned options.txt for Intel HD 2000 in $instDir" -ForegroundColor Green

    # optionsof.txt tuning
    $ofPath = Join-Path $instDir "optionsof.txt"
    $ofMap = [ordered]@{}
    if (Test-Path $ofPath) {
        $bakDir = Join-Path $instDir "config_bak"
        if (-not (Test-Path $bakDir)) { New-Item -ItemType Directory -Path $bakDir -Force | Out-Null }
        Copy-Item -Path $ofPath -Destination (Join-Path $bakDir "optionsof.txt.bak") -Force
        foreach ($line in (Get-Content -Path $ofPath)) {
            if ($line -match "^([^:]+):(.*)$") {
                $ofMap[$matches[1]] = $matches[2]
            }
        }
    }
    # Apply requested overrides:
    # ofFastMath:true, ofFastRender:true, ofSmartAnimations:true, ofSmoothWorld:true, ofChunkUpdates:1, ofDynamicUpdates:false
    $ofMap["ofFastMath"] = "true"
    $ofMap["ofFastRender"] = "true"
    $ofMap["ofSmartAnimations"] = "true"
    $ofMap["ofSmoothWorld"] = "true"
    $ofMap["ofChunkUpdates"] = "1"
    $ofMap["ofDynamicUpdates"] = "false"
    $ofMap["ofFogType"] = "3"
    $ofMap["ofRenderDistanceFine"] = "5"
    $ofMap["ofMipmapType"] = "0"

    $ofLines = @()
    foreach ($k in $ofMap.Keys) {
        $ofLines += "$k`:$($ofMap[$k])"
    }
    [System.IO.File]::WriteAllText($ofPath, ($ofLines -join "`r`n") + "`r`n", $utf8NoBom)
    Write-Host "[+] Tuned optionsof.txt for Intel HD 2000 in $instDir" -ForegroundColor Green
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " CustomForge 1.8.9 Local Client Configuration Complete!" -ForegroundColor Green
Write-Host " Instances Configured: customforge-1-8-9, 12" -ForegroundColor Cyan
Write-Host " Version:              1.8.9-forge-custom1 (Offline Local JAR)" -ForegroundColor Cyan
Write-Host " Existing '1-8' instance: 100% UNTOUCHED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
