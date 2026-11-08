#!/usr/bin/env bash
# Local release for AMX Mod X: replaces the GitHub Actions build/release (ci.yml).
# Runs on the RE server through `server-ops release --only amxmodx` (ops.miksen.me ->
# Releases), but works the same on any machine with docker, git, gh and the
# msvc-wine:latest image (on RE: `server-ops msvc-image`).
#
#   support/local-release.sh --versions
#       one TSV line for server-ops: current, changes, auto, patch, minor, major
#   support/local-release.sh [--dry-run] [--no-windows]
#       build the base and cstrike packages for Linux (docker/Dockerfile.linux, as ci.yml)
#       and Windows (real MSVC under Wine, docker/Dockerfile.windows, AMBuild run by Windows Python), bundle the ReAPI
#       module + includes from the latest mrc4tt/ReAPI release into cstrike, tag
#       v<product.version>.<commit count>, push the tag and publish the GitHub release.
#       --dry-run builds and packages but changes nothing.
#
# The version is product.version plus the commit count, like the old workflow, so there
# is no bump: --bump is accepted and ignored, --version is refused. A commit that is
# already released is skipped.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$PWD
NAME=amxmodx
BRANCH=main
REMOTE=origin
LINUX_IMAGE=amxmodx-build:linux
MSVC_IMAGE=${MSVC_IMAGE:-msvc-wine:latest}
WIN_IMAGE=amxmodx-build:msvc-wine-wow64   # docker/Dockerfile.windows, on top of MSVC_IMAGE
REAPI_REPO=${REAPI_REPO:-mrc4tt/ReAPI}
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/amxmodx-local-release"
WINPY_VERSION=3.12.7
NASM_WIN=https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/nasm-2.16.03-win64.zip   # 64-bit: msvc-wine runs wine64 only
MYSQL_WIN=https://downloads.mysql.com/archives/get/p/19/file/mysql-connector-c-6.1.1-win32.zip
PACKAGES=(base cstrike)

die() { echo "local-release: $*" >&2; exit 1; }

PRODUCT=$(sed 's/-.*//' product.version | tr -d '\r\n')
COUNT=$(git rev-list --count HEAD)
VERSION="$PRODUCT.$COUNT"
TAG="v$VERSION"
LAST_TAG=$(git describe --tags --abbrev=0 --match 'v[0-9]*' HEAD 2>/dev/null || true)
CHANGES=$([[ -n "$LAST_TAG" ]] && git rev-list --count "$LAST_TAG..HEAD" || echo "?")

if [[ "${1:-}" == --versions ]]; then
	auto=$([[ "$TAG" == "$LAST_TAG" ]] && echo - || echo "$TAG")
	printf '%s\t%s\t%s\t-\t-\t-\n' "${LAST_TAG:--}" "$CHANGES" "$auto"
	exit 0
fi

DRY=0 WINDOWS=1
while (( $# )); do
	case "$1" in
		--dry-run) DRY=1 ;;
		--no-windows) WINDOWS=0 ;;
		--bump) shift ;;              # accepted for server-ops; the version is the commit count
		--version) die "the version is product.version + commit count ($VERSION), it cannot be set" ;;
		-h|--help) sed -n '2,19p' "$0"; exit 0 ;;
		*) die "unknown option: $1" ;;
	esac
	shift
done

# --- optional signing, configured on the release machine only -----------------------
# ${LOCAL_RELEASE_SIGNING:-$HOME/.config/local-release/signing.env}, shell syntax:
#   GPG_KEY=<fingerprint>        detach-sign every package; .asc files and the public key are uploaded
GPG_KEY=""
SIGN_ENV=${LOCAL_RELEASE_SIGNING:-$HOME/.config/local-release/signing.env}
if [[ -r "$SIGN_ENV" ]]; then . "$SIGN_ENV"; fi

# --- preflight ---------------------------------------------------------------------
[[ "$(git branch --show-current)" == "$BRANCH" ]] || die "not on $BRANCH"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || die "working tree has changes"
git fetch -q "$REMOTE" "$BRANCH" --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse "$REMOTE/$BRANCH")" ]] || die "$BRANCH is not $REMOTE/$BRANCH"
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && (( ! DRY )); then
	echo "$NAME: $TAG is already released, skipped"; exit 0
