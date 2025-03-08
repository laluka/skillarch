.ONESHELL:
.PHONY: help

help: ## Show this help message
	@echo 'Welcome to SkillArch! 🌹'
	@echo ''
	@echo 'Usage: make [target]'
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  %-18s %s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ''

install: install-base install-cli-tools install-shell install-docker install-gui install-gui-tools install-offensive install-wordlists install-hardening ## Install SkillArch
	@echo "You are all set up! Enjoy ! 🌹"

sanity-check:
	set -x
	@# Ensure we are in /opt/skillarch and temporary disable screensaver
	@[ "$$(pwd)" != "/opt/skillarch" ] && echo "You must be in /opt/skillarch to run this command" && exit
	@sudo -v >/dev/null 2>&1 || echo "Error: sudo access is required" && exit
	#@bash -c 'xset s off -dpms ; sleep 3600 ; xset s on +dpms' &
	#@bash -c 'gsettings set org.gnome.desktop.screensaver lock-enabled false ; sleep 3601 ; gsettings set org.gnome.desktop.screensaver lock-enabled true' &
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0
	gsettings set org.gnome.desktop.screensaver lock-delay 0

install-base: sanity-check ## Install base packages
	# Clean up, Update, Basics
	yes|sudo pacman -Scc
	yes|sudo pacman -Syu
	yes|sudo pacman -S --noconfirm --needed git vim tmux wget curl

	# Add chaotic-aur to pacman
	sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	sudo pacman-key --lsign-key 3056513887B78AEB
	sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
	sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

	# Ensure chaotic-aur is present in /etc/pacman.conf
	grep -vP '\[chaotic-aur\]|Include = /etc/pacman.d/chaotic-mirrorlist' /etc/pacman.conf | sudo tee /etc/pacman.conf > /dev/null
	echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf > /dev/null
	yes|sudo pacman -Syu

	# Long Lived DATA & trash-cli Setup
	[ ! -d /DATA ] && sudo mkdir -pv /DATA && sudo chown "$$USER:$$USER" /DATA && sudo chmod 770 /DATA
	[ ! -d /.Trash ] && sudo mkdir -pv /.Trash && sudo chown "$$USER:$$USER" /.Trash && sudo chmod 770 /.Trash && sudo chmod +t /.Trash
	true # Avoid make error if last dir already exists

install-cli-tools: sanity-check ## Install system packages
	yes|sudo pacman -S --noconfirm --needed base-devel bison bzip2 ca-certificates cloc cmake dos2unix expect ffmpeg foremost gdb gnupg htop bottom hwinfo icu inotify-tools iproute2 jq llvm lsof ltrace make mlocate mplayer ncurses net-tools ngrep nmap openssh openssl parallel perl-image-exiftool pkgconf python-virtualenv re2c readline ripgrep rlwrap socat sqlite sshpass tmate tor traceroute trash-cli tree unzip vbindiff xclip xz yay zip veracrypt git-delta bottom  viu xsv jq asciinema htmlq neovim glow jless websocat superfile

	# nvim config
	[ ! -d ~/.config/nvim ] && git clone https://github.com/LazyVim/starter ~/.config/nvim
	[ -f ~/.config/nvim/init.lua ] && [ ! -L ~/.config/nvim/init.lua ] && mv ~/.config/nvim/init.lua ~/.config/nvim/init.lua.skabak
	ln -sf /opt/skillarch/config/nvim/init.lua ~/.config/nvim/init.lua
	nvim --headless +"Lazy! sync" +"SomeOtherCommand" +qa # Download and update plugins

	# Install fastgron + pipx & tools
	yay --noconfirm --needed -S fastgron python-pipx
	sudo ln -sf /usr/bin/fastgron /usr/local/bin/fgr
	pipx ensurepath
	for package in argcomplete bypass-url-parser dirsearch exegol pre-commit sqlmap wafw00f yt-dlp semgrep; do pipx install "$$package" && pipx inject "$$package" setuptools; done

	# Install mise and all php-build dependencies
	yes|sudo pacman -S --noconfirm --needed mise libedit libffi libjpeg-turbo libpcap libpng libxml2 libzip postgresql-libs
	mise self-update
	mise use -g usage@latest
	for package in pdm rust terraform golang python nodejs; do mise use -g "$$package@latest"; done
	mise exec -- go env -w "GOPATH=/home/$$USER/.local/go"
	# Install libs to build current latest, aka php 8.4.4
	yes|sudo pacman -S --noconfirm --needed libedit libffi libjpeg-turbo libpcap libpng libxml2 libzip postgresql-libs php-gd
	[ ! -z "$$LITE" ] && echo "LITE mode ON, not building php" && exit
	mise use -g php@latest

