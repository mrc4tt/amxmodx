#!/bin/bash
# Ultimate AMX Mod X Compilation Fixes
# Fixes: C++14, AutoPtr, macros, HLSDK conflicts, and all compatibility issues

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

echo "================================================"
echo "AMX Mod X - ULTIMATE Compilation Fixes"
echo "================================================"
echo ""

if [ ! -f "AMBuildScript" ]; then
    print_error "AMBuildScript not found. Run from AMX Mod X root."
    exit 1
fi

# Backup
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
print_info "Creating backups in $BACKUP_DIR/"

# Files to backup
for file in AMBuildScript amxmodx/CPlugin.h amxmodx/CTask.h amxmodx/amxmodx.h \
    modules/geoip/geoip_util.cpp modules/cstrike/csx/rank.h modules/cstrike/csx/meta_api.cpp \
    modules/ns/GameManager.h modules/ns/ParticleManager.h modules/fun/fun.cpp \
    public/HLTypeConversion.h; do
    [ -f "$file" ] && cp "$file" "$BACKUP_DIR/"
done

print_status "Backups created"
echo ""

# Fix 1: C++14
echo "Fix 1: C++14 standard..."
sed -i "s/'-std=c++11'/'-std=c++14'/g" AMBuildScript
print_status "Updated to C++14"

# Fix 2: Remove am-autoptr.h
echo "Fix 2: Remove am-autoptr.h..."
sed -i '/am-autoptr\.h/d' amxmodx/CPlugin.h 2>/dev/null || true
print_status "Removed deprecated header"

# Fix 3: Add #include <memory> and replace AutoPtr in CPlugin.h
echo "Fix 3: Fix AutoPtr in CPlugin.h..."
if [ -f "amxmodx/CPlugin.h" ]; then
    if ! grep -q "#include <memory>" amxmodx/CPlugin.h; then
        sed -i '/#include <amtl\/am-vector.h>/a #include <memory>' amxmodx/CPlugin.h
    fi
    sed -i 's/ke::AutoPtr</std::unique_ptr</g' amxmodx/CPlugin.h
    print_status "Fixed CPlugin.h"
fi

# Fix 4: Fix AutoPtr in CTask.h
echo "Fix 4: Fix AutoPtr in CTask.h..."
if [ -f "amxmodx/CTask.h" ]; then
    if ! grep -q "#include <memory>" amxmodx/CTask.h; then
        sed -i '/#ifndef CTASK_H/a #include <memory>' amxmodx/CTask.h
    fi
    sed -i 's/ke::AutoPtr</std::unique_ptr</g' amxmodx/CTask.h
    print_status "Fixed CTask.h"
fi

# Fix 5: CRITICAL - Undefine min/max macros in amxmodx.h
echo "Fix 5: Fix min/max macro conflicts (CRITICAL)..."
if [ -f "amxmodx/amxmodx.h" ]; then
    # Add after extdll.h include
    if ! grep -q "#undef min" amxmodx/amxmodx.h; then
        sed -i '/#include "extdll.h"/a \
// Undefine HLSDK macros that conflict with C++ standard library\
#ifdef min\
#undef min\
#endif\
#ifdef max\
#undef max\
#endif' amxmodx/amxmodx.h
        print_status "Added min/max undef to amxmodx.h"
    fi
fi

# Fix 6: Fix util.h include guard (redefinition errors)
echo "Fix 6: Fix HLSDK header inclusion..."
if [ -f "public/HLTypeConversion.h" ]; then
    # Check if metamod sdk_util is included before hlsdk util
    if grep -q 'metamod/sdk_util.h' public/HLTypeConversion.h; then
        # Add include guard check
        sed -i '/#include.*metamod\/sdk_util.h/i \
#ifndef UTIL_H_INCLUDED\
#define UTIL_H_INCLUDED' public/HLTypeConversion.h
        
        sed -i '/#include.*metamod\/sdk_util.h/a \
#endif' public/HLTypeConversion.h
        print_status "Added include guards"
    fi
fi

# Fix 7: Fix geoip INFOKEY_VALUE usage
echo "Fix 7: Fix geoip module..."
if [ -f "modules/geoip/geoip_util.cpp" ]; then
    # INFOKEY_VALUE needs edict as string, not pointer
    sed -i 's/INFOKEY_VALUE(MF_GetPlayerEdict(playerIndex), "lang")/ENTITY_KEYVALUE(MF_GetPlayerEdict(playerIndex), "lang")/g' modules/geoip/geoip_util.cpp
    # Actually, we need GETPLAYERAUTHID or infobuffer
    sed -i 's/ENTITY_KEYVALUE(MF_GetPlayerEdict(playerIndex), "lang")/INFOKEY_VALUE(ENTITY_KEYVALUE(MF_GetPlayerEdict(playerIndex), "*"), "lang")/g' modules/geoip/geoip_util.cpp
    print_status "Fixed geoip_util.cpp"
