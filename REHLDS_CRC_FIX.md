# Fixing CRC Mismatch with ReHLDS

## What is the CRC Mismatch?

When you run AMX Mod X with ReHLDS (including the mrc4tt fork from https://github.com/mrc4tt/ReHLDS), you may see warning messages like:

```
GameConfig CRC mismatch for game "cstrike" section "..." library "engine" platform "linux" expected 876A45F5 got XXXXXXXX
```

This happens because:
1. AMX Mod X calculates a CRC32 checksum of the engine binary to validate compatibility
2. ReHLDS modifies the Half-Life engine, resulting in a different binary and thus a different CRC
3. AMX Mod X expects the vanilla HLDS CRC values

**Important:** This is just a warning. AMX Mod X will continue to work normally with ReHLDS. However, if you want to eliminate the warnings, you have several options.

## Solution 1: Use the Automatic Script (Easiest)

1. Start your server with ReHLDS at least once
2. Run the provided script from your game server directory (e.g., `cstrike/` or `valve/`):
   ```bash
   bash /path/to/get_rehlds_crc.sh
   ```
3. The script will:
   - Read your server logs
   - Extract the actual CRC values for your ReHLDS build
   - Create/update `addons/amxmodx/data/gamedata/custom/linux_crc_overrides.txt`
4. Restart your server - the warnings should be gone

## Solution 2: Manual Override

If the script doesn't work or you prefer manual setup:

1. Start your server and check the AMX Mod X logs in `addons/amxmodx/logs/`
2. Look for lines like:
   ```
   GameConfig CRC computed engine=XXXXXXXX (/path/to/engine_i486.so)
   GameConfig CRC computed server=YYYYYYYY (/path/to/cs.so)
   ```
3. Note the 8-character hexadecimal CRC values (XXXXXXXX and YYYYYYYY)
4. Create the file `addons/amxmodx/data/gamedata/custom/linux_crc_overrides.txt` with:

```
"Games"
{
	"*" // Linux CRC overrides for ReHLDS
	{
		"CRC"
		{
			"engine"
			{
				"linux" "XXXXXXXX"  // Replace with your actual CRC
			}

			"server"
			{
				"linux" "YYYYYYYY"  // Replace with your actual CRC
			}
		}
	}
}
```

5. Save and restart your server

## Solution 3: Ignore the Warnings

The CRC mismatch is purely informational. If you:
- Don't mind the log warnings
- Have tested that everything works correctly
- Trust your ReHLDS build

You can simply ignore these messages. They don't affect gameplay or plugin functionality.

## Important Notes

### When You Need to Update CRC Values

You'll need to re-run the script or manually update CRC values when:
- You update ReHLDS to a new version
- You switch between different ReHLDS builds
- You change from one fork to another (e.g., official ReHLDS → mrc4tt fork)

### Why CRC Checking Exists

AMX Mod X uses CRC checking to:
- Detect when running on modified engines
- Ensure compatibility with specific engine versions
- Help identify potential issues with gamedata signatures

ReHLDS is designed to be compatible with AMX Mod X, so the CRC mismatch is expected and not a problem.

### Custom Gamedata Override System

AMX Mod X supports a `custom/` subdirectory for gamedata overrides:
- Default gamedata is in `addons/amxmodx/data/gamedata/common.games/`
- Custom overrides go in `addons/amxmodx/data/gamedata/custom/`
- Custom files are parsed after default files
- This prevents your changes from being overwritten during updates

## Troubleshooting

### Script Shows "No log files found"
- Make sure you're running the script from your game directory (where `addons/` folder is)
- Start your server at least once to generate logs

### CRC Values Keep Changing
- This means you're switching between different engine binaries
- Make sure you're consistently using the same ReHLDS build
- Check that you're not accidentally running vanilla HLDS sometimes

### Override File Not Working
- Verify the file is in the correct location: `addons/amxmodx/data/gamedata/custom/linux_crc_overrides.txt`
- Check that the CRC values are exactly 8 hexadecimal characters (uppercase)
- Ensure the file has proper KeyValues syntax (no extra quotes, commas, etc.)
- Restart the server after creating/modifying the file

## Additional Information

- ReHLDS GitHub: https://github.com/rehlds/ReHLDS
- mrc4tt's fork: https://github.com/mrc4tt/ReHLDS
- AMX Mod X Gamedata Documentation: http://wiki.alliedmods.net/Gamedata_Updating_(AMX_Mod_X)
