# Quick Reference: Dual Metamod Builds

## ✅ What Changed

Your AMX Mod X build system now creates **TWO variants** of every package:

### 1. Standard Build (AlliedModders Metamod)
- For vanilla HLDS servers
- General compatibility
- **Package suffix**: None (e.g., `base-linux.tar.gz`)

### 2. ReHLDS Build (Metamod-R)
- For ReHLDS servers (API 3.1+)
- JIT optimizations, better performance
- **Package suffix**: `-rehlds` (e.g., `base-linux-rehlds.tar.gz`)

## 📦 Package Examples

Every release now includes BOTH variants:

**Standard Build:**
- `amxmodx-1.10.0-5474-base-linux.tar.gz`
- `amxmodx-1.10.0-5474-cstrike-windows.zip`

**ReHLDS Build:**
- `amxmodx-1.10.0-5474-base-linux-rehlds.tar.gz`
- `amxmodx-1.10.0-5474-cstrike-windows-rehlds.zip`

## 🎯 Which Build to Use?

| Your Server | Use This Build |
|-------------|---------------|
| Vanilla HLDS | **Standard** |
| ReHLDS Server | **ReHLDS** (recommended) |
| Not sure? | **Standard** (safer default) |

## ⚠️ Important Rules

1. **Never mix variants** - Use matching base + addon
2. **Choose one variant** - Standard OR ReHLDS
3. **Plugins work with both** - No recompilation needed

## 🚀 Quick Install

### For Vanilla HLDS:
```bash
# Download STANDARD packages (no -rehlds suffix)
wget .../amxmodx-VERSION-base-linux.tar.gz
wget .../amxmodx-VERSION-cstrike-linux.tar.gz
tar xzf *.tar.gz
```

### For ReHLDS Servers:
```bash
# Download REHLDS packages (with -rehlds suffix)
wget .../amxmodx-VERSION-base-linux-rehlds.tar.gz
wget .../amxmodx-VERSION-cstrike-linux-rehlds.tar.gz
tar xzf *.tar.gz
```

## 🔧 Build Matrix

### CI Tests (Every Commit)
- ✅ Standard: Ubuntu 22.04 (Clang 11, GCC 9)
- ✅ ReHLDS: Ubuntu 22.04 (Clang 11), Ubuntu 24.04 (GCC 11)
- ✅ Windows: Both variants (MSVC)

### Release Builds
- **6 configurations**: 2 variants × 3 OS/compiler combos
- **All packages**: Base + all game addons for both variants

## 📝 Release Notes Format

Each release lists packages like this:

```markdown
### Standard Build (AlliedModders Metamod)
Compatible with standard HLDS and general use.
- amxmodx-VERSION-base-linux.tar.gz
- amxmodx-VERSION-cstrike-linux.tar.gz

### ReHLDS Optimized Build (Metamod-R)  
Recommended for ReHLDS (API 3.1+). JIT compiler optimizations.
- amxmodx-VERSION-base-linux-rehlds.tar.gz
- amxmodx-VERSION-cstrike-linux-rehlds.tar.gz
```

## 🎓 Key Benefits

### For Standard Build Users:
- ✅ Maximum compatibility
- ✅ Works everywhere
- ✅ Battle-tested

### For ReHLDS Build Users:
- ✅ Better performance (JIT)
- ✅ ReHLDS API optimizations
- ✅ Modern, actively developed

## 🔄 Switching Variants

To switch from Standard to ReHLDS (or vice versa):

```bash
# 1. Remove old installation
rm -rf addons/amxmodx

# 2. Install new variant (matching base + addon)
tar xzf amxmodx-VERSION-base-PLATFORM[-rehlds].tar.gz
tar xzf amxmodx-VERSION-cstrike-PLATFORM[-rehlds].tar.gz
```

## 📊 Compatibility

| Feature | Standard | ReHLDS |
|---------|----------|--------|
| Vanilla HLDS | ✅ Yes | ✅ Yes |
| ReHLDS | ✅ Yes | ✅ Yes (optimized) |
| Plugins | ✅ Same API | ✅ Same API |
| Performance | Good | Better (JIT) |

## 🆘 Troubleshooting

**Problem**: Poor performance on ReHLDS  
**Solution**: Use ReHLDS build packages (with `-rehlds` suffix)

**Problem**: Crashes or errors  
**Solution**: Ensure base and addon packages match (both standard OR both rehlds)

**Problem**: Not sure which I installed  
**Solution**: Run `meta version` - shows "Metamod-r" for ReHLDS build

## 📚 Full Documentation

See [DUAL_METAMOD_BUILDS.md](DUAL_METAMOD_BUILDS.md) for complete details.

## 🔗 Links

- [Metamod-R (ReHLDS)](https://github.com/rehlds/Metamod-R)
- [AlliedModders Metamod](https://github.com/alliedmodders/metamod-hl1)
- [ReHLDS](https://github.com/rehlds/ReHLDS)

---

**TL;DR**: Two builds per release. Use `-rehlds` packages for ReHLDS servers, standard packages for vanilla HLDS. Don't mix them.
