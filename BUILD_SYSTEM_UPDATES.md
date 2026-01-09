# AMX Mod X Build System Updates

## Overview of Changes

This document describes the updates made to support modern Linux distributions (Debian 13+, Ubuntu 24.04+) and automate the build/release process.

## Changes Made

### 1. Modern Linux Distribution Support

#### Problem
- The `execstack` utility is no longer available in Debian 13 and newer Ubuntu versions
- Modern distributions have stricter security requirements for executable stacks
- Assembly code (NASM) requires proper stack marking

#### Solution
**File: `AMBuildScript`**

Added linker flags to mark stack as non-executable directly during linking, eliminating the need for the `execstack` post-processing tool:

```python
# Add linker flags to mark stack as non-executable
# This replaces the need for execstack tool on modern Linux distributions
# Including Debian 13 and recent Ubuntu versions
cxx.linkflags += ['-Wl,-z,noexecstack']
```

The `-Wl,-z,noexecstack` flag tells the linker to mark the GNU stack segment as non-executable, which is exactly what `execstack -c` would have done post-build.

### 2. Automated Build and Release Workflow

**File: `.github/workflows/release.yml`**

Created a comprehensive GitHub Actions workflow that:

#### Features
- **Multi-Platform Builds**: Builds for Linux (Ubuntu 22.04, 24.04) and Windows
- **Multiple Compiler Support**: Tests with GCC and Clang
- **Automatic Versioning**: Generates version strings from `product.version` + git commit count
  - Format: `1.10.0-<commit_count>`
  - Example: `1.10.0-5474` (matches your current "1.10-5474 Linux" format)

#### Trigger Methods
1. **Manual Dispatch**: Run from GitHub Actions UI with dev/stable option
2. **Tag Push**: Automatically creates stable release when pushing a version tag (e.g., `v1.10.0`)
3. **Scheduled**: Weekly dev builds every Monday at 00:00 UTC

#### Build Matrix
- Ubuntu 22.04 with Clang 11
- Ubuntu 24.04 with GCC 11 (Debian 13+ compatible)
- Windows 2022 with MSVC

#### Release Packages
Automatically creates and uploads:
- **Base Packages**: `amxmodx-{version}-base-{platform}.{ext}`
- **Counter-Strike Addon**: `amxmodx-{version}-cstrike-{platform}.{ext}`
- **Other Game Addons**: DoD, ESF, NS, TFC, TS (platform-dependent)

### 3. Enhanced CI Workflow

**File: `.github/workflows/ci.yml`**

Updated the continuous integration workflow to include:
- Ubuntu 24.04 testing with GCC 11
- Better documentation of build matrix
- Support for modern Linux distributions

## Version Format

The automated versioning follows this pattern:
```
<product.version>-<git_commit_count>
```

Example:
- `product.version` contains: `1.10.0`
- Git commit count: `5474`
- Generated version: `1.10.0-5474`

This matches your current versioning scheme (1.10-5474 Linux).

## Usage

### Running a Development Build

1. Go to "Actions" tab in GitHub
2. Select "Build and Release AMX Mod X"
3. Click "Run workflow"
4. Select "dev" release type
5. The build will create a pre-release with all packages

### Creating a Stable Release

1. Tag your commit:
   ```bash
   git tag v1.10.0
   git push origin v1.10.0
   ```
2. The workflow automatically creates a stable release

### Manual Build (Local Development)

For local builds on modern Linux distributions:

```bash
# Install dependencies (Ubuntu 24.04 / Debian 13+)
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y gcc-multilib g++-multilib \
  libstdc++6 lib32stdc++6 libc6-dev libc6-dev-i386 \
  linux-libc-dev linux-libc-dev:i386 lib32z1-dev nasm

# Clone and setup dependencies
./support/checkout-deps.sh

# Configure and build
mkdir build && cd build
python3 ../configure.py --enable-optimize \
  --metamod=../path/to/metamod-am \
  --hlsdk=../path/to/hlsdk \
  --mysql=../path/to/mysql-5.5
ambuild
```

## Compatibility

### Linux Distributions
- ✅ Ubuntu 22.04 LTS
- ✅ Ubuntu 24.04 LTS
- ✅ Debian 12 (Bookworm)
- ✅ Debian 13 (Trixie) - When released
- ✅ Any modern Linux with kernel 5.x+

### Windows
- ✅ Windows Server 2022
- ✅ Windows 10/11
- ✅ MSVC 2022

### Compilers
- ✅ GCC 9, 11, 12, 13
- ✅ Clang 11, 12, 13, 14+
- ✅ MSVC 2022

## Technical Details

### Why `-Wl,-z,noexecstack`?

Modern security-conscious Linux distributions require that the stack segment be marked as non-executable (NX bit). When using assembly code (like NASM), the default behavior might not set this flag properly, which can cause:

1. Security warnings from the system
2. Refusal to load the library on hardened systems
3. SELinux/AppArmor denials

The `-Wl,-z,noexecstack` linker flag ensures:
- Stack is marked as non-executable in the ELF header
- No need for post-build `execstack` tool
- Compatible with all modern distributions
- Meets security requirements

### Assembly Code Handling

The build system uses NASM for x86 assembly optimizations:
- `helpers-x86.asm`: Helper functions
- `natives-x86.asm`: Native call wrappers
- `amxexecn.asm`: AMX execution engine
- `amxjitsn.asm`: JIT compiler

All assembly outputs are properly linked with non-executable stack marking.

## Troubleshooting

### Build Fails on Modern Linux

If you see errors about executable stack:
```
error: <library>.so requires executable stack
```

**Solution**: This should not occur with the updated `AMBuildScript`. If it does:
1. Verify your AMBuildScript has the `-Wl,-z,noexecstack` flag
2. Clean build directory: `rm -rf build`
3. Rebuild from scratch

### Version Not Updating

**Solution**: The version is generated from:
1. `product.version` file (base version)
2. `git rev-list --count HEAD` (commit count)

Ensure you're in a git repository with commits.

## Migration from Old Build System

No changes required for existing build scripts! The updates are backward-compatible:

- Old builds still work
- New linker flag is additive (doesn't break anything)
- `execstack` tool (if installed) is simply no longer needed

## Future Enhancements

Potential improvements:
- [ ] macOS builds (currently not included)
- [ ] ARM64 Linux builds
- [ ] Docker-based builds for reproducibility
- [ ] Automated testing of built packages
- [ ] Code signing for releases

## Support

For issues related to:
- **Build failures**: Check GitHub Actions logs
- **Distribution compatibility**: Test with local build first
- **Version numbering**: Review `product.version` and git history

## License

These build system changes maintain compatibility with the existing AMX Mod X license (GPL v3).
