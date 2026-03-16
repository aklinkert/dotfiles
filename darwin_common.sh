# macOS-specific configuration (shell-agnostic)
# Works with both bash and zsh

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

export HOMEBREW_PREFIX="$(brew --prefix)"

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
    --cpu "${COLIMA_VM_CPU:-4}" \
    --memory "${COLIMA_VM_MEMORY:-16}" \
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

# macOS-specific cleanup function
function cleanup-caches {
  # Source: https://github.com/paulaime/CleanUpMac/blob/master/cleanup

  echo 'Empty the Trash on all mounted volumes and the main HDD ...'
  sudo rm -rfv /Volumes/*/.Trashes &>/dev/null
  sudo rm -rfv ~/.Trash &>/dev/null

  echo 'Clear System Log Files ...'
  sudo rm -rfv /private/var/log/asl/*.asl &>/dev/null
  sudo rm -rfv /Library/Logs/DiagnosticReports/* &>/dev/null
  sudo rm -rfv /Library/Logs/Adobe/* &>/dev/null
  rm -rfv ~/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/* &>/dev/null
  rm -rfv ~/Library/Logs/CoreSimulator/* &>/dev/null

  echo 'Clear Adobe Cache Files ...'
  sudo rm -rfv ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files/* &>/dev/null

  echo 'Cleanup iOS Applications ...'
  rm -rfv ~/Music/iTunes/iTunes\ Media/Mobile\ Applications/* &>/dev/null

  echo 'Remove iOS Device Backups ...'
  rm -rfv ~/Library/Application\ Support/MobileSync/Backup/* &>/dev/null

  echo 'Cleanup XCode Derived Data and Archives ...'
  rm -rfv ~/Library/Developer/Xcode/DerivedData/* &>/dev/null
  rm -rfv ~/Library/Developer/Xcode/Archives/* &>/dev/null

  echo 'Cleanup Homebrew Cache ...'
  brew cleanup --force -s &>/dev/null
  rm -rfv /Library/Caches/Homebrew/* &>/dev/null
  brew tap --repair &>/dev/null

  echo 'Cleanup any old versions of gems ...'
  gem cleanup &>/dev/null

  echo 'Running the maintenance scripts ...'
  sudo periodic daily weekly monthly

  echo 'Purge inactive memory ...'
  sudo purge

  clear && echo 'Yeah, everything is cleaned up! :)'
}
