#!/bin/sh

MAC_SETUP_DIR="$HOME/workspace/mac-setup"
source $MAC_SETUP_DIR/lib/print.sh

pause(){
	echo 
	read -p "Press [Enter] key to continue... " fackEnterKey
	echo
}

homebrew(){
	step "Checking Homebrew"
	if [[ ! -f "/opt/homebrew/bin/brew" ]]
	then
		step "Installing..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
		export PATH=${HOME}/bin:/opt/homebrew/bin:${PATH}
	fi

	step "Homebrew is installed!"

	finish
}

setup_homebrew_github_token(){
	step "Checking Homebrew github token"
  
	local gh_token
	local existing_shell_session_disable=$SHELL_SESSIONS_DISABLE
	export SHELL_SESSIONS_DISABLE=1

	if [[ -z "$HOMEBREW_GITHUB_API_TOKEN" ]]
	then
		step "Creating a GitHub token to use with Homebrew, "
		message "When you press <ENTER> the default web browser will open to your GitHub developer token management"
		message "page. Please click 'Generate token' and input it at the prompt that will appear below"
		message
		message "Make sure to choose \"No expiration\" for expiration unless you want to redo this process every so often."
		
		pause
		
		open "https://github.com/settings/tokens/new?description=homebrew&scopes=repo" # creates token with correct permissions
		message "Enter github token, then press <ENTER>: "
		read -s gh_token
		
		echo "export HOMEBREW_GITHUB_API_TOKEN=${gh_token}" >> ~/.zshrc.user
		# Make sure .zshrc.user is only user readable
		chmod 600 ~/.zshrc.user
		export HOMEBREW_GITHUB_API_TOKEN=${gh_token}
	fi

	export SHELL_SESSIONS_DISABLE=${existing_shell_session_disable}

	finish

}

brew_bundle(){
	step "Installing Homebrew bundle"
	
	brew update # Make sure we have pulled the latest index files from the taps
	brew bundle -v --no-lock --file="$MAC_SETUP_DIR/Brewfile"

	# Install session manager plugin separatly due to
	# https://github.com/Homebrew/homebrew-cask/issues/90637
	brew install session-manager-plugin --no-quarantine

	rehash # make sure the command table is updated with everything installed

	finish
}

install_global_npm_tools() {
    step "Installing non-brew default tools"
    
	step "Installing kinesis-console-consumer"
	npm install -g kinesis-console-consumer

	finish
}

install_app_store_tools() {
	step "Installing AppStore tools"
	message "You may be asked to login with your AppleId"

	step "Installing Caffeinated"
	mas install 1362171212

	step "Installing PasteBot"
	mas install 1179623856

	finish
}

config_macos(){
	step "Tweaking macOS config settings (may take a while)"
	"$MAC_SETUP_DIR/lib/macos.sh"

	finish
}

install_zsh(){
	step "Installing zsh"
	brew list zsh || brew install zsh

	step "Changing shell to zsh"
	"$MAC_SETUP_DIR/lib/shell.sh"

	if [[ -d "$HOME/.oh-my-zsh" ]]; then
		step "oh my zsh already installed"
	else 
		step "Installing oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	fi

	step "zsh setup complete!"

	finish
}

