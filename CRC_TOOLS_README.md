# ReHLDS CRC Fix Tools

This directory contains tools to fix CRC mismatch warnings when running AMX Mod X with ReHLDS.

## Quick Start

### Option 1: Automatic (Using Logs)
If you've already started your server with ReHLDS:
```bash
cd /path/to/your/gameserver/cstrike  # or valve, dod, etc.
bash /home/mikkel/plop/amxmodx/get_rehlds_crc.sh
```

### Option 2: Calculate from Binaries
Calculate CRC directly from your engine files:
```bash
cd /path/to/your/gameserver/cstrike  # or valve, dod, etc.
python3 /home/mikkel/plop/amxmodx/calculate_rehlds_crc.py
```

### Option 3: Manual Specification
If the scripts can't find your binaries automatically:
```bash
python3 /home/mikkel/plop/amxmodx/calculate_rehlds_crc.py /path/to/gameserver/cstrike \
    --engine /path/to/engine_i486.so \
    --server /path/to/cs.so
```

## What These Tools Do

1. **get_rehlds_crc.sh** - Bash script that:
   - Reads your AMX Mod X logs
   - Extracts the CRC values that were already computed
   - Creates the override file automatically

2. **calculate_rehlds_crc.py** - Python script that:
   - Calculates CRC32 checksums directly from binary files
   - Works even before you start the server
   - Auto-detects engine and server binaries
   - Creates the override file

3. **REHLDS_CRC_FIX.md** - Complete documentation explaining:
   - What the CRC mismatch is
   - Why it happens with ReHLDS
   - Multiple solutions (automatic, manual, or ignore)
   - Troubleshooting tips

## Files Created

Both scripts create/update:
```
addons/amxmodx/data/gamedata/custom/linux_crc_overrides.txt
```

This file overrides the default CRC values to match your ReHLDS installation.

## When to Re-run

Run these tools again when you:
- Update ReHLDS to a new version
- Switch between ReHLDS builds/forks
- Move to a different server with a different ReHLDS binary

## Requirements

- **get_rehlds_crc.sh**: Bash (standard on Linux)
- **calculate_rehlds_crc.py**: Python 3 (usually pre-installed)

## More Information

See [REHLDS_CRC_FIX.md](REHLDS_CRC_FIX.md) for detailed documentation.
