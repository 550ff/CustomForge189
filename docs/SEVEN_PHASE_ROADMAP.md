# Seven-Phase Roadmap (From YO.txt)

## Phase 1 — ENVIRONMENT, REA INSTALLATION AND RESEARCH ✅ COMPLETE
**Status**: Done
**Deliverables**:
- Environment verified (4 GB RAM, Java 8, Git, Gradle, gh CLI)
- REA assessed: NOT NEEDED (no Java support, requires Node.js)
- Forge 1.8.9 architecture documented
- Project structure created
- Phase 2 plan prepared

---

## Phase 2 — DEVELOPMENT FOUNDATION
**Goal**: Set up reproducible build environment

### Tasks
1. **Create GitHub repository** for CustomForge189
2. **Fork/clone MinecraftForge 1.8.9 branch** as submodule or subtree
3. **Configure GitHub Actions workflow** for building
   - Java 8 (Temurin)
   - Gradle cache
   - 90 min timeout
   - Artifact upload
4. **Verify build works** on GitHub Actions (baseline)
5. **Create custom version JSON** template
6. **Test SKLauncher integration** with dummy JAR
7. **Document build process** for reproducibility

### Local Setup (Minimal)
- Clone Forge 1.8.9 for reference only
- No local build (RAM constraint)
- IDE config for source reading (VS Code / IntelliJ)

### Success Criteria
- [ ] GitHub Actions builds Forge 1.8.9 successfully
- [ ] Artifacts: universal.jar, installer.jar, version.json
- [ ] Version JSON loads in SKLauncher (structure test)

---

## Phase 3 — FIRST CUSTOM FORGE BUILD
**Goal**: Produce baseline custom build with zero optimizations

### Tasks
1. **Modify version scheme**: `11.15.1-custom1` (build number = custom1)
2. **Update processJson** replacements for custom version
3. **Build on GitHub Actions**
4. **Download artifacts**
5. **Install in SKLauncher** as separate version
6. **Launch test**: Main menu → New world → Play 10 min
7. **Verify**: Forge mods load, no crashes

### Success Criteria
- [ ] Custom version appears in SKLauncher
- [ ] Launches without errors
- [ ] Creates world, plays normally
- [ ] Forge mod loading works (test with 1 simple mod)
- [ ] Version JSON correct (inheritsFrom: 1.8.9)

---

## Phase 4 — PERFORMANCE RESEARCH AND BASELINES
**Goal**: Establish measurable baselines, identify bottlenecks

### Research Areas
1. **Profiling setup**: VisualVM, JFR, async-profiler on GitHub Actions or local
2. **Baseline metrics** (vanilla Forge 1.8.9):
   - FPS (static, moving, chunk gen)
   - Frame time variance (p99, p99.9)
   - Heap allocation rate (MB/s)
   - GC frequency & pause times
   - Startup time (launcher → main menu)
   - World load time
   - Chunk generation time
   - Memory footprint (RSS at 10 min)

### Profiling Methodology
- Same world seed, same position, same view
- 60-second measurement windows
- 3 runs per metric, report median
- Java flags: `-Xmx2G -Xms1G -XX:+UseG1GC -XX:MaxGCPauseMillis=20`

### Deliverable: BASELINE_REPORT.md with numbers

---

## Phase 5 — OPTIMIZATION DEVELOPMENT
**Goal**: Implement optimizations in small, tested batches

### Batch 1: Allocation Reduction (Zero Risk)
- [ ] Primitive collections (Trove4j) for hot maps/sets
- [ ] Fast math (sin, cos, atan2, sqrt) - BetterFps algorithms
- [ ] String interning for registry keys, NBT tags
- [ ] Object pooling for Vec3, AABB, BlockPos
- [ ] Remove redundant `new` in hot loops

### Batch 2: Rendering (Low Risk)
- [ ] Display list caching for static chunk geometry
- [ ] Frustum culling improvements
- [ ] Texture bind sorting

