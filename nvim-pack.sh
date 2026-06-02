#!/bin/bash
# Neovim plugin manager helper for vim.pack (Neovim 0.12+)
# Usage: ./nvim-pack.sh [update|remove <plugin>]

LOCKFILE="$HOME/.config/nvim/nvim-pack-lock.json"
PACK_DIR="$HOME/.local/share/nvim/site/pack/core/opt"
SPEC_FILE="$HOME/.config/nvim/lua/plugins/spec.lua"

if [[ ! -f "$LOCKFILE" ]]; then
    echo "Error: $LOCKFILE not found"
    exit 1
fi

cmd="$1"
plugin="$2"

case "$cmd" in
    update)
        echo "Updating plugins from lockfile..."
        while IFS= read -r line; do
            name=$(echo "$line" | awk -F'/' '{print $NF}')
            dir="$PACK_DIR/$name"
            if [[ -d "$dir" ]]; then
                cd "$dir" || continue
                remote=$(git remote get-url origin 2>/dev/null)
                if [[ -n "$remote" ]]; then
                    git fetch --quiet origin || continue
                    rev=$(python3 -c "
import json, sys
with open('$LOCKFILE') as f:
    lock = json.load(f)
for name, info in lock['plugins'].items():
    if '$name' in name:
        print(info['rev'])
        break
")
                    if [[ -n "$rev" ]]; then
                        current=$(git rev-parse HEAD)
                        if [[ "$current" != "$rev" ]]; then
                            git checkout "$rev" --quiet
                            echo "  Updated $name"
                        fi
                    fi
                fi
            fi
        done < <(ls "$PACK_DIR" 2>/dev/null)
        echo "Done."
        ;;
    remove)
        if [[ -z "$plugin" ]]; then
            echo "Usage: $0 remove <plugin-name>"
            echo "Available plugins:"
            python3 -c "
import json
with open('$LOCKFILE') as f:
    lock = json.load(f)
for name in sorted(lock['plugins'].keys()):
    print(f'  {name}')
"
            exit 1
        fi
        echo "Removing $plugin..."
        python3 -c "
import json
with open('$LOCKFILE') as f:
    lock = json.load(f)
if '$plugin' in lock['plugins']:
    del lock['plugins']['$plugin']
    with open('$LOCKFILE', 'w') as f:
        json.dump(lock, f, indent=2)
        print('Removed from lockfile.')
else:
    print('Plugin not found in lockfile.')
    exit(1)
" || exit 1
        dir="$PACK_DIR/$plugin"
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            echo "Removed $dir"
        fi
        echo "Don't forget to remove from $SPEC_FILE:"
        grep -n "$plugin" "$SPEC_FILE" 2>/dev/null || echo "(not found in spec)"
        ;;
    list)
        echo "Installed plugins:"
        python3 -c "
import json
with open('$LOCKFILE') as f:
    lock = json.load(f)
for name, info in sorted(lock['plugins'].items()):
    rev = info['rev'][:7]
    print(f'  {name} ({rev})')
"
        ;;
    *)
        echo "Usage: $0 [update|remove <plugin>|list]"
        echo ""
        echo "Commands:"
        echo "  update              Sync plugins to lockfile revisions"
        echo "  remove <plugin>     Remove plugin from lockfile and disk"
        echo "  list                Show installed plugins"
        ;;
esac
