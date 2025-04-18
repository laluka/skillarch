.ONESHELL:
.PHONY: help

help: ## Show this help message
	@echo 'Welcome to SkillArch! 🌹'
	@echo ''
	@echo 'Usage: make [target]'
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  %-18s %s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ''

install: install-base install-cli-tools install-shell install-docker install-gui install-gui-tools install-offensive install-wordlists install-hardening clean ## Install SkillArch
	@echo "You are all set up! Enjoy ! 🌹"

sanity-check:
	set -x
	@# Ensure we are in /opt/skillarch or /opt/skillarch-original (maintainer only)
	@[ "$$(pwd)" != "/opt/skillarch" ] && [ "$$(pwd)" != "/opt/skillarch-original" ] && echo "You must be in /opt/skillarch or /opt/skillarch-original to run this command" && exit 1
	@sudo id || (echo "Error: sudo access is required" ; exit 1)

install-base: sanity-check ## Install base packages
	# Clean up, Update, Basics
	sudo sed -e "s#.*ParallelDownloads.*#ParallelDownloads = 10#g" -i /etc/pacman.conf
	echo 'BUILDDIR="/dev/shm/makepkg"' | sudo tee /etc/makepkg.conf.d/00-skillarch.conf
	yes|sudo pacman -Scc
	yes|sudo pacman -Syu
	yes|sudo pacman -S --noconfirm --needed git vim tmux wget curl archlinux-keyring
	sudo pacman-key --populate archlinux
	sudo pacman-key --refresh-keys

	# Add chaotic-aur to pacman
	sudo pacman-key --add <(curl -sS "https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x3056513887B78AEB")
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
	make clean

install-cli-tools: sanity-check ## Install system packages
	yes|sudo pacman -S --noconfirm --needed base-devel bison bzip2 ca-certificates cloc cmake dos2unix expect ffmpeg foremost gdb gnupg htop bottom hwinfo icu inotify-tools iproute2 jq llvm lsof ltrace make mlocate mplayer ncurses net-tools ngrep nmap openssh openssl parallel perl-image-exiftool pkgconf python-virtualenv re2c readline ripgrep rlwrap socat gnu-netcat sqlite sshpass tmate tor traceroute trash-cli tree unzip vbindiff xclip xz yay zip veracrypt git-delta viu xsv asciinema htmlq neovim glow jless websocat superfile gron exa fastfetch bat sysstat cronie
	sudo ln -sf /usr/bin/bat /usr/local/bin/batcat
	bash -c "$$(curl -fsSL https://gef.blah.cat/sh)"
	missing_exa_lib=$$(ldd $$(which exa) | grep -ioP 'libgit2.*not found' | cut -d' ' -f 1)
	[ ! -z $$missing_exa_lib ] && sudo ln -s /usr/lib/libgit2.so  "/usr/lib/$$missing_exa_lib"
	# nvim config
	[ ! -d ~/.config/nvim ] && git clone --depth=1 https://github.com/LazyVim/starter ~/.config/nvim
	[ -f ~/.config/nvim/init.lua ] && [ ! -L ~/.config/nvim/init.lua ] && mv ~/.config/nvim/init.lua ~/.config/nvim/init.lua.skabak
	ln -sf /opt/skillarch/config/nvim/init.lua ~/.config/nvim/init.lua
	nvim --headless +"Lazy! sync" +qa >/dev/null # Download and update plugins

	# Install pipx & tools
	yay --noconfirm --needed -S python-pipx
	pipx ensurepath
	for package in argcomplete bypass-url-parser dirsearch exegol pre-commit sqlmap wafw00f yt-dlp semgrep; do pipx install -q "$$package" && pipx inject -q "$$package" setuptools; done

	# Install mise and all php-build dependencies
	yes|sudo pacman -S --noconfirm --needed mise libedit libffi libjpeg-turbo libpcap libpng libxml2 libzip postgresql-libs php-gd
	# mise self-update # Currently broken, wait for upstream fix, pinged on 17/03/2025
	sleep 30
	for package in usage pdm rust terraform golang python nodejs; do mise use -g "$$package@latest" ; sleep 10; done
	mise exec -- go env -w "GOPATH=/home/$$USER/.local/go"
	make clean

