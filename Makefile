.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -eu -c
.PHONY: help install sanity-check install-base install-cli-tools install-shell install-docker install-gui install-gui-tools install-offensive install-wordlists install-hardening update docker-build docker-build-full docker-run docker-run-full clean test test-lite test-full doctor list-tools backup

# -- Colors & UX Helpers --
C_RST  := \033[0m
C_OK   := \033[1;32m
C_INFO := \033[1;34m
C_WARN := \033[1;33m
C_ERR  := \033[1;31m
C_BOLD := \033[1m
SKA_LOG := /var/tmp/skillarch-install_$$(date +%Y%m%d_%H%M%S).log

STEP = @echo -e "$(C_BOLD)$(C_INFO)==>  [$(1)/$(2)]$(C_RST) $(C_INFO)$(3)...$(C_RST)"

define ska-link
	# Backup existing file (if not already a symlink) and create symlink
	[ -f $(2) ] && [ ! -L $(2) ] && mv $(2) $(2).skabak || true
	ln -sf $(1) $(2)
endef

PACMAN_INSTALL := sudo pacman -S --noconfirm --needed

help: ## Show this help message
	@echo 'Welcome to SkillArch! <3'
	echo ''
	echo 'Usage: make [target]'
	echo 'Targets:'
	awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  %-18s %s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	echo ''

install: ## Install SkillArch (full)
	echo "" > $(SKA_LOG)
	exec > >(tee -a $(SKA_LOG)) 2>&1
	curStep=1
	numSteps=9
	$(call STEP,$$((curStep++)),$$numSteps,Installing base packages)
	$(MAKE) install-base
	$(call STEP,$$((curStep++)),$$numSteps,Installing CLI tools & runtimes)
	$(MAKE) install-cli-tools
	$(call STEP,$$((curStep++)),$$numSteps,Installing shell & dotfiles)
	$(MAKE) install-shell
	$(call STEP,$$((curStep++)),$$numSteps,Installing Docker)
	$(MAKE) install-docker
	$(call STEP,$$((curStep++)),$$numSteps,Installing GUI & WM)
	$(MAKE) install-gui
	$(call STEP,$$((curStep++)),$$numSteps,Installing GUI applications)
	$(MAKE) install-gui-tools
	$(call STEP,$$((curStep++)),$$numSteps,Installing offensive tools)
	$(MAKE) install-offensive
	$(call STEP,$$((curStep++)),$$numSteps,Installing wordlists)
	$(MAKE) install-wordlists
	$(call STEP,$$((curStep++)),$$numSteps,Installing hardening tools)
	$(MAKE) install-hardening
	$(MAKE) clean
	$(MAKE) test
	echo -e "$(C_OK) You are all set up! Enjoy SkillArch! <3$(C_RST)"
	echo -e "$(C_INFO) Install log saved to $(SKA_LOG)$(C_RST)"

sanity-check:
	set -x
	# Ensure we are in /opt/skillarch or /opt/skillarch-original (maintainer only)
	[ "$$(pwd)" != "/opt/skillarch" ] && [ "$$(pwd)" != "/opt/skillarch-original" ] && echo "You must be in /opt/skillarch or /opt/skillarch-original to run this command" && exit 1 || true
	sudo -v || (echo "Error: sudo access is required" ; exit 1)
	[ ! -f /.dockerenv ] && { systemd-inhibit --what sleep:idle sleep 3600 & } || true

install-base: sanity-check ## Install base packages
	echo -e "$(C_INFO) Installing base packages...$(C_RST)"
	# Clean up, Update, Basics
	sudo sed -e "s#.*ParallelDownloads.*#ParallelDownloads = 10#g" -i /etc/pacman.conf
	echo 'BUILDDIR="/dev/shm/makepkg"' | sudo tee /etc/makepkg.conf.d/00-skillarch.conf
	[ ! -f /.dockerenv ] && sudo cachyos-rate-mirrors || true # Increase install speed & Update repos (skip in Docker)
	sudo pacman-key --init
	sudo pacman-key --populate archlinux cachyos
	sudo pacman --noconfirm -Scc
	sudo pacman --noconfirm -Syu
	$(PACMAN_INSTALL) git vim tmux wget curl archlinux-keyring
	# Re-populate after archlinux-keyring update to pick up any new packager keys
	sudo pacman-key --populate archlinux

	# Add chaotic-aur to pacman
	curl -sS "https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x3056513887B78AEB" | sudo pacman-key --add -
	sudo pacman-key --lsign-key 3056513887B78AEB
	sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
	sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

	# Ensure chaotic-aur is present in /etc/pacman.conf
	grep -vP '\[chaotic-aur\]|Include = /etc/pacman.d/chaotic-mirrorlist' /etc/pacman.conf | sudo tee /etc/pacman.conf > /dev/null
	echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf > /dev/null
	sudo pacman --noconfirm -Syu

	# Long Lived DATA & trash-cli Setup
	[ ! -d /DATA ] && sudo mkdir -pv /DATA && sudo chown "$$USER:$$USER" /DATA && sudo chmod 770 /DATA || true
	[ ! -d /.Trash ] && sudo mkdir -pv /.Trash && sudo chown "$$USER:$$USER" /.Trash && sudo chmod 770 /.Trash && sudo chmod +t /.Trash || true
	echo -e "$(C_OK) Base packages installed!$(C_RST)"

install-cli-tools: sanity-check ## Install CLI tools & runtimes
	echo -e "$(C_INFO) Installing CLI tools & runtimes...$(C_RST)"
	$(PACMAN_INSTALL) base-devel bison bzip2 ca-certificates cloc cmake dos2unix expect ffmpeg foremost gdb gnupg htop bottom hwinfo icu inotify-tools iproute2 jq llvm lsof ltrace make mlocate mplayer ncurses net-tools ngrep nmap openssh openssl parallel perl-image-exiftool pkgconf python-virtualenv re2c readline ripgrep rlwrap socat sqlite sshpass tmate tor traceroute trash-cli tree unzip vbindiff xclip xz yay zip veracrypt git-delta viu qsv asciinema htmlq neovim glow jless websocat superfile gron eza fastfetch bat sysstat cronie tree-sitter
	sudo ln -sf /usr/bin/bat /usr/local/bin/batcat
	bash -c "$$(curl -fsSL https://gef.blah.cat/sh)" || true
	[ ! -f ~/.gdbinit-gef.py ] && curl -fsSL -o ~/.gdbinit-gef.py https://raw.githubusercontent.com/hugsy/gef/main/gef.py && echo "source ~/.gdbinit-gef.py" >> ~/.gdbinit || echo "gef already installed"
	# nvim config
	[ ! -d ~/.config/nvim ] && git clone --depth=1 https://github.com/LazyVim/starter ~/.config/nvim || true
	$(call ska-link,/opt/skillarch/config/nvim/init.lua,$$HOME/.config/nvim/init.lua)
	nvim --headless +"Lazy! sync" +qa >/dev/null # Download and update plugins

	# Install pipx & tools
	yay --noconfirm --needed -S python-pipx
	pipx ensurepath
	for package in argcomplete bypass-url-parser dirsearch exegol pre-commit sqlmap wafw00f yt-dlp semgrep defaultcreds-cheat-sheet; do
		pipx install -q "$$package" && pipx inject -q "$$package" setuptools || {
			echo -e "$(C_WARN) Retrying $$package install...$(C_RST)"
			pipx uninstall "$$package" || true
			pipx install -q "$$package" && pipx inject -q "$$package" setuptools
		}
	done

	# Install mise and all php-build dependencies
	$(PACMAN_INSTALL) mise libedit libffi libjpeg-turbo libpcap libpng libxml2 libzip postgresql-libs php-gd
	# mise self-update # Currently broken, wait for upstream fix, pinged on 17/03/2025
	for package in usage pdm rust terraform golang python nodejs uv; do \
		for attempt in 1 2 3; do \
			mise use -g "$$package@latest" && break || { \
				echo -e "$(C_WARN) mise install $$package failed (attempt $$attempt/3), retrying in 5s...$(C_RST)" ; \
				sleep 5 ; \
			} ; \
		done ; \
	done
	mise exec -- go env -w "GOPATH=/home/$$USER/.local/go"
	echo -e "$(C_OK) CLI tools & runtimes installed!$(C_RST)"

install-shell: sanity-check ## Install shell, zsh, oh-my-zsh, fzf, tmux
	echo -e "$(C_INFO) Installing shell & dotfiles...$(C_RST)"
	# Install and Configure zsh and oh-my-zsh
	$(PACMAN_INSTALL) zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search zsh-theme-powerlevel10k
	[ ! -d ~/.oh-my-zsh ] && sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
	$(call ska-link,/opt/skillarch/config/zshrc,$$HOME/.zshrc)
	[ ! -d ~/.oh-my-zsh/plugins/zsh-completions ] && git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/plugins/zsh-completions || true
	[ ! -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions || true
	[ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting || true
	[ ! -d ~/.ssh ] && mkdir ~/.ssh && chmod 700 ~/.ssh || true # Must exist for ssh-agent to work
	for plugin in colored-man-pages docker extract fzf mise npm terraform tmux zsh-autosuggestions zsh-completions zsh-syntax-highlighting ssh-agent z ; do zsh -c "source ~/.zshrc && omz plugin enable $$plugin || true" || true; done

	# Install and configure fzf, tmux, vim
	[ ! -d ~/.fzf ] && git clone --depth=1 https://github.com/junegunn/fzf ~/.fzf && ~/.fzf/install --all || true
	$(call ska-link,/opt/skillarch/config/tmux.conf,$$HOME/.tmux.conf)
	$(call ska-link,/opt/skillarch/config/vimrc,$$HOME/.vimrc)
	# Set the default user shell to zsh
	sudo chsh -s /usr/bin/zsh "$$USER" # Logout required to be applied
	echo -e "$(C_OK) Shell & dotfiles installed!$(C_RST)"

install-docker: sanity-check ## Install Docker & Docker Compose
	echo -e "$(C_INFO) Installing Docker...$(C_RST)"
	$(PACMAN_INSTALL) docker docker-compose
	# It's a desktop machine, don't expose stuff, but we don't care much about LPE
	# Think about it, set "alias sudo='backdoor ; sudo'" in userland and voila. OSEF!
	sudo usermod -aG docker "$$USER" # Logout required to be applied
	sleep 1 # Prevent too many docker socket calls and security locks
	# Do not start services in docker
	[ ! -f /.dockerenv ] && sudo systemctl enable --now docker || true
	echo -e "$(C_OK) Docker installed!$(C_RST)"

install-gui: sanity-check ## Install i3, polybar, kitty, rofi, picom
	echo -e "$(C_INFO) Installing GUI & window manager...$(C_RST)"
	[ ! -f /etc/machine-id ] && sudo systemd-machine-id-setup || true
	$(PACMAN_INSTALL) xorg-server i3-gaps i3blocks i3lock i3lock-fancy-git i3status dmenu feh rofi nm-connection-editor picom polybar kitty brightnessctl xorg-xhost
	yay --noconfirm --needed -S rofi-power-menu i3-battery-popup-git
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

	# i3 config
	[ ! -d ~/.config/i3 ] && mkdir -p ~/.config/i3 || true
	$(call ska-link,/opt/skillarch/config/i3/config,$$HOME/.config/i3/config)

	# polybar config
	[ ! -d ~/.config/polybar ] && mkdir -p ~/.config/polybar || true
	$(call ska-link,/opt/skillarch/config/polybar/config.ini,$$HOME/.config/polybar/config.ini)
	$(call ska-link,/opt/skillarch/config/polybar/launch.sh,$$HOME/.config/polybar/launch.sh)

	# rofi config
	[ ! -d ~/.config/rofi ] && mkdir -p ~/.config/rofi || true
	$(call ska-link,/opt/skillarch/config/rofi/config.rasi,$$HOME/.config/rofi/config.rasi)

	# picom config
	$(call ska-link,/opt/skillarch/config/picom.conf,$$HOME/.config/picom.conf)

	# kitty config
	[ ! -d ~/.config/kitty ] && mkdir -p ~/.config/kitty || true
	$(call ska-link,/opt/skillarch/config/kitty/kitty.conf,$$HOME/.config/kitty/kitty.conf)

	# touchpad config
	[ ! -d /etc/X11/xorg.conf.d ] && sudo mkdir -p /etc/X11/xorg.conf.d || true
	[ -f /etc/X11/xorg.conf.d/30-touchpad.conf ] && sudo mv /etc/X11/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf.skabak || true
	sudo ln -sf /opt/skillarch/config/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf
	echo -e "$(C_OK) GUI & window manager installed!$(C_RST)"

install-gui-tools: sanity-check ## Install GUI apps (Chrome, VSCode, Ghidra, etc.)
	echo -e "$(C_INFO) Installing GUI applications...$(C_RST)"
	# Pre-create flatpak repo dir so post-install hooks don't fail in Docker (flatpak may be pulled as a dependency)
	[ -f /.dockerenv ] && sudo mkdir -p /var/lib/flatpak/repo || true
	$(PACMAN_INSTALL) vlc vlc-plugin-ffmpeg arandr blueman visual-studio-code-bin discord dunst filezilla flameshot ghex google-chrome gparted kdenlive kompare libreoffice-fresh meld okular qbittorrent torbrowser-launcher wireshark-qt ghidra signal-desktop dragon-drop-git nomachine emote guvcview audacity polkit-gnome
	[ ! -f /.dockerenv ] && $(PACMAN_INSTALL) flatpak && flatpak install -y flathub com.obsproject.Studio && flatpak install -y flathub org.gnome.Snapshot || true
	# Do not start services in docker
	[ ! -f /.dockerenv ] && sudo systemctl disable --now nxserver.service || true
	xargs -n1 -I{} code --install-extension {} --force < config/extensions.txt
	for pkg in fswebcam cursor-bin; do yay --noconfirm --needed -S "$$pkg" || echo -e "$(C_WARN) Failed to install $$pkg, continuing...$(C_RST)"; done
	sudo ln -sf /usr/bin/google-chrome-stable /usr/local/bin/gog
	echo -e "$(C_OK) GUI applications installed!$(C_RST)"

install-offensive: sanity-check ## Install offensive & security tools
	echo -e "$(C_INFO) Installing offensive tools...$(C_RST)"
	$(PACMAN_INSTALL) metasploit fx lazygit fq gitleaks jdk21-openjdk burpsuite hashcat bettercap
	sudo sed -i 's#$$JAVA_HOME#/usr/lib/jvm/java-21-openjdk#g' /usr/bin/burpsuite
	for pkg in ffuf gau pdtm-bin waybackurls fabric-ai-bin; do yay --noconfirm --needed -S "$$pkg" || echo -e "$(C_WARN) Failed to install $$pkg, continuing...$(C_RST)"; done
	[ -f /usr/bin/pdtm ] && { mkdir -p ~/.pdtm/go/bin; sudo chown "$$USER:$$USER" /usr/bin/pdtm; sudo mv /usr/bin/pdtm ~/.pdtm/go/bin; ~/.pdtm/go/bin/pdtm -u pdtm; } || true

	# Hide stdout and Keep stderr for CI builds -- run go installs in parallel
	mise exec -- go install github.com/sw33tLie/sns@latest > /dev/null &
	mise exec -- go install github.com/glitchedgitz/cook/v2/cmd/cook@latest > /dev/null &
	mise exec -- go install github.com/x90skysn3k/brutespray@latest > /dev/null &
	mise exec -- go install github.com/sensepost/gowitness@latest > /dev/null &
	wait

	# Install GitHub binary releases -- gobypass403 & wpprobe (sequential to save API budget for pdtm)
	( wget -q "$$(curl -sL https://api.github.com/repos/slicingmelon/gobypass403/releases/latest | jq -r '.assets[] | select(.name | contains("linux_amd64")) | .browser_download_url')" -O /tmp/gobypass403 \
		&& chmod +x /tmp/gobypass403 && sudo mv /tmp/gobypass403 /usr/local/bin/gobypass403 ) || true
	( wget -q "$$(curl -sL https://api.github.com/repos/Chocapikk/wpprobe/releases/latest | jq -r '.assets[] | select(.name | test("linux_amd64")) | .browser_download_url')" -O /tmp/wpprobe \
		&& chmod +x /tmp/wpprobe && sudo mv /tmp/wpprobe /usr/local/bin/wpprobe \
		&& wpprobe update-db ) || true

	# pdtm hits GitHub API rate limits (60 req/h unauthenticated) -- retry after reset (~4min)
	for attempt in 1 2 3 4 5; do \
		zsh -c "source ~/.zshrc && pdtm -install-all -v" && break || { \
			echo -e "$(C_WARN) pdtm install failed (attempt $$attempt/5), likely rate-limited. Waiting 4m for reset...$(C_RST)" ; \
			sleep 240 ; \
		} ; \
	done || true
	zsh -c "source ~/.zshrc && nuclei -update-templates -update-template-dir ~/.nuclei-templates" || true
	rm -rf /tmp/nuclei[0-9]*

	# Clone custom tools -- run in parallel
	ska_clone() { local pkg=$${1##*/}; [[ ! -d "/opt/$$pkg" ]] && git clone --depth=1 "$$1" "/tmp/$$pkg" && sudo mv "/tmp/$$pkg" "/opt/$$pkg" || true ; }
	ska_clone https://github.com/jpillora/chisel &
	ska_clone https://github.com/ambionics/phpggc &
	ska_clone https://github.com/CBHue/PyFuscation &
	ska_clone https://github.com/christophetd/CloudFlair &
	ska_clone https://github.com/minos-org/minos-static &
	ska_clone https://github.com/offensive-security/exploit-database &
	ska_clone https://gitlab.com/exploit-database/exploitdb &
	ska_clone https://github.com/laluka/pty4all &
	ska_clone https://github.com/laluka/pypotomux &
	wait
	echo -e "$(C_OK) Offensive tools installed!$(C_RST)"

install-wordlists: sanity-check ## Install wordlists (SecLists, rockyou, etc.)
	echo -e "$(C_INFO) Installing wordlists...$(C_RST)"
	[ ! -d /opt/lists ] && sudo mkdir -p /opt/lists && sudo chown "$$USER:$$USER" /opt/lists || true
	# Download all wordlists in parallel
	ska_clone_list() { local pkg=$${1##*/}; [[ ! -d "/opt/lists/$$pkg" ]] && git clone --depth=1 "$$1" "/var/tmp/$$pkg" && sudo mv "/var/tmp/$$pkg" "/opt/lists/$$pkg" || true ; }
	( [[ ! -f /opt/lists/rockyou.txt ]] && curl -L https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -o /opt/lists/rockyou.txt || true ) &
	ska_clone_list https://github.com/swisskyrepo/PayloadsAllTheThings &
	ska_clone_list https://github.com/1N3/BruteX &
	ska_clone_list https://github.com/1N3/IntruderPayloads &
	ska_clone_list https://github.com/berzerk0/Probable-Wordlists &
	ska_clone_list https://github.com/cujanovic/Open-Redirect-Payloads &
	ska_clone_list https://github.com/danielmiessler/SecLists &
	ska_clone_list https://github.com/ignis-sec/Pwdb-Public &
	ska_clone_list https://github.com/Karanxa/Bug-Bounty-Wordlists &
	ska_clone_list https://github.com/tarraschk/richelieu &
	ska_clone_list https://github.com/p0dalirius/webapp-wordlists &
	wait
	echo -e "$(C_OK) Wordlists installed!$(C_RST)"

install-hardening: sanity-check ## Install hardening tools (opensnitch)
	echo -e "$(C_INFO) Installing hardening tools...$(C_RST)"
	$(PACMAN_INSTALL) opensnitch
	# OPT-IN opensnitch as an egress firewall
	# sudo systemctl enable --now opensnitchd.service
	echo -e "$(C_OK) Hardening tools installed!$(C_RST)"

update: sanity-check ## Update SkillArch (pull & prompt reinstall)
	@[ -n "$$(git status --porcelain)" ] && echo "Error: git state is dirty, please \"git stash\" your changes before updating" && exit 1 || true
	[ "$$(git rev-parse --abbrev-ref HEAD)" != "main" ] && echo "Error: current branch is not main, please switch to main before updating" && exit 1 || true
	git pull
	echo -e "$(C_OK) SkillArch updated, please run make install to apply changes$(C_RST)"

# ============================================================
# Smoke Tests
# ============================================================

test: ## Validate installation (smoke tests)
	echo -e "$(C_INFO)$(C_BOLD) Running SkillArch smoke tests...$(C_RST)"
	@PASS=0 FAIL=0 TOTAL=0
	ska_check() {
		tool="$$1"
		cmd="$$2"
		((TOTAL++)) || true
		if eval "$$cmd" > /dev/null 2>&1 ; then
			echo -e "  $(C_OK)[PASS]$(C_RST) $$1"
			((PASS++))
		else
			echo -e "  $(C_ERR)[FAIL]$(C_RST) $$1"
			((FAIL++))
		fi || true
	}
	echo -e "\n$(C_BOLD)--- Critical Binaries ---$(C_RST)"
	for bin in zsh git nvim tmux nmap curl wget jq rg bat eza trash-put; do
		ska_check "$$bin" "which $$bin"
	done
	ska_check "fzf"        "which fzf || [ -f ~/.fzf/bin/fzf ]"
	echo -e "\n$(C_BOLD)--- Offensive Tools ---$(C_RST)"
	for bin in nmap ffuf msfconsole hashcat bettercap gobypass403 wpprobe; do
		ska_check "$$bin" "which $$bin"
	done
	ska_check "sqlmap"     "which sqlmap || [ -f ~/.local/bin/sqlmap ]"
	ska_check "nuclei"     "which nuclei || [ -f ~/.pdtm/go/bin/nuclei ]"
	ska_check "httpx"      "which httpx || [ -f ~/.pdtm/go/bin/httpx ]"
	ska_check "subfinder"  "which subfinder || [ -f ~/.pdtm/go/bin/subfinder ]"
	ska_check "gef"          "[ -f ~/.gdbinit-gef.py ]"
	echo -e "\n$(C_BOLD)--- Shell & Config ---$(C_RST)"
	ska_check "oh-my-zsh"  "[ -d ~/.oh-my-zsh ]"
	ska_check "zshrc link" "[ -L ~/.zshrc ]"
	ska_check "tmux.conf"  "[ -L ~/.tmux.conf ]"
	ska_check "vimrc"      "[ -L ~/.vimrc ]"
	ska_check "nvim init"  "[ -L ~/.config/nvim/init.lua ]"
	ska_check "ssh dir"    "[ -d ~/.ssh ]"
	echo -e "\n$(C_BOLD)--- Runtimes (mise) ---$(C_RST)"
	ska_check "python"     "mise exec -- python --version"
	ska_check "node"       "mise exec -- node --version"
	ska_check "go"         "mise exec -- go version"
	ska_check "rust"       "mise exec -- rustc --version"
	echo -e "\n$(C_BOLD)--- Directories ---$(C_RST)"
	ska_check "/DATA"      "[ -d /DATA ]"
	ska_check "/opt/skillarch" "[ -d /opt/skillarch ]"
	echo ""
	if [ "$$FAIL" -eq 0 ]; then
		echo -e "$(C_OK)$(C_BOLD) All $$TOTAL tests passed!$(C_RST)"
	else
		echo -e "$(C_WARN)$(C_BOLD) $$PASS/$$TOTAL passed, $$FAIL failed$(C_RST)"
		echo -e "$(C_INFO) Some failures may be expected if you ran a partial install (e.g., lite only)$(C_RST)"
	fi

test-lite: ## Validate lite Docker image install
	echo -e "$(C_INFO)$(C_BOLD) Running SkillArch LITE smoke tests...$(C_RST)"
	@PASS=0 FAIL=0 TOTAL=0
	ska_check() {
		((TOTAL++)) || true
		tool="$$1"
		cmd="$$2"
		if eval "$$cmd" > /dev/null 2>&1 ; then
			echo -e "  $(C_OK)[PASS]$(C_RST) $$1"
			((PASS++))
		else
			echo -e "  $(C_ERR)[FAIL]$(C_RST) $$1"
			((FAIL++))
		fi || true
	}
	echo -e "\n$(C_BOLD)--- Core Binaries ---$(C_RST)"
	for bin in zsh git nvim tmux nmap curl wget jq rg bat eza trash-put; do
		ska_check "$$bin" "which $$bin"
	done
	echo -e "\n$(C_BOLD)--- Offensive Tools ---$(C_RST)"
	for bin in ffuf hashcat bettercap msfconsole gobypass403 wpprobe; do
		ska_check "$$bin" "which $$bin"
	done
	ska_check "nuclei"      "which nuclei || [ -f ~/.pdtm/go/bin/nuclei ]"
	ska_check "httpx"       "which httpx || [ -f ~/.pdtm/go/bin/httpx ]"
	ska_check "gef"         "[ -f ~/.gdbinit-gef.py ]"
	echo -e "\n$(C_BOLD)--- Shell & Config ---$(C_RST)"
	ska_check "oh-my-zsh" "[ -d ~/.oh-my-zsh ]"
	ska_check "zshrc"     "[ -L ~/.zshrc ]"
	ska_check "nvim init" "[ -L ~/.config/nvim/init.lua ]"
	echo -e "\n$(C_BOLD)--- Runtimes ---$(C_RST)"
	ska_check "python"    "mise exec -- python --version"
	ska_check "node"      "mise exec -- node --version"
	ska_check "go"        "mise exec -- go version"
	echo ""
	if [ "$$FAIL" -eq 0 ]; then
		echo -e "$(C_OK)$(C_BOLD) All $$TOTAL lite tests passed!$(C_RST)"
	else
		echo -e "$(C_ERR)$(C_BOLD) $$PASS/$$TOTAL passed, $$FAIL failed$(C_RST)"
		exit 1
	fi

test-full: test ## Validate full Docker image install (runs test + extras)
	echo -e "$(C_INFO)$(C_BOLD) Running SkillArch FULL extra tests...$(C_RST)"
	@PASS=0 FAIL=0 TOTAL=0
	ska_check() {
		((TOTAL++)) || true
		tool="$$1"
		cmd="$$2"
		if eval "$$cmd" > /dev/null 2>&1 ; then
			echo -e "  $(C_OK)[PASS]$(C_RST) $$1"
			((PASS++))
		else
			echo -e "  $(C_ERR)[FAIL]$(C_RST) $$1"
			((FAIL++))
		fi || true
	}
	echo -e "\n$(C_BOLD)--- GUI Binaries ---$(C_RST)"
	for bin in i3 kitty polybar rofi picom code; do
		ska_check "$$bin" "which $$bin"
	done
	echo -e "\n$(C_BOLD)--- GUI Config Symlinks ---$(C_RST)"
	ska_check "i3 config"      "[ -L ~/.config/i3/config ]"
	ska_check "polybar config" "[ -L ~/.config/polybar/config.ini ]"
	ska_check "polybar launch" "[ -L ~/.config/polybar/launch.sh ]"
	ska_check "kitty config"   "[ -L ~/.config/kitty/kitty.conf ]"
	ska_check "picom config"   "[ -L ~/.config/picom.conf ]"
	ska_check "rofi config"    "[ -L ~/.config/rofi/config.rasi ]"
	echo -e "\n$(C_BOLD)--- Wordlists ---$(C_RST)"
	ska_check "/opt/lists"        "[ -d /opt/lists ]"
	ska_check "rockyou.txt"       "[ -f /opt/lists/rockyou.txt ]"
	ska_check "SecLists"          "[ -d /opt/lists/SecLists ]"
	ska_check "PayloadsAllThings" "[ -d /opt/lists/PayloadsAllTheThings ]"
	echo ""
	if [ "$$FAIL" -eq 0 ]; then
		echo -e "$(C_OK)$(C_BOLD) All $$TOTAL full tests passed!$(C_RST)"
	else
		echo -e "$(C_ERR)$(C_BOLD) $$PASS/$$TOTAL passed, $$FAIL failed$(C_RST)"
		exit 1
	fi

# ============================================================
# Diagnostics & Utilities
# ============================================================

doctor: ## Diagnose system health & common issues
	echo -e "$(C_INFO)$(C_BOLD) SkillArch Doctor$(C_RST)"
	echo -e "$(C_BOLD)=================$(C_RST)\n"
	# Disk space
	echo -e "$(C_BOLD)--- Disk Space ---$(C_RST)"
	df -h / /DATA /opt 2>/dev/null | grep -vF "Filesystem" | awk '{printf "  %-20s %s used / %s total (%s)\n", $$6, $$3, $$2, $$5}'
	echo ""
	# Docker daemon
	echo -e "$(C_BOLD)--- Docker ---$(C_RST)"
	if docker info > /dev/null 2>&1; then
		echo -e "  $(C_OK)[OK]$(C_RST) Docker daemon running"
		echo "  Images: $$(docker images -q 2>/dev/null | wc -l), Containers: $$(docker ps -aq 2>/dev/null | wc -l)"
	else
		echo -e "  $(C_WARN)[WARN]$(C_RST) Docker daemon not running or not accessible"
	fi
	echo ""
	# Backup files
	echo -e "$(C_BOLD)--- Backed-up Configs (.skabak) ---$(C_RST)"
	SKABAK_FILES=$$(find ~ /etc/X11 -name "*.skabak" 2>/dev/null || true)
	if [ -n "$$SKABAK_FILES" ]; then
		echo "$$SKABAK_FILES" | while read -r f; do echo "  $$f"; done
	else
		echo "  None found (clean install)"
	fi
	echo ""
	# Broken symlinks
	echo -e "$(C_BOLD)--- Broken Symlinks (config) ---$(C_RST)"
	BROKEN=""
	for link in ~/.zshrc ~/.tmux.conf ~/.vimrc ~/.config/nvim/init.lua ~/.config/i3/config ~/.config/polybar/config.ini ~/.config/polybar/launch.sh ~/.config/kitty/kitty.conf ~/.config/picom.conf ~/.config/rofi/config.rasi; do
		if [ -L "$$link" ] && [ ! -e "$$link" ]; then
			echo -e "  $(C_ERR)[BROKEN]$(C_RST) $$link -> $$(readlink $$link)"
			BROKEN="yes"
		fi
	done
	[ -z "$$BROKEN" ] && echo -e "  $(C_OK)[OK]$(C_RST) All config symlinks valid"
	echo ""
	# System info
	echo -e "$(C_BOLD)--- System Info ---$(C_RST)"
	echo "  OS: $$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo 'unknown')"
	echo "  Kernel: $$(uname -r)"
	echo "  Shell: $$SHELL"
	echo "  User: $$USER"
	echo "  SkillArch: $$(cd /opt/skillarch 2>/dev/null && git log -1 --format='%h (%cr)' || echo 'unknown')"
	echo ""

list-tools: ## List installed offensive tools & versions
	echo -e "$(C_INFO)$(C_BOLD) SkillArch Tool Inventory$(C_RST)"
	echo -e "$(C_BOLD)==========================$(C_RST)\n"
	ska_ver() {
		VER=$$(eval "$$2" 2>/dev/null | head -1 || echo "not found")
		printf "  %-20s %s\n" "$$1" "$$VER"
	}
	echo -e "$(C_BOLD)--- Core ---$(C_RST)"
	ska_ver "git"       "git --version"
	ska_ver "zsh"       "zsh --version"
	ska_ver "nvim"      "nvim --version | head -1"
	ska_ver "tmux"      "tmux -V"
	ska_ver "docker"    "docker --version"
	echo -e "\n$(C_BOLD)--- Runtimes (mise) ---$(C_RST)"
	ska_ver "python"    "mise exec -- python --version"
	ska_ver "node"      "mise exec -- node --version"
	ska_ver "go"        "mise exec -- go version"
	ska_ver "rust"      "mise exec -- rustc --version"
	echo -e "\n$(C_BOLD)--- Offensive ---$(C_RST)"
	ska_ver "nmap"       "nmap --version | head -1"
	ska_ver "ffuf"       "ffuf -V 2>&1 | head -1"
	ska_ver "nuclei"     "nuclei -version 2>&1 | head -1"
	ska_ver "httpx"      "httpx -version 2>&1 | tail -1"
	ska_ver "subfinder"  "subfinder -version 2>&1 | head -1"
	ska_ver "sqlmap"     "sqlmap --version 2>&1 | head -1"
	ska_ver "msfconsole" "msfconsole --version 2>&1 | head -1"
	ska_ver "hashcat"    "hashcat --version 2>&1 | head -1"
	ska_ver "bettercap"  "bettercap -eval 'quit' 2>&1 | grep -i version | head -1"
	ska_ver "gitleaks"   "gitleaks version 2>&1"
	ska_ver "burpsuite"  "burpsuite --version" ## "echo 'installed (GUI)'"
	ska_ver "ghidra"     "cat /opt/ghidra/bom.json| jq -r '.components[].version'|head -1" ## "echo 'installed (GUI)'"
	ska_ver "wireshark"  "wireshark --version 2>&1 | head -1"
	echo -e "\n$(C_BOLD)--- Pipx Tools ---$(C_RST)"
	pipx list --short 2>/dev/null || echo "  pipx not available"
	echo -e "\n$(C_BOLD)--- Pdtm Tools ---$(C_RST)"
	## ls ~/.pdtm/go/bin/ 2>/dev/null | while read -r tool; do echo "  $$tool"; done || echo "  pdtm not installed"
	pdtm 2>&1 | awk '/^[0-9]+\./ {gsub(/\033\[[0-9;]*[mK]/, ""); sub(/^[0-9]+\./, " "); print}'  || echo "  pdtm not installed"
	echo ""

backup: ## Backup current configs before overwriting
	BACKUP_DIR="$$HOME/.skillarch-backup-$$(date +%Y%m%d-%H%M%S)"
	mkdir -p "$$BACKUP_DIR"
	echo -e "$(C_INFO) Backing up configs to $$BACKUP_DIR$(C_RST)"
	for file in ~/.zshrc ~/.tmux.conf ~/.vimrc ~/.config/nvim/init.lua ~/.config/i3/config ~/.config/polybar/config.ini ~/.config/polybar/launch.sh ~/.config/kitty/kitty.conf ~/.config/picom.conf ~/.config/rofi/config.rasi /etc/X11/xorg.conf.d/30-touchpad.conf; do
		if [ -f "$$file" ] || [ -L "$$file" ]; then
			DEST="$$BACKUP_DIR/$$(basename $$file)"
			cp -L "$$file" "$$DEST" 2>/dev/null && echo "  Backed up: $$file" || true
		fi
	done
	echo -e "$(C_OK) Backup complete: $$BACKUP_DIR$(C_RST)"

# ============================================================
# Docker Targets
# ============================================================

docker-build: ## Build lite Docker image locally
	docker build -t thelaluka/skillarch:lite -f Dockerfile-lite .

docker-build-full: docker-build ## Build full Docker image locally
	docker build -t thelaluka/skillarch:full -f Dockerfile-full .

docker-run: ## Run lite Docker image locally
	sudo docker run --rm -it --name=ska --net=host -v /tmp:/tmp thelaluka/skillarch:lite

docker-run-full: ## Run full Docker image locally
	xhost +
	sudo docker run --rm -it --name=ska --net=host -v /tmp:/tmp -e DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix/ --privileged thelaluka/skillarch:full

# ============================================================
# Cleanup
# ============================================================

clean: ## Clean up system and remove unnecessary files
	set +e # Cleanup should be best-effort, never fail the build
	[ ! -f /.dockerenv ] && exit 0
	sudo pacman --noconfirm -Scc || true
	sudo pacman --noconfirm -Sc || true
	sudo pacman -Rns $$(pacman -Qtdq) 2>/dev/null || true
	rm -rf ~/.cache/pip || true
	rm -rf ~/.cache/yay || true
	npm cache clean --force 2>/dev/null || true
	mise cache clear || true
	go clean -cache -modcache -i -r 2>/dev/null || true
	sudo rm -rf /var/cache/* || true
	rm -rf ~/.cache/* || true
	sudo rm -rf /tmp/* || true
	sudo rm -rf /dev/shm/makepkg/* || true
	docker system prune -af 2>/dev/null || true
	sudo journalctl --vacuum-time=1d || true
	sudo find /var/log -type f -name "*.old" -delete 2>/dev/null || true
	sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
	sudo find /var/log -type f -exec truncate --size=0 {} \; 2>/dev/null || true
