# macOS-specific configuration (shell-agnostic)
# Works with both bash and zsh

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

export HOMEBREW_PREFIX="$(brew --prefix)"
export HOMEBREW_NO_REQUIRE_TAP_TRUST=1
export HOMEBREW_NO_ASK=1  # skip brew 6.0 upgrade confirmation prompt

# Add SSH keys to keychain (suppress errors if already added)
ssh-add --apple-use-keychain --apple-load-keychain 2>/dev/null

# macOS aliases
alias dns="sudo killall -HUP mDNSResponder"
alias brew-update="brew update ; brew upgrade ; brew cleanup"
alias colima-htop="colima ssh -- sudo apk add htop ; colima ssh -- htop"

# Colima start function
function colima-start {
  colima start \
    --ssh-config=false \
    --dns 9.9.9.9 \
    --dns 1.0.0.1 \
    --cpu "${COLIMA_VM_CPU:-2}" \
    --memory "${COLIMA_VM_MEMORY:-8}" \
    --disk "${COLIMA_VM_DISK:-50}" \
    --profile "${COLIMA_PROFILE:-default}"
}

# Ruby setup (if installed via Homebrew)
if [ -d "${HOMEBREW_PREFIX}/opt/ruby/bin" ]; then
  export PATH="${HOMEBREW_PREFIX}/opt/ruby/bin:$PATH"
  export PATH="$(gem environment gemdir)/bin:$PATH"
fi

# asdf version manager
if [ -f "${HOMEBREW_PREFIX}/opt/asdf/libexec/asdf.sh" ]; then
    . "${HOMEBREW_PREFIX}/opt/asdf/libexec/asdf.sh"
fi

# Helpers for cleanup-caches (defined at file scope so plain `find`/`rm`
# combos below never trip a zsh "no matches found" error on an unmatched
# glob — that error fires at expansion time, before `rm` even runs, so
# `&>/dev/null` can't suppress it. These take real paths instead of globs.

# Delete the *contents* of one or more existing directories. Missing
# directories are silently skipped.
_cleanup_purge() {
  local dir
  for dir in "$@"; do
    [ -n "$dir" ] && [ -d "$dir" ] || continue
    find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null
  done
}

# Same as _cleanup_purge, but for root-owned paths.
_cleanup_purge_sudo() {
  local dir
  for dir in "$@"; do
    [ -n "$dir" ] && [ -d "$dir" ] || continue
    sudo find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null
  done
}

# Delete files matching a name pattern directly inside one directory
# (no recursion), e.g. _cleanup_purge_glob /private/var/log/asl '*.asl'.
_cleanup_purge_glob() {
  local dir="$1" pattern="$2"
  [ -n "$dir" ] && [ -d "$dir" ] || return 0
  find "$dir" -maxdepth 1 -name "$pattern" -delete 2>/dev/null
}

# Same as _cleanup_purge_glob, but for root-owned paths.
_cleanup_purge_glob_sudo() {
  local dir="$1" pattern="$2"
  [ -n "$dir" ] && [ -d "$dir" ] || return 0
  sudo find "$dir" -maxdepth 1 -name "$pattern" -delete 2>/dev/null
}

