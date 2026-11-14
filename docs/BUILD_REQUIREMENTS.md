# Build Requirements

## Local Requirements (Minimal)
| Requirement | Specification | Status |
|-------------|---------------|--------|
| Java 8 JDK | 1.8.0_x (Temurin/OpenJDK) | ✅ Installed |
| Git | 2.x | ✅ Installed |
| GitHub CLI | 2.x (authenticated) | ✅ Installed |
| Text editor | VS Code / Notepad++ | ✅ Available |
| SKLauncher | For testing | ✅ Installed |

## Cloud CI Requirements (GitHub Actions)
| Requirement | Specification |
|-------------|---------------|
| Runner | ubuntu-latest (2-core, 7 GB RAM) |
| Java | Temurin 8 (setup-java action) |
| Gradle | Wrapper from repo (gradlew) |
| Cache | ~/.gradle/caches, ~/.m2/repository |
| Artifacts | Upload JARs + version JSON |
| Timeout | 60-90 minutes (Forge builds are slow) |

## ForgeGradle Requirements
| Component | Version | Source |
|-----------|---------|--------|
| ForgeGradle | 2.1-SNAPSHOT / 2.2-SNAPSHOT | maven.minecraftforge.net |
| Gradle | Wrapper (2.x/3.x era) | Included in Forge repo |
| MCP Mappings | stable_20 or stable_22 | MCP server (auto-download) |
| Minecraft Assets | 1.8 (auto-download) | Mojang servers |

## Repository Access
| Repository | URL | Access |
|------------|-----|--------|
| MinecraftForge | https://github.com/MinecraftForge/MinecraftForge | Public |
| ForgeGradle | https://github.com/MinecraftForge/ForgeGradle | Public |
| Maven (Forge) | https://maven.minecraftforge.net | Public (Reposilite) |
| Maven Central | https://repo1.maven.org/maven2 | Public |
| MCP Mappings | http://export.mcpbot.bspk.rs | Public (may be deprecated) |

## Build Process (High Level)
```bash
# 1. Clone Forge 1.8.9 branch
git clone -b 1.8.9 https://github.com/MinecraftForge/MinecraftForge.git

# 2. Run Gradle setup (downloads MCP, assets, deps)
./gradlew setupDecompWorkspace

# 3. Build universal JAR
./gradlew build

# 4. Artifacts in build/libs/
```

## Expected Build Artifacts
| Artifact | Purpose |
|----------|---------|
| `forge-1.8.9-11.15.1.x-universal.jar` | Main modded client/server JAR |
| `forge-1.8.9-11.15.1.x-installer.jar` | Installer for launchers |
| `forge-1.8.9-11.15.1.x-userdev.jar` | Development environment |
| `1.8.9-forge-11.15.1.x.json` | Version JSON for launcher |

## Version JSON Customization (For Custom Build)
Need to modify `processJson` replacements:
- `@version@` → Custom version string (e.g., `11.15.1-custom1`)
- `@universal_jar@` → Custom JAR name
- `@timestamp@` → Build timestamp
- Add custom `id` in version JSON: `1.8.9-forge-custom1`

## Launcher Integration (SKLauncher / Legacy)
1. Place version JSON in launcher versions folder
2. Place universal JAR in libraries folder matching JSON path
3. Launcher reads JSON, downloads libraries, launches with tweakClass

## Storage Estimates
| Item | Size |
|------|------|
| Forge source clone | ~200 MB |
| Gradle cache (after setup) | ~1-2 GB |
| MCP mappings + decompiled MC | ~500 MB |
| Build output | ~50 MB |
| **Total local (if built locally)** | **~3-4 GB** |
| **GitHub Actions cache** | **Free (5 GB limit)** |

## RAM Requirements
| Task | Min RAM | Recommended |
|------|---------|-------------|
| Gradle setupDecompWorkspace | 2 GB | 3-4 GB |
| Gradle build | 1.5 GB | 2-3 GB |
| Minecraft client (testing) | 1 GB | 2 GB |
| **Total for local build+test** | **3.5 GB** | **5+ GB** |

→ **Conclusion: Local build not feasible on 4 GB machine. Use GitHub Actions.**

## GitHub Actions Workflow Skeleton
```yaml
name: Build Custom Forge 1.8.9
on: [workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v4
        with:
          repository: MinecraftForge/MinecraftForge
          ref: 1.8.9
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 8
      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4
      - name: Build
        run: ./gradlew build -x test
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          path: build/libs/*.jar
```

## UNVERIFIED / Risks
- Maven.minecraftforge.net may not serve 1.8.9 artifacts (old version)
- MCP mapping server (export.mcpbot.bspk.rs) may be deprecated
- ForgeGradle 2.1-SNAPSHOT may have dependency resolution issues
- GitHub Actions 7 GB RAM may be tight for decomp workspace
- Build time may exceed 90 min timeout