install_zsh_plugins(){
	step "Installing Custom zsh plugins"

	if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
		step "powerlevel10k already installed"
	else 
		step "installing powerlevel10k zsh custom theme" 
		git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
	fi 

	if [ -d "$HOME/.oh-my-zsh/custom/plugins/autoupdate" ]; then
		step "autoupdate already installed"
	else 
		step "installing autoupdate"
		git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git ~/.oh-my-zsh/custom/plugins/autoupdate
	fi 

	if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
		step "zsh-autosuggestions already installed"
	else 
		step "installing zsh-autosuggestions"
		git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	fi 

	if [ -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
		step "fast-syntax-highlighting already installed"
	else 
		step "installing fast-syntax-highlighting"
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
	fi 

	if [ -d "$HOME/.oh-my-zsh/custom/plugins/alias-tips" ]; then
		step "alias-tips already installed"
	else 
		step "installing alias-tips" 
		git clone https://github.com/djui/alias-tips.git ~/.oh-my-zsh/custom/plugins/alias-tips
	fi

	finish
}

install_fonts() {
	step "Installing fonts"
	cp "${MAC_SETUP_DIR}/fonts/"*.ttf ~/Library/Fonts/
	finish
}

dotfiles(){
	step "Backing up existing dot files"
	mkdir -p $MAC_SETUP_DIR/backup
	cp -ivL ~/.gitconfig $MAC_SETUP_DIR/backup/.gitconfig.old
	cp -ivL ~/.p10k.zsh $MAC_SETUP_DIR/backup/.p10k.zsh.old
	cp -ivL ~/.zshrc $MAC_SETUP_DIR/backup/.zshrc.old
	cp -ivL ~/.zshlocal $MAC_SETUP_DIR/backup/.zshlocal.old

	step "Adding symlinks to dot files"
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/.gitconfig ~/.gitconfig
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/.p10k.zsh ~/.p10k.zsh
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/.zshrc ~/.zshrc
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/.zshlocal ~/.zshlocal

	step "Remove backups with 'rm -ir $MAC_SETUP_DIR/backup.*.old'"

	finish
}


configure_github(){
	step "Configuring github"

	step "Setting up git email"
	if [ -z "$(git config user.email)" ]; then
		printf "Insert git email: "
		read git_email
		git config --global user.email "${git_email}"
	fi

	step "Verifying ssh key in path: $path"
	path="$HOME/.ssh/id_ecdsa.pub"
	if [ ! -f "$path" ]; then
		step "Generating SSH key for github"

		printf "Insert identifier for ssh key: "
		read ssh_identifier
		ssh-keygen -t ecdsa -b 521 -f ~/.ssh/id_ecdsa
		cat ~/.ssh/id_ecdsa.pub | pbcopy
        step "Copied public key, paste it to GitHub"
        open https://github.com/settings/keys
        pause
	else
		step "ssh key already exists"
		step "skipping..."
	fi
	step "Adding the SSH key to the agent now to avoid multiple prompts"
	if ! ssh-add -L -q > /dev/null ; then
		ssh-add
		ssh -T git@github.com
	fi

	finish
}


setup_zsh_profile(){
    step "Setup zsh profile"
	open /Applications/iTerm.app
    cp $MAC_SETUP_DIR/iterm2/Profiles.json $HOME/Library/Application\ Support/iTerm2/DynamicProfiles

	finish
}

setup_nvm() {
    step "Set up nvm"

	brew uninstall --ignore-dependencies node
	brew uninstall --force node
	mkdir -p ~/.nvm
	export NVM_DIR=~/.nvm
	source $(brew --prefix nvm)/nvm.sh
	nvm install 16
	nvm use 16

	finish
}

setup_jenv() {
    step "Set up jenv"

	eval "$(jenv init -)"
	asdf plugin-add java 2>/dev/null

	jenv enable-plugin maven
	jenv enable-plugin gradle

	asdf install java corretto-8.362.08.1
	asdf install java corretto-11.0.17.8.1

	arch
	jenv add $HOME/.asdf/installs/java/corretto-11.0.17.8.1/
	jenv add $HOME/.asdf/installs/java/corretto-8.362.08.1/

	finish
}


setup_tfenv() {
    step "Set up tfenv"
  
	tfenv install 1.1.4
	tfenv install 1.0.11
	tfenv use 1.1.4

	finish
}

homebrew
setup_homebrew_github_token
brew_bundle
install_global_npm_tools
install_app_store_tools
install_zsh
config_macos
install_zsh_plugins
install_fonts
dotfiles
configure_github
setup_zsh_profile
setup_nvm
setup_jenv
setup_tfenv
zsh
