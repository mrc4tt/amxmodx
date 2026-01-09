# Dual Metamod Build System

## Overview

AMX Mod X now supports building with two different Metamod variants, providing optimized packages for different server environments:

1. **Standard Build** - Uses AlliedModders Metamod (original)
2. **ReHLDS Build** - Uses Metamod-R (optimized for ReHLDS)

## Why Two Variants?

### Standard Build (AlliedModders Metamod)
- **Use for**: Vanilla HLDS servers, legacy environments
- **Repository**: https://github.com/alliedmodders/metamod-hl1
- **Best for**: General compatibility, standard HLDS installations
- **Stability**: Battle-tested, widely used

### ReHLDS Build (Metamod-R)
- **Use for**: Servers running ReHLDS (API 3.1+)
- **Repository**: https://github.com/rehlds/Metamod-R
- **Best for**: Modern ReHLDS environments
- **Performance**: JIT compiler optimizations, better performance
- **Features**: 
  - Optimized for ReHLDS API
  - Performance improvements
  - Cleaner, modern codebase
  - Active development by ReHLDS team

## Build Matrix

### Linux Builds
Both variants are built on:
- Ubuntu 22.04 (Clang 11, GCC 9)
- Ubuntu 24.04 (GCC 11) - Debian 13+ compatible

### Windows Builds
Both variants are built on:
- Windows Server 2022 (MSVC 2022)

## Package Naming Convention

### Standard Build Packages
```
amxmodx-{version}-{game}-{platform}.{ext}

Examples:
- amxmodx-1.10.0-5474-base-linux.tar.gz
- amxmodx-1.10.0-5474-base-windows.zip
- amxmodx-1.10.0-5474-cstrike-linux.tar.gz
- amxmodx-1.10.0-5474-cstrike-windows.zip
```

### ReHLDS Build Packages
```
amxmodx-{version}-{game}-{platform}-rehlds.{ext}

Examples:
- amxmodx-1.10.0-5474-base-linux-rehlds.tar.gz
- amxmodx-1.10.0-5474-base-windows-rehlds.zip
- amxmodx-1.10.0-5474-cstrike-linux-rehlds.tar.gz
- amxmodx-1.10.0-5474-cstrike-windows-rehlds.zip
```

## Which Build Should I Use?

### Choose Standard Build If:
- ✅ Running vanilla HLDS
- ✅ Using legacy server setup
- ✅ Not sure which to use (safer default)
- ✅ Compatibility is priority

### Choose ReHLDS Build If:
- ✅ Running ReHLDS (API 3.1+)
- ✅ Want better performance
- ✅ Using modern ReHLDS ecosystem
- ✅ Performance is priority

## Installation Guide

### Important: Do Not Mix Variants!
**Never mix standard and ReHLDS packages**. Always use matching base and addon packages.

### Installation Steps

#### For Standard HLDS:
```bash
# Download standard packages
wget https://github.com/.../amxmodx-1.10.0-5474-base-linux.tar.gz
wget https://github.com/.../amxmodx-1.10.0-5474-cstrike-linux.tar.gz

# Extract both to your mod directory
cd /path/to/cstrike
tar xzf amxmodx-1.10.0-5474-base-linux.tar.gz
tar xzf amxmodx-1.10.0-5474-cstrike-linux.tar.gz
```

#### For ReHLDS Servers:
```bash
# Download ReHLDS-optimized packages
wget https://github.com/.../amxmodx-1.10.0-5474-base-linux-rehlds.tar.gz
wget https://github.com/.../amxmodx-1.10.0-5474-cstrike-linux-rehlds.tar.gz

# Extract both to your mod directory
cd /path/to/cstrike
tar xzf amxmodx-1.10.0-5474-base-linux-rehlds.tar.gz
tar xzf amxmodx-1.10.0-5474-cstrike-linux-rehlds.tar.gz
```

## Build Configuration

### Workflow Configuration

Both CI and Release workflows build with both Metamod variants using a build matrix:

```yaml
matrix:
  include:
    # Standard builds
    - metamod_variant: standard
      metamod_repo: https://github.com/alliedmodders/metamod-hl1
      metamod_branch: master
    
    # ReHLDS builds
    - metamod_variant: rehlds
      metamod_repo: https://github.com/rehlds/Metamod-R
      metamod_branch: master
```

### Local Development

#### Building Standard Variant:
```bash
mkdir build && cd build
python3 ../configure.py --enable-optimize \
  --metamod=/path/to/metamod-hl1 \
  --hlsdk=/path/to/hlsdk \
  --mysql=/path/to/mysql-5.5
ambuild
```