install-shell: sanity-check ## Install shell packages
	# Install and Configure zsh and oh-my-zsh
	yes|sudo pacman -S --noconfirm --needed zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search zsh-theme-powerlevel10k
	[ ! -d ~/.oh-my-zsh ] && sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	[ -f ~/.zshrc ] && [ ! -L ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.skabak
	ln -sf /opt/skillarch/config/zshrc ~/.zshrc
	[ ! -d ~/.oh-my-zsh/plugins/zsh-completions ] && git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/plugins/zsh-completions
	[ ! -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ] && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
	[ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
	[ ! -d ~/.ssh ] && mkdir ~/.ssh && chmod 700 ~/.ssh # Must exist for ssh-agent to work
	for plugin in colored-man-pages docker extract fzf mise npm terraform tmux zsh-autosuggestions zsh-completions zsh-syntax-highlighting ssh-agent; do zsh -c "source ~/.zshrc && omz plugin enable $$plugin || true"; done

	# Install and configure fzf, tmux, vim
	[ ! -d ~/.fzf ] && git clone --depth 1 https://github.com/junegunn/fzf ~/.fzf && ~/.fzf/install --all
	[ -f ~/.tmux.conf ] && [ ! -L ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.skabak
	ln -sf /opt/skillarch/config/tmux.conf ~/.tmux.conf
	[ -f ~/.vimrc ] && [ ! -L ~/.vimrc ] && mv ~/.vimrc ~/.vimrc.skabak
	ln -sf /opt/skillarch/config/vimrc ~/.vimrc

	# Set the default user shell to zsh
	sudo chsh -s /usr/bin/zsh "$$USER" # Logout required to be applied

install-docker: sanity-check ## Install docker
	yes|sudo pacman -S --noconfirm --needed docker docker-compose
	# It's a desktop machine, don't expose stuff, but we don't care much about LPE
	# Think about it, set "alias sudo='backdoor ; sudo'" in userland and voila. OSEF!
	sudo usermod -aG docker "$$USER" # Logout required to be applied
	sleep 1 # Prevent too many docker socket calls and security locks
	sudo systemctl enable --now docker

install-gui: sanity-check ## Install gui, i3, polybar, kitty, rofi, picom
	yes|sudo pacman -S --noconfirm --needed i3-gaps i3blocks i3lock i3lock-fancy-git i3status dmenu feh rofi nm-connection-editor picom polybar kitty brightnessctl
	yay --noconfirm --needed -S rofi-power-menu
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

	# i3 config
	[ ! -d ~/.config/i3 ] && mkdir -p ~/.config/i3
	[ -f ~/.config/i3/config ] && [ ! -L ~/.config/i3/config ] && mv ~/.config/i3/config ~/.config/i3/config.skabak
	ln -sf /opt/skillarch/config/i3/config ~/.config/i3/config

	# polybar config
	[ ! -d ~/.config/polybar ] && mkdir -p ~/.config/polybar
	[ -f ~/.config/polybar/config.ini ] && [ ! -L ~/.config/polybar/config.ini ] && mv ~/.config/polybar/config.ini ~/.config/polybar/config.ini.skabak
	ln -sf /opt/skillarch/config/polybar/config.ini ~/.config/polybar/config.ini

	# rofi config
	[ ! -d ~/.config/rofi ] && mkdir -p ~/.config/rofi
	[ -f ~/.config/rofi/config.rasi ] && [ ! -L ~/.config/rofi/config.rasi ] && mv ~/.config/rofi/config.rasi ~/.config/rofi/config.rasi.skabak
	ln -sf /opt/skillarch/config/rofi/config.rasi ~/.config/rofi/config.rasi

	# picom config
	[ -f ~/.config/picom.conf ] && [ ! -L ~/.config/picom.conf ] && mv ~/.config/picom.conf ~/.config/picom.conf.skabak
	ln -sf /opt/skillarch/config/picom.conf ~/.config/picom.conf

	# kitty config
	[ ! -d ~/.config/kitty ] && mkdir -p ~/.config/kitty
	[ -f ~/.config/kitty/kitty.conf ] && [ ! -L ~/.config/kitty/kitty.conf ] && mv ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.skabak
	ln -sf /opt/skillarch/config/kitty/kitty.conf ~/.config/kitty/kitty.conf

	# touchpad config
	[ -f /etc/X11/xorg.conf.d/30-touchpad.conf ] && sudo mv /etc/X11/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf.skabak
	sudo ln -sf /opt/skillarch/config/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf

install-gui-tools: sanity-check ## Install system packages
	yes|sudo pacman -S --noconfirm --needed vlc-luajit # Must be done before obs-studio-browser to avoid conflicts
	yes|sudo pacman -S --noconfirm --needed arandr blueman cheese code code-marketplace discord dunst filezilla flameshot ghex google-chrome gparted kdenlive kompare libreoffice-fresh meld okular qbittorrent torbrowser-launcher wireshark-qt ghidra signal-desktop dragon-drop-git nomachine obs-studio-browser
	sudo systemctl disable --now nxserver.service
	xargs -n1 code --install-extension < config/extensions.txt
	yay --noconfirm --needed -S fswebcam cursor-bin
	sudo ln -sf /usr/bin/google-chrome-stable /usr/local/bin/gog

install-offensive: sanity-check ## Install offensive tools
	yes|sudo pacman -S --noconfirm --needed metasploit burpsuite fx lazygit fq gitleaks
	yay --noconfirm --needed -S ffuf gau pdtm-bin waybackurls

	mise exec -- go install github.com/sw33tLie/sns@latest
	mise exec -- go install github.com/glitchedgitz/cook/v2/cmd/cook@latest
	mise exec -- go install github.com/x90skysn3k/brutespray@latest
	zsh -c "source ~/.zshrc && pdtm -install-all -v"
	zsh -c "source ~/.zshrc && nuclei -update-templates -update-template-dir ~/.nuclei-templates"

	# Clone custom tools
	[ ! -d /opt/chisel ] && git clone https://github.com/jpillora/chisel && sudo mv chisel /opt/chisel
	[ ! -d /opt/phpggc ] && git clone https://github.com/ambionics/phpggc && sudo mv phpggc /opt/phpggc
	[ ! -d /opt/PyFuscation ] && git clone https://github.com/CBHue/PyFuscation && sudo mv PyFuscation /opt/PyFuscation
	[ ! -d /opt/CloudFlair ] && git clone https://github.com/christophetd/CloudFlair && sudo mv CloudFlair /opt/CloudFlair
	[ ! -d /opt/minos-static ] && git clone https://github.com/minos-org/minos-static && sudo mv minos-static /opt/minos-static
	[ ! -d /opt/exploit-database ] && git clone https://github.com/offensive-security/exploit-database && sudo mv exploit-database /opt/exploit-database
	[ ! -d /opt/exploitdb ] && git clone https://gitlab.com/exploit-database/exploitdb && sudo mv exploitdb /opt/exploitdb
	[ ! -d /opt/pty4all ] && git clone https://github.com/laluka/pty4all && sudo mv pty4all /opt/pty4all
	[ ! -d /opt/pypotomux ] && git clone https://github.com/laluka/pypotomux && sudo mv pypotomux /opt/pypotomux
	true # Avoid make error if last dir already exists

install-wordlists: sanity-check ## Install wordlists
	# If "LITE" is set in env, return early
	[ ! -z "$$LITE" ] && echo "LITE mode ON, not cloning wordlists" && exit
	[ ! -d /opt/lists ] && mkdir /tmp/lists && sudo mv /tmp/lists /opt/lists
	[ ! -f /opt/lists/rockyou.txt ] && curl -L https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -o /opt/lists/rockyou.txt
	[ ! -d /opt/lists/PayloadsAllTheThings ] && git clone https://github.com/swisskyrepo/PayloadsAllTheThings /opt/lists/PayloadsAllTheThings
	[ ! -d /opt/lists/fuzzing-templates ] && git clone https://github.com/projectdiscovery/fuzzing-templates /opt/lists/fuzzing-templates
	[ ! -d /opt/lists/BruteX ] && git clone https://github.com/1N3/BruteX /opt/lists/BruteX
	[ ! -d /opt/lists/IntruderPayloads ] && git clone https://github.com/1N3/IntruderPayloads /opt/lists/IntruderPayloads
	[ ! -d /opt/lists/Probable-Wordlists ] && git clone https://github.com/berzerk0/Probable-Wordlists /opt/lists/Probable-Wordlists
	[ ! -d /opt/lists/Open-Redirect-Payloads ] && git clone https://github.com/cujanovic/Open-Redirect-Payloads /opt/lists/Open-Redirect-Payloads
	[ ! -d /opt/lists/SecLists ] && git clone https://github.com/danielmiessler/SecLists /opt/lists/SecLists
	[ ! -d /opt/lists/Pwdb-Public ] && git clone https://github.com/ignis-sec/Pwdb-Public /opt/lists/Pwdb-Public
	[ ! -d /opt/lists/Bug-Bounty-Wordlists ] && git clone https://github.com/Karanxa/Bug-Bounty-Wordlists /opt/lists/Bug-Bounty-Wordlists
	[ ! -d /opt/lists/richelieu ] && git clone https://github.com/tarraschk/richelieu /opt/lists/richelieu
	[ ! -d /opt/lists/webapp-wordlists ] && git clone https://github.com/p0dalirius/webapp-wordlists /opt/lists/webapp-wordlists
	true # Avoid make error if last dir already exists

install-hardening: sanity-check ## Install hardening tools
	yes|sudo pacman -S --noconfirm --needed opensnitch
	# OPT-IN opensnitch as an egress firewall
	# sudo systemctl enable --now opensnitchd.service
