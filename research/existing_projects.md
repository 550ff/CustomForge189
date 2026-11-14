# Existing Projects Research

## OptiFine (sp614x/optifine)
- **Focus**: Rendering, chunk loading, texture handling, shaders
- **Architecture**: Core mod with extensive ASM transformers
- **1.8.9 branch**: Exists (branch `1.8`)
- **License**: Proprietary, closed source
- **Key techniques**:
  - Connected textures
  - Custom model loading
  - VBO/Display list optimization
  - Chunk rendering multithreading
  - Fast math replacements
  - Smart chunk updates
- **Relevance**: Rendering pipeline reference only; cannot copy code

## FoamFix (asiekierka/FoamFix) - **1.8.9 branch EXISTS**
- **Focus**: Memory usage optimization
- **Architecture**: Core mod + coremod (ASM transformers)
- **Version on 1.8.9**: 0.6.3
- **License**: GPL-3.0 (viral - can only use if our build is GPL)
- **Key techniques**:
  - String interning / deduplication
  - Small object allocation reduction
  - Immutable object caching
  - Weak reference caches
  - Heap inspection/analysis (JMH benchmarks included)
  - NanoHTTPD for heap dump endpoint
- **Relevance**: Memory optimization algorithms reference only; cannot copy GPL code

## BetterFps (Guichaguri/BetterFps) - **1.8 branch EXISTS**
- **Focus**: Game-loop performance, math optimizations
- **Architecture**: Simple mod, minimal ASM
- **License**: MIT
- **Key techniques**:
  - Fast trigonometric functions (sin/cos/atan2)
  - Optimized random number generation
  - Reduced object allocations in hot paths
  - A* pathfinding improvements
- **Relevance**: Can reference algorithms (MIT license)

## VanillaFix
- **Focus**: Crash fixes, compatibility
- **License**: MIT
- **Relevance**: Compatibility reference

## Patcher
- **Focus**: Mod compatibility patching
- **License**: MIT
- **Relevance**: Compatibility strategy reference

## Summary: What We Can Use
| Project | License | Can Reference Algorithms | Can Copy Code |
|---------|---------|--------------------------|---------------|
| OptiFine | Proprietary | ✅ | ❌ |
| FoamFix | GPL-3.0 | ✅ (with caution) | ❌ (unless GPL) |
| BetterFps | MIT | ✅ | ✅ |
| VanillaFix | MIT | ✅ | ✅ |

## Policy
- Re-implement algorithms from first principles
- Reference MIT projects for algorithms only
- No GPL code
- No proprietary code