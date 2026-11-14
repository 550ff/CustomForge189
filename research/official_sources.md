# Official Sources Research

## MinecraftForge/MinecraftForge Repository
- **URL**: https://github.com/MinecraftForge/MinecraftForge
- **Branch for 1.8.9**: `1.8.9` (verified exists)
- **Last commit**: 2017-06-08 (sha: d06e0ad)
- **Key files**:
  - `build.gradle` - Main build, ForgeGradle 2.1-SNAPSHOT
  - `jsons/1.8.9-rel.json` - Release version JSON for launcher
  - `jsons/1.8.9-dev.json` - Dev version JSON
  - `src/main/java/net/minecraftforge/common/ForgeVersion.java` - Version constants
  - `patches/minecraft/` - Minecraft source patches
  - `mdk/` - Mod Development Kit template

## ForgeGradle Repository
- **URL**: https://github.com/MinecraftForge/ForgeGradle
- **Branch for 1.8.9**: `FG_2.1` (ForgeGradle 2.1)
- **Tag**: `2.1` (2019-02-15)
- **Key info**: Uses `maven.minecraftforge.net` for dependencies

## Version Information (from ForgeVersion.java on 1.8.9 branch)
```java
public static final int majorVersion    = 11;
public static final int minorVersion    = 15;
public static final int revisionVersion = 1;
public static final int buildVersion    = 0;  // Jenkins increments
public static final String mcVersion = "1.8.9";
public static final String mcpVersion = "9.19";
```
**Artifact pattern**: `forge-1.8.9-11.15.1.{build}-1.8.9.jar`

## MCP Mappings
- **Version**: 9.19 (stable_20 in Forge build.gradle, stable_22 in FoamFix)
- **Source**: Downloaded by ForgeGradle from MCP servers
- **Status**: May be deprecated; ForgeGradle caches locally

## Maven Repositories
| Repo | URL | Status |
|------|-----|--------|
| Forge Maven | https://maven.minecraftforge.net | ✅ Reposilite, active |
| Maven Central | https://repo1.maven.org/maven2 | ✅ Active |
| Files Forge | https://files.minecraftforge.net | ⚠️ Redirects, Cloudflare |
| Sonatype Snapshots | https://oss.sonatype.org/content/repositories/snapshots/ | ✅ Active |

## Version JSON Structure (1.8.9-rel.json)
Key fields for launcher compatibility:
- `id`: `@minecraft_version@-@project@@version@` → `1.8.9-forge11.15.1.x`
- `inheritsFrom`: `1.8.9`
- `mainClass`: `net.minecraft.launchwrapper.Launch`
- `tweakClass`: `net.minecraftforge.fml.common.launcher.FMLTweaker`
- `assets`: `1.8`
- `libraries`: 24 entries (Forge + deps)
- `minimumLauncherVersion`: 14

## License
- Forge: Minecraft Forge Public License v1.0
- FML: LGPL-like (CREDITS-fml.txt, LICENSE-fml.txt)
- MCP: Non-commercial research use only

## UNVERIFIED
- Latest Jenkins build number for 1.8.9
- Whether maven.minecraftforge.net serves 1.8.9 artifacts
- MCP mapping server availability