# Forge 1.8.9 Architecture Research

## Source Repository
- **Primary**: https://github.com/MinecraftForge/MinecraftForge
- **Branch**: `1.8.9` (exists, 44 branches total)
- **Last commit**: 2017-06-08 (sha: d06e0ad71b8471923cc809dde58251de8299a143)
- **Commit message**: "Fix log4j configuration"

## Version Information (from ForgeVersion.java on 1.8.9 branch)
```
Major: 11
Minor: 15
Revision: 1
Build: 0 (in repo; Jenkins increments)
Minecraft: 1.8.9
MCP: 9.19
```
**Expected artifact**: `forge-1.8.9-11.15.1.x-1.8.9.jar` where x = Jenkins build number

## Build System
| Component | Version/Detail |
|-----------|----------------|
| ForgeGradle | 2.1-SNAPSHOT (build.gradle) / 2.2-SNAPSHOT (FoamFix) |
| Gradle Wrapper | Included in repo (gradlew) |
| Java Compatibility | 1.6 source/target (ForgeGradle) / 1.8 (project) |
| MCP Mappings | stable_20 (dev) / stable_22 (FoamFix) |

## Repository Structure (1.8.9 branch)
```
MinecraftForge/
├── build.gradle              # Main build script
├── gradle.properties         # Not present on 1.8.9 branch
├── settings.gradle           # rootProject.name = 'forge'
├── gradlew / gradlew.bat     # Gradle wrapper
├── jsons/
│   ├── 1.8.9-dev.json        # Dev version JSON
│   ├── 1.8.9-rel.json        # Release version JSON (launcher)
│   └── 1.8.9.json            # Base version JSON
├── patches/
│   └── minecraft/            # Minecraft patches (net/...)
├── mdk/                      # Mod Development Kit template
├── src/
│   └── main/java/            # Forge/FML source code
└── [fmlcore, fmlearlydisplay, fmlloader, etc.]
```

## Version JSONs (Critical for Launcher)

### 1.8.9-rel.json (Release)
- **id**: `@minecraft_version@-@project@@version@` → `1.8.9-forge11.15.1.x`
- **inheritsFrom**: `1.8.9`
- **mainClass**: `net.minecraft.launchwrapper.Launch`
- **tweakClass**: `net.minecraftforge.fml.common.launcher.FMLTweaker`
- **assets**: `1.8`
- **libraries**: Forge artifact + 23 dependencies (ASM, Scala, Akka, etc.)
- **mirrorList**: `http://files.minecraftforge.net/mirror-brand.list`
- **minimumLauncherVersion**: 14

### 1.8.9-dev.json (Development)
- Similar structure, fewer libraries, no installer config
- Uses mavenCentral for most deps

## Patching Process
1. **Clean Minecraft source** → `src-base/minecraft`
2. **Patches** in `patches/minecraft/net/...` applied
3. **Result** → `src-work/minecraft`
4. **Forge code** in `src/main/java/net/minecraftforge/...`
5. **Combined** → reobfuscated → universal JAR

## Key Forge/FML Components
| Package | Purpose |
|---------|---------|
| `net.minecraftforge.common` | Core API, ForgeVersion, config |
| `net.minecraftforge.fml.common` | Mod loading, lifecycle, events |
| `net.minecraftforge.fml.client` | Client-specific hooks |
| `net.minecraftforge.client` | Rendering, model, event hooks |
| `net.minecraftforge.event` | Event bus system |

## Artifact Assembly
From build.gradle:
- `processJson` task generates version JSON with replacements
- `installerVersion = "1.4"` - creates installer
- `buildUserdev = true` - creates userdev (dev) JAR
- `buildInstaller = true` - creates installer JAR
- Output: `forge-<version>-universal.jar` + `forge-<version>-installer.jar`

## Dependencies (from 1.8.9-rel.json)
**Core Libraries:**
- net.minecraft:launchwrapper:1.12
- org.ow2.asm:asm-all:5.0.3
- jline:jline:2.13
- com.typesafe.akka:akka-actor_2.11:2.3.3
- com.typesafe:config:1.2.1
- org.scala-lang:scala-* :2.11.1 (7 artifacts)
- lzma:lzma:0.0.1
- net.sf.jopt-simple:jopt-simple:4.6
- java3d:vecmath:1.5.2
- net.sf.trove4j:trove4j:3.0.3

## MCP Mappings
- **stable_20**: Used in Forge 1.8.9 build.gradle
- **stable_22**: Used by FoamFix (later MCP version)
- Location: Downloaded by ForgeGradle from MCP servers

## Build Output Locations
```
build/
├── libs/
│   ├── forge-1.8.9-11.15.1.x-universal.jar    # Main artifact
│   ├── forge-1.8.9-11.15.1.x-installer.jar    # Installer
│   └── forge-1.8.9-11.15.1.x-userdev.jar      # Dev environment
└── classes/...
```

## License
- Forge: Minecraft Forge Public License v1.0
- FML: Separate license (LGPL-like)
- MCP: Non-commercial, private use

## UNVERIFIED Items
- Exact latest Jenkins build number on 1.8.9 branch
- Whether maven.minecraftforge.net serves 1.8.9 artifacts
- SKLauncher exact version JSON requirements
- GitHub Actions build time for Forge 1.8.9