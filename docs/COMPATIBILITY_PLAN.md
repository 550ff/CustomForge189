# Compatibility Plan

## Compatibility Goals
1. **Forge Mod Compatibility**: Load all existing Forge 1.8.9 mods
2. **Vanilla Compatibility**: Same behavior as vanilla 1.8.9 + Forge
3. **Launcher Compatibility**: Recognized by SKLauncher/Legacy Launcher
4. **Java Compatibility**: Run on Java 8 (no module system, no var, no records)

## Mod Compatibility Testing Strategy

### Tier 1: Core Library Mods (Must Work)
| Mod | Purpose | Test Method |
|-----|---------|-------------|
| CodeChickenLib | Core library | Load + basic function |
| NotEnoughItems (NEI) | Item viewing | Open inventory |
| JEI (if 1.8.9) | Recipe viewing | Open recipe book |
| Baubles | API for accessories | Equip bauble |
| Mantle | Tinkers' Construct lib | Load |
| Bookshelf | Library mod | Load |

### Tier 2: Popular Content Mods
| Mod | Category | Test Method |
|-----|----------|-------------|
| Tinkers' Construct | Tools/weapons | Craft tool, use |
| Thermal Expansion | Tech | Machine craft/use |
| Applied Energistics 2 | Storage | ME system |
| Botania | Magic | Mana generation |
| Thaumcraft (if 1.8.9) | Magic | Research, wand |
| Biomes O' Plenty | World gen | Create world |
| JourneyMap | Minimap | Open map |

### Tier 3: Optimization Mods (Should Coexist)
| Mod | Purpose | Test Method |
|-----|---------|-------------|
| OptiFine | Rendering/performance | Install + launch |
| FoamFix | Memory | Install + check memory |
| BetterFps | Math/game loop | Install + benchmark |
| VanillaFix | Crash fixes | Install + crash test |

### Tier 4: Coremods / Transformers (Highest Risk)
| Mod | Transformer Type | Risk |
|-----|------------------|------|
| OptiFine | Rendering, chunk, texture | High |
| FoamFix | Memory, collections | Medium |
| VanillaFix | Crash hooks, ASM | Medium |
| RandomPatches | Various fixes | Medium |

## Compatibility Test Matrix

| Test Scenario | Expected Result |
|---------------|-----------------|
| Vanilla 1.8.9 + Forge (no mods) | Launch, join world, play 30 min |
| Forge + 10 mods (Tier 1+2) | Launch, join world, basic functions |
| Forge + OptiFine | Launch, settings work, FPS improvement |
| Forge + FoamFix | Launch, memory reduction visible |
| Forge + 50 mods (heavy pack) | Launch, stable 20+ min |
| Server + mods | Dedicated server starts, clients join |
| World upgrade | 1.8.9 world loads in custom build |

## Regression Testing Checklist

### Rendering
- [ ] Blocks render correctly (all types)
- [ ] Entities render (mobs, items, particles)
- [ ] Translucent blocks (water, glass, leaves)
- [ ] Shaders (if OptiFine compatible)
- [ ] Custom models (block/item)
- [ ] Text animations, font rendering

### Gameplay
- [ ] Block breaking/placing
- [ ] Inventory management
- [ ] Crafting (vanilla + mod)
- [ ] Combat (melee, ranged)
- [ ] Movement (walk, sprint, fly, swim)
- [ ] Redstone (basic + complex)
- [ ] Fluids (water, lava flow)

### World
- [ ] Chunk loading/generation
- [ ] Dimension travel (Nether, End, mod dims)
- [ ] Structure generation (villages, temples)
- [ ] Biome transitions
- [ ] World save/load

### Networking (if applicable)
- [ ] Singleplayer (integrated server)
- [ ] Multiplayer client
- [ ] Dedicated server
- [ ] Mod sync (FML handshake)

### Performance
- [ ] No memory leaks (stable heap over 30 min)
- [ ] No excessive GC pauses
- [ ] FPS >= vanilla Forge baseline
- [ ] Startup time <= vanilla Forge

## Version JSON Compatibility
Custom version JSON must:
- [ ] `inheritsFrom: "1.8.9"` (not "1.8.9-Forge...")
- [ ] `mainClass: "net.minecraft.launchwrapper.Launch"`
- [ ] `tweakClass: "net.minecraftforge.fml.common.launcher.FMLTweaker"`
- [ ] `assets: "1.8"`
- [ ] All library entries from 1.8.9-rel.json preserved
- [ ] Custom `id` distinct from official Forge (e.g., `1.8.9-forge-custom1`)

## Launcher Integration (SKLauncher)
1. Version JSON placed in: `%APPDATA%/sklauncher/versions/1.8.9-forge-custom1/`
2. JAR placed in: `%APPDATA%/sklauncher/libraries/net/minecraftforge/forge/1.8.9-forge-custom1/`
3. Assets inherited from 1.8.9 (no custom assets needed)
4. Libraries downloaded from maven.minecraftforge.net + mavenCentral

## Java 8 Specific
- No `module-info.java`
- No `var`, `record`, `sealed`, `pattern matching`
- Target/source compatibility: 1.8
- Bytecode version: 52.0

## Known Incompatibilities to Avoid
| Change | Breaks |
|--------|--------|
| Removing FMLTweaker | All mods |
| Changing event bus signature | All mods with @SubscribeEvent |
| Removing ASM transformer API | Coremods (OptiFine, FoamFix) |
| Changing MCP mapping names | All mods (use stable_20/22) |
| Modifying launchwrapper | Launcher integration |
| Changing ForgeVersion format | Version checkers, mod compatibility |

## UNVERIFIED
- SKLauncher exact version folder structure
- Whether maven.minecraftforge.net serves 1.8.9 artifacts for custom version
- Mod compatibility with specific optimizations (need Phase 6 testing)