#### Building ReHLDS Variant:
```bash
mkdir build-rehlds && cd build-rehlds
python3 ../configure.py --enable-optimize \
  --metamod=/path/to/Metamod-R \
  --hlsdk=/path/to/hlsdk \
  --mysql=/path/to/mysql-5.5
ambuild
```

## CI/CD Pipeline

### Continuous Integration (ci.yml)
Tests both variants on every push/PR:
- Standard: Ubuntu 22.04 (Clang 11, GCC 9)
- ReHLDS: Ubuntu 22.04 (Clang 11), Ubuntu 24.04 (GCC 11)
- Windows: Both variants with MSVC

### Release Workflow (release.yml)
Creates releases with both variants:
- Builds 6 configurations (2 variants × 3 OS/compiler combos)
- Packages are organized in release under:
  - `release/standard/` - Standard build packages
  - `release/rehlds/` - ReHLDS build packages

## Release Structure

Each release includes:

```
Release v1.10.0-5474
├── Standard Build Packages
│   ├── amxmodx-1.10.0-5474-base-linux.tar.gz
│   ├── amxmodx-1.10.0-5474-base-windows.zip
│   ├── amxmodx-1.10.0-5474-cstrike-linux.tar.gz
│   ├── amxmodx-1.10.0-5474-cstrike-windows.zip
│   └── ... (other game addons)
└── ReHLDS Build Packages
    ├── amxmodx-1.10.0-5474-base-linux-rehlds.tar.gz
    ├── amxmodx-1.10.0-5474-base-windows-rehlds.zip
    ├── amxmodx-1.10.0-5474-cstrike-linux-rehlds.tar.gz
    ├── amxmodx-1.10.0-5474-cstrike-windows-rehlds.zip
    └── ... (other game addons)
```

## Compatibility Matrix

| Component | Standard Build | ReHLDS Build |
|-----------|---------------|--------------|
| **HLDS (Vanilla)** | ✅ Recommended | ✅ Compatible |
| **ReHLDS** | ✅ Compatible | ✅ Recommended |
| **Metamod** | AlliedModders | Metamod-R |
| **Performance** | Standard | Optimized (JIT) |
| **API Version** | Standard | ReHLDS API 3.1+ |

## Technical Details

### Metamod-R Optimizations

Metamod-R includes:
- **JIT Compiler Core**: Faster plugin execution
- **Performance Optimizations**: Reduced overhead
- **Modern Codebase**: Cleaner, more maintainable
- **ReHLDS Integration**: Better API utilization

### Binary Compatibility

Both builds produce the same AMX Mod X plugin API, so:
- ✅ Plugins are compatible with both variants
- ✅ Scripting API is identical
- ✅ No plugin recompilation needed
- ✅ Switch between variants by replacing binaries

## Troubleshooting

### Wrong Build Variant Installed

**Symptom**: Poor performance or crashes on ReHLDS
**Solution**: Ensure you're using ReHLDS-optimized packages

**Symptom**: Compatibility issues on vanilla HLDS
**Solution**: Switch to standard build packages

### Mixed Packages

**Symptom**: Loading errors, crashes, undefined behavior
**Solution**: Remove all AMX Mod X files and reinstall matching variant

```bash
# Clean installation
rm -rf addons/amxmodx
# Then reinstall with matching base + addon packages
```

### Verifying Installation

Check your Metamod version:
```
meta version
```

- Standard Metamod: Shows AlliedModders version
- Metamod-R: Shows "Metamod-r" with version

## FAQ

**Q: Can I use standard plugins with ReHLDS build?**  
A: Yes! Plugins are compatible with both variants.

**Q: Is ReHLDS build faster?**  
A: Yes, Metamod-R includes JIT optimizations that improve performance.

**Q: Do I need ReHLDS to use the ReHLDS build?**  
A: No, but it's recommended. ReHLDS build works with vanilla HLDS but is optimized for ReHLDS.

**Q: Can I switch between variants?**  
A: Yes, just replace the binaries. Ensure base and addon match.

**Q: Which build is more stable?**  
A: Both are stable. Standard has longer history, ReHLDS has modern optimizations.

**Q: Does this affect plugin compatibility?**  
A: No, the plugin API is identical for both variants.

## Support

For issues specific to:
- **Standard Build**: Check AlliedModders forums
- **ReHLDS Build**: Check ReHLDS GitHub or forums
- **Build System**: Create issue in this repository

## References

- [AlliedModders Metamod](https://github.com/alliedmodders/metamod-hl1)
- [Metamod-R](https://github.com/rehlds/Metamod-R)
- [ReHLDS](https://github.com/rehlds/ReHLDS)
- [ReHLDS Documentation](https://rehlds.dev/docs/metamod-r/)
