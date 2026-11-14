# Optimization Research

## Reference Projects Analyzed

### 1. OptiFine (sp614x/optifine)
- **Focus**: Rendering pipeline, chunk loading, texture handling, shaders
- **Architecture**: Core mod with extensive ASM transformers
- **1.8.9 branch**: Exists (1.8)
- **Key techniques**:
  - Connected textures
  - Custom model loading
  - VBO/Display list optimization
  - Chunk rendering multithreading
  - Fast math replacements
  - Smart chunk updates

### 2. FoamFix (asiekierka/FoamFix) - **1.8.9 branch EXISTS**
- **Focus**: Memory usage optimization
- **Architecture**: Core mod + coremod (ASM transformers)
- **Version on 1.8.9**: 0.6.3 (build.gradle)
- **Key techniques**:
  - String interning / deduplication
  - Small object allocation reduction
  - Immutable object caching
  - Weak reference caches
  - Heap inspection/analysis (JMH benchmarks included)
  - NanoHTTPD for heap dump endpoint
- **License**: GPL (important - viral)

### 3. BetterFps (Guichaguri/BetterFps) - **1.8 branch EXISTS**
- **Focus**: Game-loop performance, math optimizations
- **Architecture**: Simple mod, minimal ASM
- **Key techniques**:
  - Fast trigonometric functions (sin/cos/atan2)
  - Optimized random number generation
  - Reduced object allocations in hot paths
  - A* pathfinding improvements

## Identified Optimization Categories

### A. Rendering Pipeline
| Area | Vanilla/Forge Issue | OptiFine Approach | Risk |
|------|---------------------|-------------------|------|
| Chunk rebuild | Single-threaded, frequent | Multithreaded chunk rebuild | High (thread safety) |
| Display lists | Immediate mode, deprecated | VBOs, display list caching | Medium |
| Texture binding | Frequent state changes | Texture atlasing, bindless | Medium |
| Entity rendering | No frustum culling optimization | Better culling | Low |
| Particle system | High allocation rate | Object pooling | Low |

### B. Chunk Processing
| Area | Issue | Potential Fix | Risk |
|------|-------|---------------|------|
| Chunk loading | Synchronous, blocking | Async chunk loading | High (world access) |
| Chunk saving | Frequent disk I/O | Batched writes, compression | Medium |
| Block updates | Cascade updates | Batch/coalesce updates | Medium |
| Light recalculation | Expensive, single-threaded | Incremental, parallel | High |

### C. Memory & GC
| Area | Issue | FoamFix/BetterFps Approach | Risk |
|------|-------|---------------------------|------|
| String allocation | Massive in NBT, chat, commands | Interning, CharSequence | Low |
| Object allocation | Hot paths (vec3, AABB) | Object pooling, primitives | Low |
| Collection overhead | HashMap/ArrayList in loops | Trove4j, primitive collections | Low |
| Weak references | Mod caches leak | WeakHashMap, ReferenceQueue | Low |

### D. Game Loop & Ticking
| Area | Issue | Potential Fix | Risk |
|------|-------|---------------|------|
| Entity ticking | O(n) per tick, no spatial index | Spatial partitioning | High |
| TileEntity ticking | All ticked every tick | Dirty tracking, event-based | High |
| Random ticks | Block random ticks | Optimized scheduling | Medium |
| Server/client sync | Excessive packets | Delta compression | Medium |

### E. Resource Loading
| Area | Issue | Potential Fix | Risk |
|------|-------|---------------|------|
| Model loading | JSON parsing at startup | Binary format, caching | Low |
| Texture loading | Sequential, no priority | Async, priority queue | Medium |
| Sound loading | Blocking | Async | Low |
| Language files | Reloaded frequently | Caching | Low |

### F. Network
| Area | Issue | Potential Fix | Risk |
|------|-------|---------------|------|
| Packet handling | Single-threaded | Pipeline, batching | High |
| Serialization | Java serialization | Custom binary | High |
| Compression | Per-packet | Batch compression | Medium |

### G. Forge Event System
| Area | Issue | Potential Fix | Risk |
|------|-------|---------------|------|
| Event bus | Synchronous, reflective | Compiled lambdas, indexing | Medium |
| Event firing | Allocates Event objects | Reusable events | Low |
| Mod compatibility | Transformers conflict | Careful ordering | High |

## Compatibility Risk Matrix

| Optimization | Mod Compatibility Risk | Stability Risk | Effort |
|--------------|------------------------|----------------|--------|
| Fast math (sin/cos) | Low (pure functions) | Low | Low |
| Object pooling (Vec3, AABB) | Medium (if mods access fields) | Low | Medium |
| String interning | Low | Low | Low |
| Async chunk loading | **High** (world not thread-safe) | **High** | High |
| VBO rendering | Medium (shader mods) | Medium | High |
| Event bus rewrite | **High** (breaks mod events) | **High** | High |
| TileEntity dirty tracking | Medium (mod TE behavior) | Medium | High |
| Packet batching | Medium (timing-sensitive mods) | Medium | High |

## Recommended Phase 5 Approach (Safe First)

### Batch 1: Zero-Risk Allocation Reductions
1. **Primitive collections** (Trove4j already in deps)
2. **Fast math replacements** (sin/cos/atan2/sqrt)
3. **String interning** for registries, NBT keys
4. **Object pooling** for Vec3, AABB, BlockPos (immutable)
5. **Remove redundant allocations** in hot loops

### Batch 2: Low-Risk Rendering
1. **Display list caching** for static geometry
2. **Frustum culling** improvements
3. **Texture bind reduction** (sort by texture)

### Batch 3: Medium-Risk (Requires Testing)
1. **Chunk rebuild scheduling** (not threading - just prioritize)
2. **TileEntity tick optimization** (dirty flags)
3. **Event bus listener indexing** (cache listener lists)

### Batch 4: High-Risk (Defer to Phase 6+)
1. **Async chunk loading** (requires major refactor)
2. **VBO migration** (shader mod conflicts)
3. **Network pipeline rewrite**

## Licensing Constraints
| Project | License | Can Copy Code? |
|---------|---------|----------------|
| OptiFine | Proprietary (closed source) | ❌ No |
| FoamFix | GPL-3.0 | ⚠️ Only if our build is GPL |
| BetterFps | MIT | ✅ Yes |
| VanillaFix | MIT | ✅ Yes |
| FoamFix-Fabric | MIT | ✅ Yes |

**Policy**: Do not copy GPL code. Re-implement algorithms from first principles. Reference MIT projects for algorithms only.

## Performance Baseline Metrics (To Establish in Phase 4)
| Metric | Measurement Method |
|--------|-------------------|
| FPS (static scene) | Debug screen, 60s average |
| FPS (moving/chunk gen) | Debug screen, 60s average |
| Frame time variance | Frame time graph (F3) |
| Heap allocation rate | VisualVM / JFR |
| GC frequency/pause | GC logs (-Xlog:gc) |
| Startup time | Launcher to main menu |
| World load time | New world creation |
| Chunk gen time | /fill or exploration |
| Memory footprint | RSS after 10 min play |

## UNVERIFIED
- Actual Forge 1.8.9 hot paths (need profiling)
- Whether MCP stable_22 mappings work with Forge 1.8.9 branch
- Mod compatibility with specific optimizations
- GitHub Actions build stability