# macOS-specific cleanup function
function cleanup-caches {
  # Source: https://github.com/paulaime/CleanUpMac/blob/master/cleanup
  #
  # Requires sudo (Trash on other volumes, system logs, purge). Quit Chrome
  # first so its cache directories aren't locked mid-cleanup. Set
  # CLEANUP_GO_MODCACHE=1 to also wipe the Go module cache (off by default —
  # it's expensive to re-download).

  echo 'Requesting sudo access (needed for system logs, Trash, and purge) ...'
  sudo -v

  local free_before free_after
  free_before=$(df -k / | awk 'NR==2{print $4}')

  echo 'Empty the Trash on all mounted volumes and the main HDD ...'
  if [ -d /Volumes ]; then
    find /Volumes -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null |
      while IFS= read -r -d '' vol; do
        _cleanup_purge_sudo "$vol/.Trashes"
      done
  fi
  _cleanup_purge_sudo "$HOME/.Trash"

  echo 'Clear system log files ...'
  _cleanup_purge_glob_sudo /private/var/log/asl '*.asl'
  _cleanup_purge_sudo /Library/Logs/DiagnosticReports
  _cleanup_purge_sudo /Library/Logs/Adobe
  _cleanup_purge "$HOME/Library/Containers/com.apple.mail/Data/Library/Logs/Mail"
  _cleanup_purge "$HOME/Library/Logs/CoreSimulator"

  echo 'Clear Adobe cache files ...'
  _cleanup_purge_sudo "$HOME/Library/Application Support/Adobe/Common/Media Cache Files"

  echo 'Cleanup iOS applications ...'
  _cleanup_purge "$HOME/Music/iTunes/iTunes Media/Mobile Applications"

  echo 'Remove iOS device backups ...'
  _cleanup_purge "$HOME/Library/Application Support/MobileSync/Backup"

  echo 'Cleanup Xcode derived data, archives, and simulator caches ...'
  _cleanup_purge "$HOME/Library/Developer/Xcode/DerivedData"
  _cleanup_purge "$HOME/Library/Developer/Xcode/Archives"
  _cleanup_purge "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  _cleanup_purge "$HOME/Library/Developer/CoreSimulator/Caches"
  if command -v xcrun >/dev/null 2>&1; then
    xcrun simctl delete unavailable &>/dev/null
  fi

  echo 'Cleanup Homebrew cache ...'
  if command -v brew >/dev/null 2>&1; then
    brew cleanup --prune=all -s &>/dev/null
    brew tap --repair &>/dev/null
    _cleanup_purge "$(brew --cache 2>/dev/null)"
  fi
  _cleanup_purge_sudo /Library/Caches/Homebrew

  echo 'Cleanup any old versions of gems ...'
  if command -v gem >/dev/null 2>&1; then
    gem cleanup &>/dev/null
  fi

  echo 'Cleanup Go build cache ...'
  if command -v go >/dev/null 2>&1; then
    go clean -cache -testcache &>/dev/null
    # Module cache is expensive to rebuild from scratch, so it's opt-in.
    if [ "${CLEANUP_GO_MODCACHE:-0}" = "1" ]; then
      go clean -modcache &>/dev/null
    fi
  else
    _cleanup_purge "$HOME/Library/Caches/go-build"
  fi

  echo 'Cleanup Node ecosystem caches ...'
  if command -v npm >/dev/null 2>&1; then
    npm cache clean --force &>/dev/null
  fi
  if command -v pnpm >/dev/null 2>&1; then
    pnpm store prune &>/dev/null
  fi
  if command -v yarn >/dev/null 2>&1; then
    yarn cache clean &>/dev/null
  fi
  _cleanup_purge "$HOME/.bun/install/cache"

  echo 'Cleanup Python caches ...'
  if command -v pip3 >/dev/null 2>&1; then
    pip3 cache purge &>/dev/null
  fi
  if command -v uv >/dev/null 2>&1; then
    uv cache prune &>/dev/null
  else
    _cleanup_purge "$HOME/.cache/uv"
  fi
  _cleanup_purge "$HOME/Library/Caches/pip"

  echo 'Cleanup Rust cargo registry cache ...'
  if [ -d "$HOME/.cargo" ]; then
    _cleanup_purge "$HOME/.cargo/registry/cache"
  fi

  echo 'Cleanup Gradle cache ...'
  _cleanup_purge "$HOME/.gradle/caches"

  echo 'Cleanup JetBrains caches ...'
  _cleanup_purge "$HOME/Library/Caches/JetBrains"

  echo 'Cleanup gcloud logs and component cache ...'
  # Never touch credentials.db, access_tokens.db, or configurations/.
  _cleanup_purge "$HOME/.config/gcloud/logs"
  _cleanup_purge "$HOME/.config/gcloud/cache"

  echo 'Cleanup Google Chrome caches (quit Chrome first for best results) ...'
  _cleanup_purge "$HOME/Library/Caches/Google/Chrome"
  if [ -d "$HOME/Library/Application Support/Google/Chrome" ]; then
    find "$HOME/Library/Application Support/Google/Chrome" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null |
      while IFS= read -r -d '' profile_dir; do
        _cleanup_purge "$profile_dir/Service Worker/CacheStorage"
        _cleanup_purge "$profile_dir/Code Cache"
        _cleanup_purge "$profile_dir/GPUCache"
      done
  fi

  echo 'Cleanup Docker/Colima build cache ...'
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker builder prune -f &>/dev/null
  fi

  echo 'Cleanup an allowlist of known-safe app caches ...'
  # Deliberately explicit rather than blanket-purging ~/Library/Caches.
  _cleanup_purge \
    "$HOME/Library/Caches/com.apple.dt.Xcode" \
    "$HOME/Library/Caches/Yarn" \
    "$HOME/Library/Caches/electron" \
    "$HOME/Library/Caches/ms-playwright"

  # Refresh the cached sudo timestamp: sudo -v at the top only holds ~5
  # minutes, and brew/DerivedData/docker cleanup above can easily outrun
  # that, which would otherwise surprise-prompt for a password here.
  sudo -v

  # command -v checks the calling shell's PATH, not sudo's secure_path —
  # that's fine here since /usr/sbin is on both.
  if command -v periodic >/dev/null 2>&1; then
    echo 'Running the maintenance scripts ...'
    sudo periodic daily weekly monthly
  fi

  if command -v purge >/dev/null 2>&1; then
    echo 'Purge inactive memory ...'
    sudo purge
  fi

  free_after=$(df -k / | awk 'NR==2{print $4}')
  awk -v before="$free_before" -v after="$free_after" 'BEGIN {
    before_gb = before / 1024 / 1024
    after_gb = after / 1024 / 1024
    delta_mb = (after - before) / 1024
    sign = "+"
    val = delta_mb
    if (delta_mb < 0) { sign = "-"; val = -delta_mb }
    unit = "MB"
    if (val >= 1024) { val = val / 1024; unit = "GB" }
    printf "Done! Free space on / changed by %s%.2f %s (was %.1f GB, now %.1f GB)\n", sign, val, unit, before_gb, after_gb
  }'
}
