usage() {
  cat <<EOF
Usage: update-github-package <file> <owner/repo>

Update GitHub-sourced packages in Nix files to their latest release.

Arguments:
  <file>        Path to the Nix file to update (e.g., overlays/opencode/package.nix)
  <owner/repo>  GitHub repository (e.g., sst/opencode)

Example:
  update-github-package overlays/opencode/package.nix sst/opencode
EOF
}

main() {
  local file="$1"
  local repo="$2"

  if [ "$file" = "-h" ] || [ "$file" = "--help" ] || [ -z "$file" ] || [ -z "$repo" ]; then
    usage
    exit 0
  fi

  if [ ! -f "$file" ]; then
    echo "Error: File not found: $file"
    exit 1
  fi

  local current_version
  local latest_version
  local version
  local src_hash

  current_version=$(grep "version = " "$file" | head -1 | sed 's/.*"\(.*\)".*/\1/')

  echo "Current version: $current_version"
  echo "Checking for latest version..."

  latest_version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name')

  if [ -z "$latest_version" ] || [ "$latest_version" = "null" ]; then
    echo "Error: Could not fetch latest version from GitHub"
    exit 1
  fi

  version="${latest_version#v}"

  echo "Latest version: $version"

  if [ "$current_version" = "$version" ]; then
    echo "Already up to date!"
    exit 0
  fi

  echo "Updating from $current_version to $version..."
  echo "Fetching source hash..."

  src_hash=$(nix flake prefetch "github:$repo/$latest_version" --json 2>/dev/null | jq -r '.hash')

  if [ -z "$src_hash" ] || [ "$src_hash" = "null" ]; then
    echo "Error: Could not prefetch source hash"
    exit 1
  fi

  echo "Updating $file..."

  sed -i "s/version = \".*\";/version = \"$version\";/" "$file"
  sed -i "s|tag = \"v.*\";|tag = \"v$version\";|" "$file"
  sed -i "0,/hash = \"sha256-.*\";/s||hash = \"$src_hash\";|" "$file"

  echo ""
  echo "✓ Updated $file"
  echo "  Version: $current_version → $version"
  echo "  Hash: $src_hash"
}

main "$@"
