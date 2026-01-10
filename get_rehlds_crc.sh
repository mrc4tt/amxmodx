#!/bin/bash

# Script to find the ReHLDS CRC from AMX Mod X logs and update the override file

echo "=== ReHLDS CRC Fix Helper ==="
echo ""

# Find the logs directory
LOGS_DIR="addons/amxmodx/logs"
if [ ! -d "$LOGS_DIR" ]; then
    echo "Error: Cannot find logs directory at $LOGS_DIR"
    echo "Please run this script from your game server directory (e.g., cstrike/)"
    exit 1
fi

# Find the most recent log file
LATEST_LOG=$(ls -t "$LOGS_DIR"/L*.log 2>/dev/null | head -n 1)

if [ -z "$LATEST_LOG" ]; then
    echo "Error: No log files found in $LOGS_DIR"
    exit 1
fi

echo "Checking log file: $LATEST_LOG"
echo ""

# Extract CRC information
ENGINE_CRC=$(grep "GameConfig CRC computed engine=" "$LATEST_LOG" | tail -n 1 | sed -n 's/.*engine=\([0-9A-F]*\).*/\1/p')
SERVER_CRC=$(grep "GameConfig CRC computed server=" "$LATEST_LOG" | tail -n 1 | sed -n 's/.*server=\([0-9A-F]*\).*/\1/p')

if [ -z "$ENGINE_CRC" ] && [ -z "$SERVER_CRC" ]; then
    echo "No CRC values found in logs yet."
    echo "Please start your server first, then run this script again."
    exit 1
fi

echo "Found CRC values:"
[ -n "$ENGINE_CRC" ] && echo "  Engine: $ENGINE_CRC"
[ -n "$SERVER_CRC" ] && echo "  Server: $SERVER_CRC"
echo ""

# Create the override file
OVERRIDE_FILE="addons/amxmodx/data/gamedata/custom/linux_crc_overrides.txt"
OVERRIDE_DIR="addons/amxmodx/data/gamedata/custom"

# Create directory if it doesn't exist
mkdir -p "$OVERRIDE_DIR"

# Create the override file
cat > "$OVERRIDE_FILE" << 'EOF'
/**
 * Custom CRC overrides for ReHLDS
 * 
 * This file overrides the default CRC values for ReHLDS binaries.
 * The CRC values below were automatically detected from your server.
 */

"Games"
{
	"*" // Linux CRC overrides for engine/server
	{
		"CRC"
		{
EOF

if [ -n "$ENGINE_CRC" ]; then
cat >> "$OVERRIDE_FILE" << EOF
			"engine"
			{
				"linux" "$ENGINE_CRC"
			}

EOF
fi

if [ -n "$SERVER_CRC" ]; then
cat >> "$OVERRIDE_FILE" << EOF
			"server"
			{
				"linux" "$SERVER_CRC"
			}
EOF
fi

cat >> "$OVERRIDE_FILE" << 'EOF'
		}
	}
}
EOF

echo "✓ Created override file: $OVERRIDE_FILE"
echo ""
echo "The CRC mismatch warnings should disappear on the next server restart."
echo ""
echo "Note: If you update ReHLDS to a different version, you'll need to run"
echo "this script again to update the CRC values."
