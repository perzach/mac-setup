# Mac setup

Based on [Erlend's setup](https://github.com/ErlendF/mac-setup.git)

## Set up eveything
1. Install oh-my-zsh:
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

2. Run setup script:
```
git clone https://github.com/Perzach/mac-setup.git ~/workspace/mac-setup
~/workspace/mac-setup/setup.sh
```

3. Update default profile in iTerm2
* Iterm2 - Settings -> Profiles -> Select "My Profile" and make it the default one

## Checklist afterwards
- Login to Apps (AppleId, Dashlane, Chrome, Spotify, VS Code)
- Change screensaver (Including idleTime and password prompt settings)
- Check github access (SSH access might need some tweaks)