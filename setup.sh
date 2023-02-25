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
		read -rs "gh_token?${YELLOW}Enter token:${RESET} " # TODO: Does not work
		
		mkdir -p ~/.zsh
		echo "export HOMEBREW_GITHUB_API_TOKEN=${gh_token}" >> ~/.zsh/.zshrc.user
		# Make sure .zshrc.user is only user readable
		chmod 600 ~/.zsh/.zshrc.user
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

install_non_brew_default_tools() {
    step "Installing non-brew default tools"
    
	step "Installing kinesis-console-consumer"
	npm install -g kinesis-console-consumer

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
	cp -ivL ~/.zsh/.p10k.zsh $MAC_SETUP_DIR/backup/.p10k.zsh.old
	cp -ivL ~/.zsh/.zshrc $MAC_SETUP_DIR/backup/.zshrc.old
	cp -ivL ~/.zsh/.zshenv $MAC_SETUP_DIR/backup/.zshenv.old

	step "Adding symlinks to dot files"
	cp -ivL $MAC_SETUP_DIR/lib/dotfiles/.gitconfig ~/.gitconfig
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/.zshenv ~/.zshenv
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/zsh/.p10k.zsh ~/.zsh/.p10k.zsh
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/zsh/.zshrc ~/.zsh/.zshrc
	ln -sfnv $MAC_SETUP_DIR/lib/dotfiles/zsh/.zshenv ~/.zsh/.zshenv

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
	path="$HOME/.ssh/id_ecdsa_github.pub"
	if [ ! -f "$path" ]; then
		step "Generating SSH key for github"

		printf "Insert identifier for ssh key: "
		read ssh_identifier
		ssh-keygen -t ecdsa -b 521 -f ~/.ssh/id_ecdsa_github -C "${ssh_identifier}"
		cat ~/.ssh/id_ecdsa_github.pub | pbcopy
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


# set_zsh_profile(){
#     step "Set zsh profile"

#     cp $MAC_SETUP_DIR/iterm2/Profiles.json $HOME/Library/Application\ Support/iTerm2/DynamicProfiles

#     printf "Remove: \n- ⌥←\n- ⌥→\n- ⌘←\n- ⌘←\n- ⌘←Delete\n- ⌥←Delete\nIn:\n"
# 	printf " - Iterm2 > Preferences > Keys > Key Bindings"
#     printf " - Iterm2 > Preferences > Keys > Profiles > Default > Keys"
#     pause
# 	finish
# }

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

	# if [[ "$CPU_ARCH" == "arm" ]]; then
	# 	_fetch_custom_binaries
	# 	python3 -m http.server 47285 --directory $CUSTOM_BINARIES_FOLDER &
	# 	local http_server_pid=$!
	# 	echo "http_server_pid : ${http_server_pid}"
	# 	TFENV_ARCH=arm64 TFENV_REMOTE=http://localhost:47285 tfenv install 0.15.5
	# 	TFENV_ARCH=arm64 TFENV_REMOTE=http://localhost:47285 tfenv install 0.14.11
	# 	TFENV_ARCH=arm64 TFENV_REMOTE=http://localhost:47285 tfenv install 0.13.7
	# 	kill -s SIGINT ${http_server_pid}
	# else 
	# 	tfenv install 0.15.5
	# 	tfenv install 0.14.11
	# 	tfenv install 0.13.7
	# fi
	# _configure-terraform-if-needed
	
	tfenv use 1.1.4

	finish
}


# function _configure-terraform-if-needed() {
#     [[ ! -f "~/.terraformrc" ]] && printf 'plugin_cache_dir   = "$HOME/.terraform.d/plugin-cache"\ndisable_checkpoint = true\n' > ~/.terraformrc && mkdir -p $HOME/.terraform.d/plugin-cache
#     if [[ "$CPU_ARCH" == "arm" ]]; then
#       _fetch_custom_binaries
#       # install locally template module
#       mkdir -p ~/.terraform.d/plugins/registry.terraform.io/hashicorp/template/2.2.0/darwin_arm64/terraform-provider-template
#       cp $CUSTOM_BINARIES_FOLDER/terraform-providers/terraform-provider-template/2.2.0/terraform-provider-template_v2.2.0_x5 \
#           ~/.terraform.d/plugins/registry.terraform.io/hashicorp/template/2.2.0/darwin_arm64/
#       chmod +x ~/.terraform.d/plugins/registry.terraform.io/hashicorp/template/2.2.0/darwin_arm64/terraform-provider-template_v2.2.0_x5

#       mkdir -p  ~/.terraform.d/plugins/registry.terraform.io/paloaltonetworks/prismacloud/1.1.10/darwin_arm64
#       cp  $CUSTOM_BINARIES_FOLDER/terraform-providers/terraform-provider-prismacloud/1.1.10/terraform-provider-prismacloud_v1.1.10 \
#           ~/.terraform.d/plugins/registry.terraform.io/paloaltonetworks/prismacloud/1.1.10/darwin_arm64/terraform-provider-prismacloud_v1.1.10
#       chmod +x ~/.terraform.d/plugins/registry.terraform.io/paloaltonetworks/prismacloud/1.1.10/darwin_arm64/terraform-provider-prismacloud_v1.1.10
#     fi
# }

# function _fetch_custom_binaries(){
#   mkdir -p $CUSTOM_BINARIES_FOLDER
#   if [[ "$CPU_ARCH" == "arm" ]]; then
#     echo "Moving custom binaries from iCloud Drive to .custom-binaries"
#     echo "Press <ENTER> to continue"
#     read
#     cp -R /Users/per-oystein/Library/Mobile\ Documents/com\~apple\~CloudDocs/Brukermappe/Diverse/Ny\ Maskin/binaries/ $CUSTOM_BINARIES_FOLDER/
#   fi
# }


homebrew
#setup_homebrew_github_token # Not working at the moment
brew_bundle
install_non_brew_default_tools
install_zsh
#config_macos ## TODO: Go over these
install_zsh_plugins
install_fonts
dotfiles
configure_github
#set_zsh_profile
setup_nvm
setup_jenv
setup_tfenv
zsh
