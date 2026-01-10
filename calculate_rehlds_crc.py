#!/usr/bin/env python3
"""
ReHLDS CRC Calculator for AMX Mod X

This script calculates the CRC32 checksum of your engine binaries
to help resolve CRC mismatch warnings with ReHLDS.
"""

import os
import sys
import zlib
import argparse
from pathlib import Path


def calculate_crc32(filepath):
    """Calculate CRC32 checksum of a file."""
    if not os.path.exists(filepath):
        return None
    
    try:
        with open(filepath, 'rb') as f:
            data = f.read()
            crc = zlib.crc32(data) & 0xFFFFFFFF
            return f"{crc:08X}"
    except Exception as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)
        return None


def find_binary(game_dir, binary_name):
    """Try to find a binary file in common locations."""
    possible_paths = [
        os.path.join(game_dir, binary_name),
        os.path.join(game_dir, '..', binary_name),
        os.path.join(game_dir, '..', 'bin', binary_name),
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            return os.path.abspath(path)
    return None


def create_override_file(game_dir, engine_crc, server_crc):
    """Create the CRC override file for AMX Mod X."""
    override_dir = os.path.join(game_dir, 'addons', 'amxmodx', 'data', 'gamedata', 'custom')
    os.makedirs(override_dir, exist_ok=True)
    
    override_file = os.path.join(override_dir, 'linux_crc_overrides.txt')
    
    with open(override_file, 'w') as f:
        f.write('/**\n')
        f.write(' * Custom CRC overrides for ReHLDS\n')
        f.write(' * \n')
        f.write(' * This file overrides the default CRC values for ReHLDS binaries.\n')
        f.write(' * Generated automatically by calculate_rehlds_crc.py\n')
        f.write(' */\n\n')
        f.write('"Games"\n')
        f.write('{\n')
        f.write('\t"*" // Linux CRC overrides for engine/server\n')
        f.write('\t{\n')
        f.write('\t\t"CRC"\n')
        f.write('\t\t{\n')
        
        if engine_crc:
            f.write('\t\t\t"engine"\n')
            f.write('\t\t\t{\n')
            f.write(f'\t\t\t\t"linux" "{engine_crc}"\n')
            f.write('\t\t\t}\n\n')
        
        if server_crc:
            f.write('\t\t\t"server"\n')
            f.write('\t\t\t{\n')
            f.write(f'\t\t\t\t"linux" "{server_crc}"\n')
            f.write('\t\t\t}\n')
        
        f.write('\t\t}\n')
        f.write('\t}\n')
        f.write('}\n')
    
    return override_file


def main():
    parser = argparse.ArgumentParser(
        description='Calculate CRC32 checksums for ReHLDS binaries and create AMX Mod X override file.'
    )
    parser.add_argument(
        'game_dir',
        nargs='?',
        default='.',
        help='Path to game directory (e.g., cstrike/ or valve/). Default: current directory'
    )
    parser.add_argument(
        '--engine',
        help='Path to engine binary (e.g., engine_i486.so or hw.dll)'
    )
    parser.add_argument(
        '--server',
        help='Path to game server binary (e.g., cs.so or mp.dll)'
    )
    parser.add_argument(
        '--no-create',
        action='store_true',
        help='Only display CRC values, do not create override file'
    )
    
    args = parser.parse_args()
    
    game_dir = os.path.abspath(args.game_dir)
    
    if not os.path.isdir(game_dir):
        print(f"Error: Directory not found: {game_dir}", file=sys.stderr)
        return 1
    
    print("=== ReHLDS CRC Calculator ===\n")
    print(f"Game directory: {game_dir}\n")
    
    # Detect platform
    is_linux = sys.platform.startswith('linux')
    is_windows = sys.platform.startswith('win')
    
    # Find binaries
    engine_path = args.engine
    server_path = args.server
    
    if not engine_path:
        if is_linux:
            engine_path = find_binary(game_dir, 'engine_i486.so')
        else:
            engine_path = find_binary(game_dir, 'hw.dll') or find_binary(game_dir, 'swds.dll')
    
    if not server_path:
        # Try to detect game type
        if 'cstrike' in game_dir.lower() or 'czero' in game_dir.lower():
            server_name = 'cs.so' if is_linux else 'mp.dll'
        else:
            server_name = 'hl.so' if is_linux else 'hl.dll'
        server_path = find_binary(game_dir, server_name)
    
    # Calculate CRCs
    engine_crc = None
    server_crc = None
    
    if engine_path:
        print(f"Engine binary: {engine_path}")
        engine_crc = calculate_crc32(engine_path)
        if engine_crc:
            print(f"  CRC32: {engine_crc}")
        else:
            print(f"  Could not calculate CRC")
    else:
        print("Engine binary: Not found")
        print("  Use --engine to specify path manually")
    
    print()
    
    if server_path:
        print(f"Server binary: {server_path}")
        server_crc = calculate_crc32(server_path)
        if server_crc:
            print(f"  CRC32: {server_crc}")
        else:
            print(f"  Could not calculate CRC")
    else:
        print("Server binary: Not found")
        print("  Use --server to specify path manually")
    
    print()
    
    if not engine_crc and not server_crc:
        print("Error: Could not calculate any CRC values.", file=sys.stderr)
        print("\nTip: Make sure you're running this from your game directory,", file=sys.stderr)
        print("or specify binary paths manually with --engine and --server", file=sys.stderr)
        return 1
    
    if args.no_create:
        print("Skipping override file creation (--no-create specified)")
        return 0
    
    # Create override file
    try:
        override_file = create_override_file(game_dir, engine_crc, server_crc)
        print(f"✓ Created override file: {override_file}")
        print("\nThe CRC mismatch warnings should disappear on the next server restart.")
        print("\nNote: If you update ReHLDS, you'll need to run this script again.")
    except Exception as e:
        print(f"Error creating override file: {e}", file=sys.stderr)
        return 1
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
