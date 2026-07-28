#!/usr/bin/env bash
# Takes a fresh CachyOS/Arch machine from nothing to a built home-manager config.
# Run this once. After it finishes, use ./rebuild-linux.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  sudo pacman -S --needed --noconfirm nix
  sudo systemctl enable --now nix-daemon
  REAL_USER="$(whoami)"
  sudo usermod -aG nix "$REAL_USER"
  # Enable flakes (Arch's nix package has them off by default).
  if ! grep -q 'experimental-features' /etc/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo systemctl restart nix-daemon
  fi
  echo "    nix installed. Group membership takes effect after re-login,"
  echo "    but 'sg nix' works for this script without re-login."
fi

# Source nix profile for PATH (works in both login and non-login shells).
if [ -f /etc/profile.d/nix.sh ]; then
  # shellcheck disable=SC1091
  . /etc/profile.d/nix.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: personalize the configured username"
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the user line in flake.nix."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's user line to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed -i -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review with: git diff flake.nix"
  else
    echo "    Skipped. Edit the user line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

echo "==> Step 4: install agent CLIs and herdr (outside Nix)"
# herdr: AUR precompiled binary (skips long rust+zig build).
if ! command -v herdr >/dev/null 2>&1; then
  paru -S --needed --noconfirm herdr-bin
fi
# claude-code: npm (only install if not already present).
if ! command -v claude >/dev/null 2>&1; then
  npm i -g @anthropic-ai/claude-code
fi
# codex: npm (only install if not already present).
if ! command -v codex >/dev/null 2>&1; then
  npm i -g @openai/codex
fi

echo "==> Step 5: back up existing configs (idempotent)"
[ -d ~/.config/nvim ]              && [ ! -L ~/.config/nvim ]              && mv ~/.config/nvim              ~/.config/nvim.bak              && echo "    backed up ~/.config/nvim -> ~/.config/nvim.bak"
[ -f ~/.config/starship.toml ]     && [ ! -L ~/.config/starship.toml ]     && cp  ~/.config/starship.toml     ~/.config/starship.toml.bak     && echo "    backed up ~/.config/starship.toml -> ~/.config/starship.toml.bak"
[ -f ~/.claude/settings.json ]     && [ ! -L ~/.claude/settings.json ]     && cp  ~/.claude/settings.json     ~/.claude/settings.json.bak     && echo "    backed up ~/.claude/settings.json -> ~/.claude/settings.json.bak"

echo "==> Step 6: first home-manager switch (uses sg nix to pick up group membership)"
# 'sg nix' runs the command with the nix group without requiring re-login.
sg nix -c 'nix run github:nix-community/home-manager/release-26.05 -- switch --flake ~/.dotfiles#'"$REAL_USER"

echo "==> Step 7: install home-manager to nix profile (for rebuild-linux.sh)"
sg nix -c 'nix profile install github:nix-community/home-manager/release-26.05'

echo "==> Step 8: merge Claude theme + statusLine into existing settings (preserves hooks/permissions)"
if [ -f ~/.claude/settings.json ] && [ ! -L ~/.claude/settings.json ]; then
  # Take the theme and statusLine from the repo's settings.json and merge into existing.
  REPO_THEME="$(jq -r '.theme // "dark-ansi"' "$DIR/home/.claude/settings.json")"
  REPO_STATUSLINE="$(jq -c '.statusLine' "$DIR/home/.claude/settings.json")"
  if [ "$REPO_STATUSLINE" != "null" ]; then
    TMP="$(mktemp)"
    jq --arg theme "$REPO_THEME" --argjson sl "$REPO_STATUSLINE" \
      '.theme = $theme | .statusLine = $sl' ~/.claude/settings.json > "$TMP"
    mv "$TMP" ~/.claude/settings.json
    echo "    merged theme=\"$REPO_THEME\" and statusLine into ~/.claude/settings.json"
  fi
fi

echo "==> Step 9: add repo aliases + nix PATH to zsh (via sourced file, leaves .zshrc untouched)"
ZSHD_SNIPPET="$HOME/.config/zsh/kunchen-aliases.zsh"
mkdir -p "$(dirname "$ZSHD_SNIPPET")"
cat > "$ZSHD_SNIPPET" <<'EOF'
# --- from kunchen/dotfiles home.nix (cc/co/../add/push/pull/m) ---
alias ..='cd ..'
alias add='git add .'
alias push='git push'
alias pull='git pull'
alias m='git switch main'
alias cc='claude --dangerously-skip-permissions'
alias co='codex --full-auto'

# --- nix profile PATH ---
export PATH="$HOME/.nix-profile/bin:$PATH"
EOF
# Source from .zshrc if not already sourced.
if ! grep -qF 'kunchen-aliases.zsh' ~/.zshrc 2>/dev/null; then
  printf '\n# kunchen/dotfiles aliases\n[ -f ~/.config/zsh/kunchen-aliases.zsh ] && source ~/.config/zsh/kunchen-aliases.zsh\n' >> ~/.zshrc
  echo "    sourced $ZSHD_SNIPPET from ~/.zshrc"
fi

echo "==> Done. Use ./rebuild-linux.sh for future changes. Restart your shell or run: exec zsh"
