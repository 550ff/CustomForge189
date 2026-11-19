<#
.SYNOPSIS
    Installs CustomForge 1.8.9 into SKLauncher / Legacy Launcher / Minecraft.
.DESCRIPTION
    Follows Master Project Specification Part 2, Step 6.2:
    - Installs custom universal JAR into .minecraft\libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-custom1\
    - Creates isolated version profile in .minecraft\versions\1.8.9-forge-custom1\
    - Creates self-contained launcher JSON inheriting vanilla 1.8.9 assets with local JAR resolution
    - Backs up any prior version folder cleanly without touching any other profiles
#>

[CmdletBinding()]
param(
    [string]$JarPath = "",
    [string]$MinecraftDir = "$env:APPDATA\.minecraft"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " CustomForge 1.8.9 Isolated Local Installer (SKLauncher)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Resolve .minecraft directory
if (-not (Test-Path $MinecraftDir)) {
    Write-Error "Target Minecraft directory not found: $MinecraftDir"
}
Write-Host "[+] Target .minecraft: $MinecraftDir" -ForegroundColor Green

# 2. Check for vanilla 1.8.9 base
$vanilla189Jar = Join-Path $MinecraftDir "versions\1.8.9\1.8.9.jar"
if (-not (Test-Path $vanilla189Jar)) {
    Write-Warning "Vanilla 1.8.9 is not installed in '$vanilla189Jar'."
    Write-Warning "Please launch vanilla 1.8.9 once in SKLauncher so Mojang assets and vanilla libraries are downloaded."
} else {
    Write-Host "[+] Verified vanilla 1.8.9 base: $vanilla189Jar" -ForegroundColor Green
}

# 3. Locate source universal JAR
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($JarPath)) {
    $searchPaths = @(
        (Join-Path $repoRoot "dist\baseline\forge-1.8.9-*-universal.jar"),
        (Join-Path $repoRoot "dist\baseline\*.jar"),
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
    Write-Error "Could not find Forge universal JAR. Please supply -JarPath <path-to-jar> or download artifact into dist/baseline/."
}
Write-Host "[+] Source Forge JAR: $JarPath" -ForegroundColor Green

# 4. Target Library Directory & File
$libDir = Join-Path $MinecraftDir "libraries\net\minecraftforge\forge\1.8.9-11.15.1.2318-custom1"
if (-not (Test-Path $libDir)) {
    New-Item -ItemType Directory -Path $libDir -Force | Out-Null
}
$targetLibJar = Join-Path $libDir "forge-1.8.9-11.15.1.2318-custom1.jar"
Copy-Item -Path $JarPath -Destination $targetLibJar -Force
Write-Host "[+] Installed Forge library JAR: $targetLibJar" -ForegroundColor Green

# 5. Target Version Profile Directory & Backup
$verDir = Join-Path $MinecraftDir "versions\1.8.9-forge-custom1"
if (Test-Path $verDir) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $MinecraftDir "versions\1.8.9-forge-custom1.bak_$timestamp"
    Write-Host "[*] Backing up existing profile to: $backupDir" -ForegroundColor Yellow
    Move-Item -Path $verDir -Destination $backupDir -Force
}
New-Item -ItemType Directory -Path $verDir -Force | Out-Null

# Also copy JAR into versions folder for launchers that look in versions/<id>/<id>.jar
$targetVerJar = Join-Path $verDir "1.8.9-forge-custom1.jar"
Copy-Item -Path $JarPath -Destination $targetVerJar -Force

# 6. Generate 1.8.9-forge-custom1.json
$nowIso = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
$versionJson = @{
    "id" = "1.8.9-forge-custom1"
    "inheritsFrom" = "1.8.9"
    "time" = $nowIso
    "releaseTime" = $nowIso
    "type" = "release"
    "mainClass" = "net.minecraft.launchwrapper.Launch"
    "minecraftArguments" = "--username `${auth_player_name} --version `${version_name} --gameDir `${game_directory} --assetsDir `${assets_root} --assetIndex `${assets_index_name} --uuid `${auth_uuid} --accessToken `${auth_access_token} --userProperties `${user_properties} --userType `${user_type} --tweakClass net.minecraftforge.fml.common.launcher.FMLTweaker"
    "libraries" = @(
        # The custom Forge JAR with NO url and NO downloads block: forces local resolution
        @{
            "name" = "net.minecraftforge:forge:1.8.9-11.15.1.2318-custom1"
        },
        @{
            "name" = "net.minecraft:launchwrapper:1.12"
        },
        @{
            "name" = "org.ow2.asm:asm-all:5.0.3"
        },
        @{
            "name" = "jline:jline:2.13"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "com.typesafe.akka:akka-actor_2.11:2.3.3"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "com.typesafe:config:1.2.1"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang:scala-actors-migration_2.11:1.1.0"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang:scala-compiler:2.11.1"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang.plugins:scala-continuations-library_2.11:1.0.2"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang.plugins:scala-continuations-plugin_2.11.1:1.0.2"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang:scala-library:2.11.1"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang.modules:scala-parser-combinators_2.11:1.0.1"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang:scala-reflect:2.11.1"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang.modules:scala-swing_2.11:1.0.1"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "org.scala-lang.modules:scala-xml_2.11:1.0.2"
            "url" = "https://repo1.maven.org/maven2/"
        },
        @{
            "name" = "lzma:lzma:0.0.1"
        },
        @{
            "name" = "java3d:vecmath:1.5.2"
        },
        @{
            "name" = "net.sf.trove4j:trove4j:3.0.3"
        },
        @{
            "name" = "com.google.code.findbugs:jsr305:1.3.9"
            "url" = "https://repo1.maven.org/maven2/"
        }
    )
}

$targetJsonFile = Join-Path $verDir "1.8.9-forge-custom1.json"
$jsonString = $versionJson | ConvertTo-Json -Depth 10
Set-Content -Path $targetJsonFile -Value $jsonString -Encoding UTF8
Write-Host "[+] Generated launcher version JSON: $targetJsonFile" -ForegroundColor Green

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host " Profile Name: 1.8.9-forge-custom1" -ForegroundColor Cyan
Write-Host " In SKLauncher: Add Profile -> Version -> select '1.8.9-forge-custom1'" -ForegroundColor Cyan
Write-Host " Recommended JVM Args: -Xms1024M -Xmx1792M -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=25 -XX:G1HeapRegionSize=16M -XX:+DisableExplicitGC -XX:+AlwaysPreTouch" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