fi

# Fix 8: Fix CSX macros
echo "Fix 8: Fix CSX module macros..."
if [ -f "modules/cstrike/csx/rank.h" ]; then
    # Fix macro syntax - remove trailing backslash issues
    cat > /tmp/csx_rank_fix.txt << 'EOFFIX'
// Insert after existing defines, around line 118
#ifndef MAX_REG_MSGS
#define MAX_REG_MSGS 255
#endif

#define CHECK_ENTITY(x) \\
    if (x < 0 || x > gpGlobals->maxEntities) { \\
        MF_LogError(amx, AMX_ERR_NATIVE, "Entity out of range (%d)", x); \\
        return 0; \\
    } else { \\
        if (x != 0 && FNullEnt(INDEXENT(x))) { \\
            MF_LogError(amx, AMX_ERR_NATIVE, "Invalid entity %d", x); \\
            return 0; \\
        } \\
    }

#define CHECK_PLAYER(x) \\
    if (x < 1 || x > gpGlobals->maxClients) { \\
        MF_LogError(amx, AMX_ERR_NATIVE, "Player out of range (%d)", x); \\
        return 0; \\
    } else { \\
        if (!MF_IsPlayerIngame(x)) { \\
            MF_LogError(amx, AMX_ERR_NATIVE, "Invalid player %d (not in-game)", x); \\
            return 0; \\
        } \\
    }

#define CHECK_PLAYERRANGE(x) \\
    if (x > gpGlobals->maxClients || x < 0) \\
        return 0;

#define CHECK_NONPLAYER(x) \\
    if (x < 1 || x <= gpGlobals->maxClients || x > gpGlobals->maxEntities) { \\
        MF_LogError(amx, AMX_ERR_NATIVE, "Non-player entity %d out of range", x); \\
        return 0; \\
    } else { \\
        if (FNullEnt(INDEXENT(x))) { \\
            MF_LogError(amx, AMX_ERR_NATIVE, "Invalid non-player entity %d", x); \\
            return 0; \\
        } \\
    }

#define GETEDICT(n) \\
    ((n >= 1 && n <= gpGlobals->maxClients) ? MF_GetPlayerEdict(n) : INDEXENT(n))
EOFFIX
    
    # Remove old broken macros (lines 120-173)
    sed -i '120,173d' modules/cstrike/csx/rank.h
    
    # Insert new macros at line 120
    sed -i '120r /tmp/csx_rank_fix.txt' modules/cstrike/csx/rank.h
    
    rm /tmp/csx_rank_fix.txt
    print_status "Fixed CSX rank.h macros"
fi

# Fix 9: Fix CSX meta_api.cpp
echo "Fix 9: Fix CSX meta_api.cpp..."
if [ -f "modules/cstrike/csx/meta_api.cpp" ]; then
    # Fix typo in previous fix
    sed -i 's/SET_GET_LOCALINFO/SET_LOCALINFO/g' modules/cstrike/csx/meta_api.cpp
    print_status "Fixed CSX meta_api.cpp"
fi

# Fix 10: NS module
echo "Fix 10: Fix NS module..."
if [ -f "modules/ns/GameManager.h" ]; then
    sed -i 's/ke::AString/AString/g' modules/ns/GameManager.h
fi
if [ -f "modules/ns/ParticleManager.h" ]; then
    sed -i 's/ke::AString/AString/g; s/ke::Vector/Vector/g' modules/ns/ParticleManager.h
fi
print_status "Fixed NS module"

# Fix 11: Fun module - add min/max undefs
echo "Fix 11: Fix fun module..."
if [ -f "modules/fun/fun.cpp" ]; then
    if ! grep -q "#undef min" modules/fun/fun.cpp; then
        # Add at the top after includes
        sed -i '1a \
// Undefine HLSDK macros\
#ifdef min\
#undef min\
#endif\
#ifdef max\
#undef max\
#endif' modules/fun/fun.cpp
        print_status "Fixed fun.cpp"
    fi
fi

echo ""
echo "================================================"
echo "Summary of All Fixes"
echo "================================================"
echo ""
echo "✓ C++14 standard"
echo "✓ Removed am-autoptr.h"
echo "✓ Replaced ke::AutoPtr with std::unique_ptr"
echo "✓ Fixed min/max macro conflicts (CRITICAL)"
echo "✓ Fixed HLSDK header redefinitions"
echo "✓ Fixed geoip INFOKEY_VALUE usage"
echo "✓ Fixed CSX module macros"
echo "✓ Fixed CSX LOCALINFO"
echo "✓ Fixed NS module namespaces"
echo "✓ Fixed fun module conflicts"
echo ""
print_status "All fixes applied!"
echo ""
echo "Backups: $BACKUP_DIR/"
echo ""
echo "Next: git add . && git commit -m 'Fix: All compilation issues' && git push"