install-shell: sanity-check ## Install shell packages
	# Install and Configure zsh and oh-my-zsh
	yes|sudo pacman -S --noconfirm --needed zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search zsh-theme-powerlevel10k
	[ ! -d ~/.oh-my-zsh ] && sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	[ -f ~/.zshrc ] && [ ! -L ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.skabak
	ln -sf /opt/skillarch/config/zshrc ~/.zshrc
	[ ! -d ~/.oh-my-zsh/plugins/zsh-completions ] && git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/plugins/zsh-completions
	[ ! -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
	[ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
	[ ! -d ~/.ssh ] && mkdir ~/.ssh && chmod 700 ~/.ssh # Must exist for ssh-agent to work
	for plugin in colored-man-pages docker extract fzf mise npm terraform tmux zsh-autosuggestions zsh-completions zsh-syntax-highlighting ssh-agent; do zsh -c "source ~/.zshrc && omz plugin enable $$plugin || true"; done
	make clean

	# Install and configure fzf, tmux, vim
	[ ! -d ~/.fzf ] && git clone --depth=1 --depth 1 https://github.com/junegunn/fzf ~/.fzf && ~/.fzf/install --all
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
	# Do not start services in docker
	[ ! -f /.dockerenv ] && sudo systemctl enable --now docker
	make clean

install-gui: sanity-check ## Install gui, i3, polybar, kitty, rofi, picom
	[ ! -f /etc/machine-id ] && sudo systemd-machine-id-setup
	yes|sudo pacman -S --noconfirm --needed i3-gaps i3blocks i3lock i3lock-fancy-git i3status dmenu feh rofi nm-connection-editor picom polybar kitty brightnessctl xorg-xhost
	yay --noconfirm --needed -S rofi-power-menu i3-battery-popup-git
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

	# i3 config
	[ ! -d ~/.config/i3 ] && mkdir -p ~/.config/i3
	[ -f ~/.config/i3/config ] && [ ! -L ~/.config/i3/config ] && mv ~/.config/i3/config ~/.config/i3/config.skabak
	ln -sf /opt/skillarch/config/i3/config ~/.config/i3/config

	# polybar config
	[ ! -d ~/.config/polybar ] && mkdir -p ~/.config/polybar
	[ -f ~/.config/polybar/config.ini ] && [ ! -L ~/.config/polybar/config.ini ] && mv ~/.config/polybar/config.ini ~/.config/polybar/config.ini.skabak
	ln -sf /opt/skillarch/config/polybar/config.ini ~/.config/polybar/config.ini
	[ -f ~/.config/polybar/launch.sh ] && [ ! -L ~/.config/polybar/launch.sh ] && mv ~/.config/polybar/launch.sh ~/.config/polybar/launch.sh.skabak
	ln -sf /opt/skillarch/config/polybar/launch.sh ~/.config/polybar/launch.sh

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
	[ ! -d /etc/X11/xorg.conf.d ] && sudo mkdir -p /etc/X11/xorg.conf.d
	[ -f /etc/X11/xorg.conf.d/30-touchpad.conf ] && sudo mv /etc/X11/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf.skabak
	sudo ln -sf /opt/skillarch/config/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf
	make clean

install-gui-tools: sanity-check ## Install system packages
	yes|sudo pacman -S --noconfirm --needed vlc-luajit # Must be done before obs-studio-browser to avoid conflicts
	yes|sudo pacman -S --noconfirm --needed arandr blueman cheese code code-marketplace discord dunst filezilla flameshot ghex google-chrome gparted kdenlive kompare libreoffice-fresh meld okular qbittorrent torbrowser-launcher wireshark-qt ghidra signal-desktop dragon-drop-git nomachine obs-studio-browser emote guvcview audacity polkit-gnome
	# Do not start services in docker
	[ ! -f /.dockerenv ] && sudo systemctl disable --now nxserver.service
	xargs -n1 code --install-extension < config/extensions.txt
	yay --noconfirm --needed -S fswebcam cursor-bin
	sudo ln -sf /usr/bin/google-chrome-stable /usr/local/bin/gog
	make clean

install-offensive: sanity-check ## Install offensive tools
	yes|sudo pacman -S --noconfirm --needed metasploit fx lazygit fq gitleaks jdk21-openjdk burpsuite hashcat bettercap
	sudo sed -i 's#$JAVA_HOME#/usr/lib/jvm/java-21-openjdk#g' /usr/bin/burpsuite
	yay --noconfirm --needed -S ffuf gau pdtm-bin waybackurls fabric-ai-bin

	# Hide stdout and Keep stderr for CI builds
	mise exec -- go install github.com/sw33tLie/sns@latest > /dev/null
	mise exec -- go install github.com/glitchedgitz/cook/v2/cmd/cook@latest > /dev/null
	mise exec -- go install github.com/x90skysn3k/brutespray@latest > /dev/null
	mise exec -- go install github.com/sensepost/gowitness@latest > /dev/null
	sleep 30
	zsh -c "source ~/.zshrc && pdtm -install-all -v"
	zsh -c "source ~/.zshrc && nuclei -update-templates -update-template-dir ~/.nuclei-templates"

	# Clone custom tools
	pushd /tmp # Avoid git clone --depth=1 in root
	[ ! -d /opt/chisel ] && git clone --depth=1 https://github.com/jpillora/chisel && sudo mv chisel /opt/chisel
	[ ! -d /opt/phpggc ] && git clone --depth=1 https://github.com/ambionics/phpggc && sudo mv phpggc /opt/phpggc
	[ ! -d /opt/PyFuscation ] && git clone --depth=1 https://github.com/CBHue/PyFuscation && sudo mv PyFuscation /opt/PyFuscation
	[ ! -d /opt/CloudFlair ] && git clone --depth=1 https://github.com/christophetd/CloudFlair && sudo mv CloudFlair /opt/CloudFlair
	[ ! -d /opt/minos-static ] && git clone --depth=1 https://github.com/minos-org/minos-static && sudo mv minos-static /opt/minos-static
	[ ! -d /opt/exploit-database ] && git clone --depth=1 https://github.com/offensive-security/exploit-database && sudo mv exploit-database /opt/exploit-database
	[ ! -d /opt/exploitdb ] && git clone --depth=1 https://gitlab.com/exploit-database/exploitdb && sudo mv exploitdb /opt/exploitdb
	[ ! -d /opt/pty4all ] && git clone --depth=1 https://github.com/laluka/pty4all && sudo mv pty4all /opt/pty4all
	[ ! -d /opt/pypotomux ] && git clone --depth=1 https://github.com/laluka/pypotomux && sudo mv pypotomux /opt/pypotomux
	popd
	make clean

install-wordlists: sanity-check ## Install wordlists
	[ ! -d /opt/lists ] && mkdir /tmp/lists && sudo mv /tmp/lists /opt/lists
	[ ! -f /opt/lists/rockyou.txt ] && curl -L https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -o /opt/lists/rockyou.txt
	[ ! -d /opt/lists/PayloadsAllTheThings ] && git clone --depth=1 https://github.com/swisskyrepo/PayloadsAllTheThings /opt/lists/PayloadsAllTheThings
	[ ! -d /opt/lists/fuzzing-templates ] && git clone --depth=1 https://github.com/projectdiscovery/fuzzing-templates /opt/lists/fuzzing-templates
	[ ! -d /opt/lists/BruteX ] && git clone --depth=1 https://github.com/1N3/BruteX /opt/lists/BruteX
	[ ! -d /opt/lists/IntruderPayloads ] && git clone --depth=1 https://github.com/1N3/IntruderPayloads /opt/lists/IntruderPayloads
	[ ! -d /opt/lists/Probable-Wordlists ] && git clone --depth=1 https://github.com/berzerk0/Probable-Wordlists /opt/lists/Probable-Wordlists
	[ ! -d /opt/lists/Open-Redirect-Payloads ] && git clone --depth=1 https://github.com/cujanovic/Open-Redirect-Payloads /opt/lists/Open-Redirect-Payloads
	[ ! -d /opt/lists/SecLists ] && git clone --depth=1 https://github.com/danielmiessler/SecLists /opt/lists/SecLists
	[ ! -d /opt/lists/Pwdb-Public ] && git clone --depth=1 https://github.com/ignis-sec/Pwdb-Public /opt/lists/Pwdb-Public
	[ ! -d /opt/lists/Bug-Bounty-Wordlists ] && git clone --depth=1 https://github.com/Karanxa/Bug-Bounty-Wordlists /opt/lists/Bug-Bounty-Wordlists
	[ ! -d /opt/lists/richelieu ] && git clone --depth=1 https://github.com/tarraschk/richelieu /opt/lists/richelieu
	[ ! -d /opt/lists/webapp-wordlists ] && git clone --depth=1 https://github.com/p0dalirius/webapp-wordlists /opt/lists/webapp-wordlists
	make clean

install-hardening: sanity-check ## Install hardening tools
	yes|sudo pacman -S --noconfirm --needed opensnitch
	# OPT-IN opensnitch as an egress firewall
	# sudo systemctl enable --now opensnitchd.service
	make clean

update: sanity-check ## Update SkillArch
	@[ -n "$$(git status --porcelain)" ] && echo "Error: git state is dirty, please "git stash" your changes before updating" && exit 1
	@[ "$$(git rev-parse --abbrev-ref HEAD)" != "main" ] && echo "Error: current branch is not main, please switch to main before updating" && exit 1
	@git pull
	@echo "SkillArch updated, please run make install to apply changes 🙏"

docker-build:  ## Build lite docker image locally
	docker build -t thelaluka/skillarch:lite -f Dockerfile-lite .

docker-build-full: docker-build  ## Build full docker image locally
	docker build -t thelaluka/skillarch:full -f Dockerfile-full .

docker-run:  ## Run lite docker image locally
	sudo docker run --rm -it --name=ska --net=host -v /tmp:/tmp thelaluka/skillarch:lite

docker-run-full:  ## Run full docker image locally
	xhost +
	sudo docker run --rm -it --name=ska --net=host -v /tmp:/tmp -e DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix/ --privileged thelaluka/skillarch:full

clean: ## Clean up system and remove unnecessary files
	[ ! -f /.dockerenv ] && exit
	yes|sudo pacman -Scc
	yes|sudo pacman -Sc
	yes|sudo pacman -Rns $$(pacman -Qtdq) 2>/dev/null || true
	rm -rf ~/.cache/pip
	npm cache clean --force 2>/dev/null || true
	mise cache clear
	go clean -cache -modcache -i -r 2>/dev/null || true
	sudo rm -rf /var/cache/*
	rm -rf ~/.cache/*
	sudo rm -rf /tmp/*
	docker system prune -af 2>/dev/null || true
	sudo journalctl --vacuum-time=1d
	sudo find /var/log -type f -name "*.old" -delete
	sudo find /var/log -type f -name "*.gz" -delete
	sudo find /var/log -type f -exec truncate --size=0 {} \;
