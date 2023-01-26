export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

ssh-add --apple-use-keychain --apple-load-keychain

#  --dns 8.8.8.8 --dns 8.8.4.4 --dns 1.1.1.1 --dns 1.0.0.1
colima_start="colima start --cpu 5 --memory 16 --disk 250 --runtime docker --dns 1.1.1.1"
alias colima-start="${colima_start} --arch aarch64"
alias colima-start-x86="${colima_start} --arch x86_64"

export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
alias colima-htop="colima ssh -- sudo apk add htop ; colima ssh -- htop"

export BASH_SILENCE_DEPRECATION_WARNING=1

if [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]]; then
    source "/opt/homebrew/etc/profile.d/bash_completion.sh"
fi

if [ -f "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    source "/opt/homebrew/opt/nvm/nvm.sh"
fi

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
  brew cask cleanup &>/dev/null
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