### Batch 3: Game Loop (Medium Risk)
- [ ] TileEntity dirty tracking (skip unchanged)
- [ ] Event listener caching (index by event type)
- [ ] Chunk rebuild prioritization

### Per-Change Process
1. Explain bottleneck (with profiling data)
2. Explain solution
3. Identify compatibility risks
4. Benchmark before/after (same methodology as Phase 4)
5. Keep reversible (git commit per change)
6. Test with Tier 1 mods

### Success Criteria
- [ ] Each batch: measurable improvement, no regressions
- [ ] Cumulative: 10%+ FPS improvement, 20%+ allocation reduction

---

## Phase 6 — COMPATIBILITY AND STABILITY
**Goal**: Verify mods work, fix regressions

### Test Matrix
| Mod Set | Mods | Duration |
|---------|------|----------|
| Minimal | 5 (Tier 1) | 30 min |
| Standard | 20 (Tier 1+2) | 1 hour |
| Heavy | 50+ (pack) | 2 hours |
| + OptiFine | Standard + OptiFine | 1 hour |
| + FoamFix | Standard + FoamFix | 1 hour |
| Server | Dedicated + 10 mods | 30 min |

### Regression Checklist
- [ ] All Tier 1 mods load and function
- [ ] OptiFine compatible (no crash, settings work)
- [ ] FoamFix compatible (memory reduction works)
- [ ] No new crashes in vanilla gameplay
- [ ] World saves load correctly
- [ ] Multiplayer sync works
- [ ] Memory stable over 2 hours (no leaks)

### Process
1. Test each batch from Phase 5 against full matrix
2. Document any failures
3. Revert or fix regressions
4. Performance must not degrade vs Phase 4 baseline

---

## Phase 7 — FINAL RELEASE
**Goal**: Deliver production-ready custom Forge

### Deliverables
1. **Final JAR**: `forge-1.8.9-11.15.1-custom-final-universal.jar`
2. **Version JSON**: `1.8.9-forge-custom-final.json`
3. **Installation Guide**: `INSTALL.md` for SKLauncher
4. **Java Requirements**: Document Java 8 requirement
5. **Changelog**: `CHANGES.md` - all modifications with rationale
6. **Benchmark Report**: `BENCHMARKS.md` - before/after comparison
7. **Known Limitations**: Document any trade-offs
8. **Source Reference**: Tag/branch for reproducibility

### Installation Package Structure
```
CustomForge189-Release/
├── forge-1.8.9-11.15.1-custom-final-universal.jar
├── 1.8.9-forge-custom-final.json
├── INSTALL.md
├── CHANGES.md
├── BENCHMARKS.md
└── KNOWN_LIMITATIONS.md
```

### Success Criteria
- [ ] Clean install on fresh SKLauncher profile
- [ ] Loads user's existing mod folder
- [ ] Measurable performance improvement vs stock Forge
- [ ] No data loss / world corruption
- [ ] All documentation complete

---

## Timeline Estimate
| Phase | Estimated Time | Dependencies |
|-------|---------------|--------------|
| 1 | ✅ Done | - |
| 2 | 1-2 days | GitHub Actions setup |
| 3 | 1 day | Phase 2 working |
| 4 | 2-3 days | Profiling setup |
| 5 | 1-2 weeks | Iterative, per-batch |
| 6 | 1 week | Phase 5 complete |
| 7 | 1 day | Phase 6 complete |
| **Total** | **~3-4 weeks** | |

---

## Risk Register
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| GitHub Actions build fails | Medium | High | Test incrementally, cache aggressively |
| MCP mappings unavailable | Low | High | Use stable_20 (in ForgeGradle cache) |
| maven.minecraftforge.net down | Low | Medium | Mirror deps, use mavenCentral fallbacks |
| Optimizations break mods | Medium | High | Small batches, extensive testing |
| 4 GB RAM blocks local test | Certain | Medium | All heavy work on CI |
| SKLauncher version format | Low | Medium | Test early in Phase 2 |
| ForgeGradle 2.1 SNAPSHOT broken | Medium | High | Pin to working commit, vendor if needed |