fi
command -v docker >/dev/null || die "docker missing"
(( ! WINDOWS )) || docker image inspect "$MSVC_IMAGE" >/dev/null 2>&1 || die "$MSVC_IMAGE missing (on RE: server-ops msvc-image), or use --no-windows"
(( DRY )) || gh auth status >/dev/null 2>&1 || die "gh is not logged in"
[[ -z "$GPG_KEY" ]] || gpg --batch --list-secret-keys "$GPG_KEY" >/dev/null 2>&1 || die "GPG_KEY $GPG_KEY: no secret key"
git submodule update -q --init --recursive
SLUG=$(git remote get-url "$REMOTE" | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')
COMMIT=$(git rev-parse HEAD)
SHORT=$(git rev-parse --short HEAD)

echo "== $NAME: ${LAST_TAG:-none} -> $TAG ($CHANGES commits)$( (( DRY )) && echo ', dry run')"

OUT="$ROOT/dist"
rm -rf "$OUT" && mkdir -p "$OUT" "$CACHE"
GIT_ENV=(-e AMXX_GIT_REVISION_COUNT="$COUNT" -e AMXX_GIT_SHORTHASH="$SHORT" -e AMXX_GIT_LONGHASH="$COMMIT")

# --- ReAPI to bundle: latest release of our fork --------------------------------------
REAPI_DIR="$CACHE/reapi"
rm -rf "$REAPI_DIR" && mkdir -p "$REAPI_DIR"
REAPI_TAG=$(gh release view -R "$REAPI_REPO" --json tagName -q .tagName 2>/dev/null || true)
if [[ -n "$REAPI_TAG" ]]; then
	gh release download "$REAPI_TAG" -R "$REAPI_REPO" -p '*.zip' -D "$REAPI_DIR"
	(cd "$REAPI_DIR" && unzip -q ./*.zip -d x)
	echo "== bundling ReAPI $REAPI_TAG from $REAPI_REPO"
else
	echo "== WARNING: no $REAPI_REPO release, the cstrike packages ship without ReAPI"
fi
bundle_reapi() { # bundle_reapi <cstrike package dir> <linux|windows>
	[[ -d "$REAPI_DIR/x/addons" ]] || return 0
	local dest="$1/addons/amxmodx"
	mkdir -p "$dest/modules" "$dest/scripting/include"
	if [[ $2 == linux ]]; then cp "$REAPI_DIR"/x/addons/amxmodx/modules/*.so "$dest/modules/"
	else cp "$REAPI_DIR"/x/addons/amxmodx/modules/*.dll "$dest/modules/"; fi
	cp "$REAPI_DIR"/x/addons/amxmodx/scripting/include/*.inc "$dest/scripting/include/"
}

# The build output (every compiler call) goes to dist/build-<platform>.log; its end is
# shown only when the build fails.
build_failed() {
	echo "== $1 build FAILED, last lines of dist/build-$1.log:" >&2
	grep -v '^\[[0-9]*\] \(g++\|gcc\|cl\|cp\|ar\|link\|rc\) ' "$OUT/build-$1.log" | tail -40 >&2
	die "$1 build failed"
}

# --- Linux ---------------------------------------------------------------------------
echo "== linux: docker image $LINUX_IMAGE"
docker build -q -t "$LINUX_IMAGE" -f docker/Dockerfile.linux docker >/dev/null
docker run --rm -v "$ROOT:/src:ro" -v "$OUT:/out" "${GIT_ENV[@]}" --entrypoint bash "$LINUX_IMAGE" -euo pipefail -c "
	rm -rf /work && cp -r /src /work && rm -rf /work/build && mkdir /work/build && cd /work/build
	python3 ../configure.py --enable-optimize --metamod=/deps/metamod-am --hlsdk=/deps/hlsdk --mysql=/deps/mysql-5.5
	ambuild
	cp -r packages /out/linux
	chown -R $(id -u):$(id -g) /out/linux" > "$OUT/build-linux.log" 2>&1 || build_failed linux
echo "== linux: built ($(grep -c '^\[' "$OUT/build-linux.log") steps, log dist/build-linux.log)"
bundle_reapi "$OUT/linux/cstrike" linux
for pkg in "${PACKAGES[@]}"; do
	[[ -d "$OUT/linux/$pkg/addons" ]] || die "linux package $pkg missing"
	(cd "$OUT/linux/$pkg" && tar zcf "$OUT/amxmodx-$VERSION-$pkg-linux.tar.gz" addons)
done

# --- Windows -------------------------------------------------------------------------
fetch() { # fetch <url> <file>, kept in the cache
	[[ -s "$2" ]] && return 0
	curl -fsSL -o "$2.part" "$1"
	mv "$2.part" "$2"
}
if (( WINDOWS )); then
	echo "== windows: deps in $CACHE"
	mkdir -p "$CACHE/deps"
	for r in "metamod-am https://github.com/alliedmodders/metamod-hl1" "hlsdk https://github.com/alliedmodders/hlsdk" "ambuild https://github.com/alliedmodders/ambuild"; do
		set -- $r
		if [[ -d "$CACHE/deps/$1/.git" ]]; then git -C "$CACHE/deps/$1" checkout -q -- . && git -C "$CACHE/deps/$1" pull -q --ff-only
		else git clone -q --depth 1 "$2" "$CACHE/deps/$1"; fi
	done
	# AMBuild turns include dirs on the build's drive into relative paths (an old cl/subprocess
	# workaround). cl under Wine does not resolve those from the right directory, so every
	# <header> found only through them is missing. AMBUILD_ABSOLUTE_INCLUDES keeps them absolute;
	# the patch is redone on every run, the checkout above resets it.
	vendors="$CACHE/deps/ambuild/ambuild2/frontend/v2_0/cpp/vendors.py"
	sed -i "s/^        if outputDrive == includeDrive:$/        if outputDrive == includeDrive and not os.environ.get('AMBUILD_ABSOLUTE_INCLUDES'):/" "$vendors"
	grep -q AMBUILD_ABSOLUTE_INCLUDES "$vendors" || die "could not patch $vendors"
	if [[ ! -x "$CACHE/deps/nasm/nasm.exe" ]]; then
		fetch "$NASM_WIN" "$CACHE/nasm.zip"
		rm -rf "$CACHE/deps/nasm" && mkdir -p "$CACHE/deps/nasm"
		unzip -qj "$CACHE/nasm.zip" -d "$CACHE/deps/nasm"
	fi
	if [[ ! -d "$CACHE/deps/mysql-5.5" ]]; then
		fetch "$MYSQL_WIN" "$CACHE/mysql-win32.zip"
		rm -rf "$CACHE/mysql-x" && unzip -q "$CACHE/mysql-win32.zip" -d "$CACHE/mysql-x"
		mv "$CACHE"/mysql-x/mysql-connector-c-6.1.1-win32 "$CACHE/deps/mysql-5.5" && rm -rf "$CACHE/mysql-x"
	fi
	if [[ ! -f "$CACHE/winpy/tools/python.exe" ]]; then
		mkdir -p "$CACHE/winpy"
		fetch "https://www.nuget.org/api/v2/package/python/$WINPY_VERSION" "$CACHE/winpy/python.nupkg"
		python3 -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$CACHE/winpy/python.nupkg" "$CACHE/winpy"
	fi
	echo "== windows: docker image $WIN_IMAGE"
	docker build -q -t "$WIN_IMAGE" --build-arg BASE="$MSVC_IMAGE" -f docker/Dockerfile.windows docker >/dev/null
	# Wine's Python cannot open its standard streams when they are redirected to a file,
	# so its output always goes through a pipe.
	docker run --rm -v "$ROOT:/src:ro" -v "$CACHE/deps:/deps:ro" -v "$CACHE/winpy:/winpy:ro" -v "$OUT:/out" \
		"${GIT_ENV[@]}" "$WIN_IMAGE" bash -euo pipefail -c "
		. /opt/msvc/bin/x86/msvcenv.sh
		# Lower-case drive letter everywhere: AMBuild writes include dirs as z:\\..., and cl under
		# Wine does not find <header> in them when the source file is given as Z:\\... (version.rc).
		export PYTHONPATH='z:\\deps\\ambuild' CC=cl CXX=cl AMBUILD_ABSOLUTE_INCLUDES=1
		rm -rf /work && cp -r /src /work && rm -rf /work/build && mkdir /work/build && cd /work/build
		wine64 /winpy/tools/python.exe 'z:\\work\\configure.py' --enable-optimize '--metamod=z:\\deps\\metamod-am' '--hlsdk=z:\\deps\\hlsdk' '--mysql=z:\\deps\\mysql-5.5' '--nasm=z:\\deps\\nasm\\nasm.exe' 2>&1 | cat
		# AMBuild is incremental: a second run only redoes what failed, should Wine trip once.
		ok=0
		for try in 1 2; do
			if wine64 /winpy/tools/python.exe -c 'import sys, ambuild2.run as r; sys.argv = [\"ambuild\", \"-j\", \"8\"]; r.cli_run()' 2>&1 | cat; then ok=1; break; fi
			echo \"== windows: AMBuild attempt \$try failed, retrying\"
		done
		test \$ok = 1
		test -d packages/base/addons
		cp -r packages /out/windows
		chown -R $(id -u):$(id -g) /out/windows" > "$OUT/build-windows.log" 2>&1 || build_failed windows
	echo "== windows: built ($(grep -c '^\[' "$OUT/build-windows.log") steps, log dist/build-windows.log)"
	bundle_reapi "$OUT/windows/cstrike" windows
	for pkg in "${PACKAGES[@]}"; do
		[[ -d "$OUT/windows/$pkg/addons" ]] || die "windows package $pkg missing"
		(cd "$OUT/windows/$pkg" && python3 -c 'import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
	for root, _, files in os.walk("addons"):
		for f in files:
			z.write(os.path.join(root, f))' "$OUT/amxmodx-$VERSION-$pkg-windows.zip")
	done
fi

ASSETS=("$OUT"/amxmodx-"$VERSION"-*)
if [[ -n "$GPG_KEY" ]]; then
	for f in "${ASSETS[@]}"; do
		gpg --batch --yes --local-user "$GPG_KEY" --detach-sign --armor -o "$f.asc" "$f"
		gpg --batch --verify "$f.asc" "$f" 2>/dev/null || die "signature of $(basename "$f") does not verify"
	done
	gpg --batch --yes --armor --export "$GPG_KEY" > "$OUT/signing-key.asc"
	ASSETS=("$OUT"/amxmodx-"$VERSION"-* "$OUT/signing-key.asc")
	echo "== signed with $GPG_KEY"
fi
echo "== packages:"; for f in "${ASSETS[@]}"; do printf '    %s %s\n' "$(stat -c %s "$f")" "$(basename "$f")"; done

if (( DRY )); then
	echo "== dry run: would tag $TAG and release $SLUG $TAG"
	exit 0
fi

# --- tag, push, release -------------------------------------------------------------
NOTES=$(mktemp); trap 'rm -f "$NOTES"' EXIT
{
	echo "## AMX Mod X $VERSION"
	echo
	if [[ -n "$LAST_TAG" ]]; then
		git log --no-merges --format='- %s (%h)' "$LAST_TAG..HEAD" || true
	fi
	echo
	echo "Packages: base (all games) and cstrike, for Linux (.tar.gz) and Windows (.zip)."
	[[ -z "$REAPI_TAG" ]] || echo "cstrike bundles ReAPI $REAPI_TAG ($REAPI_REPO)."
	(( WINDOWS )) || echo "Linux only (no Windows build)."
	if [[ -n "$GPG_KEY" ]]; then
		echo
		echo "Signed with GPG key \`$GPG_KEY\` (\`signing-key.asc\`): \`gpg --import signing-key.asc && gpg --verify <file>.asc\`"
	fi
} > "$NOTES"

git tag -a "$TAG" -m "AMX Mod X $VERSION"
git push -q "$REMOTE" "$TAG"
gh release create "$TAG" "${ASSETS[@]}" -R "$SLUG" --title "AMX Mod X $VERSION" --notes-file "$NOTES" --latest
echo "== released https://github.com/$SLUG/releases/tag/$TAG"
