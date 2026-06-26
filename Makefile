.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -eu -c
.PHONY: help install sanity-check install-base install-cli-tools install-shell install-docker install-gui install-gui-tools install-offensive install-wordlists install-hardening cloud cloud-export update docker-build docker-build-full docker-run docker-run-full clean test test-lite test-full doctor list-tools backup

# -- Colors & UX Helpers --
C_RST   := \033[0m
C_OK    := \033[1;32m
C_INFO  := \033[1;34m
C_WARN  := \033[1;33m
C_ERR   := \033[1;31m
C_BOLD  := \033[1m
SKA_LOG := /var/tmp/skillarch-install_$(shell date +%Y%m%d_%H%M%S).log
## Use the variable $(comma) instead of ',' to prevent it from being used as a parameter separator.
comma   := ,

BOLD = echo -e "$(C_BOLD)$(1)$(C_RST)"
OK   = echo -e "$(C_OK)✔  $(1)$(C_RST)"
INFO = echo -e "$(C_INFO)→  $(1)$(C_RST)"
WARN = echo -e "$(C_WARN)⚠  $(1)$(C_RST)"
ERR  = echo -e "$(C_ERR)✖  $(1)$(C_RST)" >&2
STEP = echo -e "$(C_BOLD)$(C_INFO)==>  [$(1)/$(2)]$(C_RST) $(C_INFO)$(3)...$(C_RST)"
DONE = echo -e "\n$(C_OK)✓ Done - $(1)$(C_RST)\n"

define ska-link
	# Backup existing file (if not already a symlink) and create symlink
	[[ -f $(2) && ! -L $(2) ]] && mv $(2) $(2).skabak || true
	ln -sf $(1) $(2)
endef

# In Docker the build sandbox lacks the caps to isolate the network for pacman
# install hooks (systemd-hook etc) -> "could not isolate the network". Disable it.
# Called by every target that runs pacman before install-base (e.g. install-docker
# in the full image, which is FROM lite and never re-runs install-base).
define ska-pacman-sandbox
	[[ -f /.dockerenv ]] && ! grep -q '^DisableSandboxNetwork' /etc/pacman.conf && sudo sed -i '/^\[options\]/a DisableSandboxNetwork' /etc/pacman.conf || true
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
	$(call DONE,You are all set up! Enjoy SkillArch! <3)
	$(call INFO,Install log saved to $(SKA_LOG))

sanity-check:
	set -x
	# Ensure we are in /opt/skillarch or /opt/skillarch-original (maintainer only)
	[[ "$$(pwd)" != "/opt/skillarch" ]] && [[ "$$(pwd)" != "/opt/skillarch-original" ]] && $(call ERR,You must be in /opt/skillarch or /opt/skillarch-original to run this command) && exit 1 || true
	@sudo true || { $(call ERR,Error: sudo access is required) ; exit 1; }
	[[ ! -f /.dockerenv ]] && { systemd-inhibit --what sleep:idle sleep 3600 & } || true

install-base: sanity-check ## Install base packages
	$(call INFO,Installing base packages...)
	# Clean up, Update, Basics
	sudo sed -e "s#.*ParallelDownloads.*#ParallelDownloads = 10#g" -i /etc/pacman.conf
	$(call ska-pacman-sandbox)
	echo 'BUILDDIR="/dev/shm/makepkg"' | sudo tee /etc/makepkg.conf.d/00-skillarch.conf
	[[ ! -f /.dockerenv ]] && sudo cachyos-rate-mirrors || true # Increase install speed & Update repos (skip in Docker)

	# Init keyring only if needed
	[[ ! -d /etc/pacman.d/gnupg ]] && sudo pacman-key --init || true
	sudo pacman --noconfirm -Sc
	sudo pacman --noconfirm -Syu
	$(PACMAN_INSTALL) git vim tmux wget curl archlinux-keyring

	# Add chaotic-aur: download keyring+mirrorlist in parallel, install locally (avoids slow HKP keyserver)
	wget -qP /tmp/ 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' &
	wget -qP /tmp/ 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' &
	wait
	sudo pacman --noconfirm -U /tmp/chaotic-keyring.pkg.tar.zst /tmp/chaotic-mirrorlist.pkg.tar.zst

	# Ensure chaotic-aur is present in /etc/pacman.conf
	grep -vP '\[chaotic-aur\]|Include = /etc/pacman.d/chaotic-mirrorlist' /etc/pacman.conf | sudo tee /etc/pacman.conf > /dev/null
	echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf > /dev/null

	# Single populate + sync with all repos now configured
	sudo pacman-key --populate archlinux cachyos chaotic
	sudo pacman --noconfirm -Syu

	# Long Lived DATA & trash-cli Setup
	[[ ! -d /DATA ]] && sudo mkdir -pv /DATA && sudo chown "$$USER:$$USER" /DATA && sudo chmod 770 /DATA || true
	[[ ! -d /.Trash ]] && sudo mkdir -pv /.Trash && sudo chown "$$USER:$$USER" /.Trash && sudo chmod 770 /.Trash && sudo chmod +t /.Trash || true
	$(call DONE,Base packages installed!)

install-cli-tools: sanity-check ## Install CLI tools & runtimes
	$(call INFO,Installing CLI tools & runtimes...)
	$(PACMAN_INSTALL) base-devel bison bzip2 ca-certificates cloc cmake dos2unix expect ffmpeg foremost gdb gnupg htop bottom hwinfo icu inotify-tools iproute2 jq llvm lsof ltrace make mlocate mplayer ncurses net-tools ngrep nmap openssh openssl parallel perl-image-exiftool pkgconf python-virtualenv re2c readline ripgrep rlwrap socat sqlite sshpass tmate tor traceroute trash-cli tree unzip vbindiff xclip xz yay zip veracrypt git-delta viu qsv asciinema htmlq neovim glow jless websocat superfile gron eza fastfetch bat sysstat cronie tree-sitter bc
	sudo ln -sf /usr/bin/bat /usr/local/bin/batcat
	[[ ! -f ~/.gdbinit-gef.py ]] && curl -fsSL -o ~/.gdbinit-gef.py https://raw.githubusercontent.com/hugsy/gef/main/gef.py && echo "source ~/.gdbinit-gef.py" >> ~/.gdbinit || echo "gef already installed"
	# nvim config
	[[ ! -d ~/.config/nvim ]] && git clone --depth=1 https://github.com/LazyVim/starter ~/.config/nvim || true
	$(call ska-link,/opt/skillarch/config/nvim/init.lua,$$HOME/.config/nvim/init.lua)
	nvim --headless +"Lazy! sync" +qa >/dev/null # Download and update plugins

	# Install mise and all php-build dependencies
	$(PACMAN_INSTALL) mise libedit libffi libjpeg-turbo libpcap libpng libxml2 libzip postgresql-libs php-gd
	# mise self-update # Currently broken, wait for upstream fix, pinged on 17/03/2025
	for package in uv usage pdm rust terraform golang python nodejs opencode; do \
		for attempt in 1 2 3; do \
			mise use -g "$$package@latest" && break || { \
				$(call WARN,mise install $$package failed (attempt $$attempt/3)$(comma) retrying in 5s...) ; \
				sleep 5 ; \
			} ; \
		done ; \
	done
	mise exec -- go env -w "GOPATH=/home/$$USER/.local/go"
	eval "$$(mise activate bash)" || true

	# Install uv tools
	for package in argcomplete bypass-url-parser exegol pre-commit sqlmap wafw00f yt-dlp semgrep defaultcreds-cheat-sheet; do
		uv tool install "$$package" || {
			$(call WARN,Retrying $$package install...)
			uv tool install -q "$$package"
		}
	done
	uv tool upgrade --all || true
	mise up -q || true
	mise prune -q || true
	$(call DONE,CLI tools & runtimes installed!)

install-shell: sanity-check ## Install shell, zsh, oh-my-zsh, fzf, tmux
	$(call INFO,Installing shell & dotfiles...)
	# Install and Configure zsh and oh-my-zsh
	$(PACMAN_INSTALL) zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search zsh-theme-powerlevel10k
	[[ ! -d ~/.oh-my-zsh ]] && sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
	$(call ska-link,/opt/skillarch/config/zshrc,$$HOME/.zshrc)
	[[ ! -d ~/.oh-my-zsh/plugins/zsh-completions ]] && git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/plugins/zsh-completions || true
	[[ ! -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ]] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions || true
	[[ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ]] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting || true
	[[ ! -d ~/.ssh ]] && mkdir ~/.ssh && chmod 700 ~/.ssh || true # Must exist for ssh-agent to work
	for plugin in colored-man-pages docker extract fzf mise npm terraform tmux zsh-autosuggestions zsh-completions zsh-syntax-highlighting ssh-agent z ; do zsh -c "source ~/.zshrc && omz plugin enable $$plugin || true" || true; done

	# Install and configure fzf, tmux, vim
	[[ ! -d ~/.fzf ]] && git clone --depth=1 https://github.com/junegunn/fzf ~/.fzf && ~/.fzf/install --all || true
	$(call ska-link,/opt/skillarch/config/tmux.conf,$$HOME/.tmux.conf)
	$(call ska-link,/opt/skillarch/config/vimrc,$$HOME/.vimrc)
	# Set the default user shell to zsh
	sudo chsh -s /usr/bin/zsh "$$USER" # Logout required to be applied
	$(call DONE,Shell & dotfiles installed!)

install-docker: sanity-check ## Install Docker & Docker Compose
	$(call INFO,Installing Docker...)
	$(call ska-pacman-sandbox) # full image is FROM lite & skips install-base; ensure flag here
	$(PACMAN_INSTALL) docker docker-compose
	# It's a desktop machine, don't expose stuff, but we don't care much about LPE
	# Think about it, set "alias sudo='backdoor ; sudo'" in userland and voila. OSEF!
	getent group docker >/dev/null || sudo groupadd docker # ensure group exists (pacman hook may have been sandboxed)
	sudo usermod -aG docker "$$USER" # Logout required to be applied
	sleep 1 # Prevent too many docker socket calls and security locks
	# Do not start services in docker
	[[ ! -f /.dockerenv ]] && sudo systemctl enable --now docker || true
	$(call DONE,Docker installed!)

install-gui: sanity-check ## Install i3, polybar, kitty, rofi, picom, KDE Plasma
	$(call INFO,Installing GUI & window manager...)
	[[ ! -f /etc/machine-id ]] && sudo systemd-machine-id-setup || true
	$(PACMAN_INSTALL) xorg-server cachyos-kde-settings plasma-meta i3-gaps i3blocks i3lock i3lock-fancy-git i3status dmenu feh rofi nm-connection-editor picom polybar kitty brightnessctl xorg-xhost
	# KDE Plasma X11 - Plasma 6 + kwin_x11, also used by cloud VNC target
	$(PACMAN_INSTALL) plasma-desktop plasma-x11-session kwin-x11 konsole alacritty
	yay --noconfirm --needed -S rofi-power-menu i3-battery-popup-git
	# -- KDE Dark Theme (BreezeDark) --
	# plasma-apply-colorscheme needs a running Plasma session (D-Bus); during install
	# it usually fails silently. Write kdeglobals + GTK configs directly as fallback.
	plasma-apply-colorscheme BreezeDark 2>/dev/null || true
	plasma-apply-wallpaperimage /opt/skillarch/assets/bg.jpg 2>/dev/null || true
	mkdir -p ~/.config ~/.config/gtk-3.0 ~/.config/gtk-4.0
	# kdeglobals - force BreezeDark color scheme + Breeze icons for all KDE/Qt apps
	kwriteconfig6 --file ~/.config/kdeglobals --group General --key ColorScheme BreezeDark 2>/dev/null || true
	kwriteconfig6 --file ~/.config/kdeglobals --group General --key Name "Breeze Dark" 2>/dev/null || true
	kwriteconfig6 --file ~/.config/kdeglobals --group Icons --key Theme breeze-dark 2>/dev/null || true
	kwriteconfig6 --file ~/.config/kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop 2>/dev/null || true
	# GTK 3/4 - sync dark theme so GTK apps (Firefox, etc.) also go dark
	echo -e '[Settings]\ngtk-theme-name=Breeze-Dark\ngtk-icon-theme-name=breeze-dark\ngtk-application-prefer-dark-theme=true' > ~/.config/gtk-3.0/settings.ini
	echo -e '[Settings]\ngtk-theme-name=Breeze-Dark\ngtk-icon-theme-name=breeze-dark\ngtk-application-prefer-dark-theme=true' > ~/.config/gtk-4.0/settings.ini
	echo "export QT_QPA_PLATFORMTHEME=kde" > ~/.xprofile # Ensures Qt apps read kdeglobals under i3 (not just Plasma)
	echo "export XDG_SESSION_TYPE=x11" >> ~/.xprofile # Ensure other other apps rely on x11 instead of wayland
	# -- MIME defaults: image=eog, video/audio=vlc, pdf/html=chrome, text=kate, dir=thunar --
	# GTK file managers (Thunar, Nautilus, etc.) and xdg-open read ~/.config/mimeapps.list.
	# We use Thunar instead of Dolphin because KIO's portal-based launcher hangs under i3.
	printf '%s\n' '[Default Applications]' 'image/png=org.gnome.eog.desktop' 'image/jpeg=org.gnome.eog.desktop' 'image/gif=org.gnome.eog.desktop' 'image/webp=org.gnome.eog.desktop' 'image/bmp=org.gnome.eog.desktop' 'image/tiff=org.gnome.eog.desktop' 'image/svg+xml=org.gnome.eog.desktop' 'video/mp4=vlc.desktop' 'video/x-matroska=vlc.desktop' 'video/webm=vlc.desktop' 'video/quicktime=vlc.desktop' 'video/x-msvideo=vlc.desktop' 'audio/mpeg=vlc.desktop' 'audio/ogg=vlc.desktop' 'audio/flac=vlc.desktop' 'audio/x-wav=vlc.desktop' 'audio/vnd.wave=vlc.desktop' 'application/pdf=google-chrome.desktop' 'text/html=google-chrome.desktop' 'x-scheme-handler/http=google-chrome.desktop' 'x-scheme-handler/https=google-chrome.desktop' 'x-scheme-handler/about=google-chrome.desktop' 'x-scheme-handler/unknown=google-chrome.desktop' 'x-scheme-handler/mailto=google-chrome.desktop' 'text/plain=org.kde.kate.desktop' 'inode/directory=thunar.desktop' > ~/.config/mimeapps.list
	# Pin default taskbar launchers (systemsettings, chrome, thunar, alacritty)
	mkdir -p ~/.config
	PLASMA_RC=~/.config/plasma-org.kde.plasma.desktop-appletsrc ; \
	if [[ -f "$$PLASMA_RC" ]]; then \
		sed -i 's|^launchers=.*|launchers=applications:systemsettings.desktop,applications:google-chrome.desktop,applications:thunar.desktop,applications:Alacritty.desktop|' "$$PLASMA_RC" ; \
	fi

	# i3 config
	[[ ! -d ~/.config/i3 ]] && mkdir -p ~/.config/i3 || true
	$(call ska-link,/opt/skillarch/config/i3/config,$$HOME/.config/i3/config)

	# polybar config
	[[ ! -d ~/.config/polybar ]] && mkdir -p ~/.config/polybar || true
	$(call ska-link,/opt/skillarch/config/polybar/config.ini,$$HOME/.config/polybar/config.ini)
	$(call ska-link,/opt/skillarch/config/polybar/launch.sh,$$HOME/.config/polybar/launch.sh)

	# rofi config
	[[ ! -d ~/.config/rofi ]] && mkdir -p ~/.config/rofi || true
	$(call ska-link,/opt/skillarch/config/rofi/config.rasi,$$HOME/.config/rofi/config.rasi)

	# picom config
	$(call ska-link,/opt/skillarch/config/picom.conf,$$HOME/.config/picom.conf)

	# kitty config
	[[ ! -d ~/.config/kitty ]] && mkdir -p ~/.config/kitty || true
	$(call ska-link,/opt/skillarch/config/kitty/kitty.conf,$$HOME/.config/kitty/kitty.conf)

	# touchpad config
	[[ ! -d /etc/X11/xorg.conf.d ]] && sudo mkdir -p /etc/X11/xorg.conf.d || true
	[[ -f /etc/X11/xorg.conf.d/30-touchpad.conf ]] && sudo mv /etc/X11/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf.skabak || true
	sudo ln -sf /opt/skillarch/config/xorg.conf.d/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf
	$(call DONE,GUI & window manager installed!)

install-gui-tools: sanity-check ## Install GUI apps (Chrome, VSCode, Ghidra, etc.)
	$(call INFO,Installing GUI applications...)
	# Pre-create flatpak repo dir so post-install hooks don't fail in Docker (flatpak may be pulled as a dependency)
	[[ -f /.dockerenv ]] && sudo mkdir -p /var/lib/flatpak/repo || true
	# Force refresh DBs - chaotic-aur rolls fast; stale local DB → 404 on package files (e.g. visual-studio-code-bin)
	sudo pacman --noconfirm -Syy || true
	$(PACMAN_INSTALL) vlc vlc-plugin-ffmpeg arandr blueman visual-studio-code-bin discord dunst filezilla flameshot ghex google-chrome gparted kdenlive kompare libreoffice-fresh meld okular qbittorrent torbrowser-launcher wireshark-qt ghidra signal-desktop dragon-drop-git emote guvcview audacity polkit-kde-agent kamoso thunar thunar-archive-plugin thunar-volman tumbler ffmpegthumbnailer gvfs gvfs-mtp file-roller
	[[ ! -f /.dockerenv ]] && $(PACMAN_INSTALL) flatpak && flatpak install -y flathub com.obsproject.Studio || true
	# Do not start services in docker

	xargs -I{} code --install-extension {} --force < config/extensions.txt
	for pkg in fswebcam; do yay --noconfirm --needed -S "$$pkg" || $(call WARN,Failed to install $$pkg$(comma) continuing...); done
	sudo ln -sf /usr/bin/google-chrome-stable /usr/local/bin/gog
	$(call DONE,GUI applications installed!)

install-offensive: sanity-check ## Install offensive & security tools
	$(call INFO,Installing offensive tools...)
	ska_clone() { local pkg=$${1##*/}; [[ ! -d "/opt/$$pkg" ]] && git clone --depth=1 "$$1" "/tmp/$$pkg" && sudo mv "/tmp/$$pkg" "/opt/$$pkg" || true ; }
	$(PACMAN_INSTALL) metasploit fx lazygit fq gitleaks jdk21-openjdk hashcat bettercap bore
	for pkg in ffuf gau waybackurls fabric-ai-bin caido-desktop caido-cli; do yay --noconfirm --needed -S "$$pkg" || $(call WARN,Failed to install $$pkg$(comma) continuing...); done

	# HExHTTP: HTTP header vuln/cache-poisoning scanner - clone + isolated venv + PATH shim.
	# Upstream pyproject entrypoint is broken (hexhttp.py not packaged); bypass with a direct wrapper.
	ska_clone https://github.com/c0dejump/HExHTTP && sudo chown -R "$$USER:$$USER" /opt/HExHTTP || true
	[[ -d /opt/HExHTTP ]] && git -C /opt/HExHTTP/ pull -q && uv venv --allow-existing -q /opt/HExHTTP/.venv && uv pip install -q -p /opt/HExHTTP/.venv /opt/HExHTTP || true
	sudo tee /usr/local/bin/hexhttp > /dev/null <<-'SHIM'
		#!/usr/bin/env bash
		exec /opt/HExHTTP/.venv/bin/python /opt/HExHTTP/hexhttp.py "$$@"
	SHIM
	sudo chmod +x /usr/local/bin/hexhttp

	# Hide stdout and Keep stderr for CI builds -- run go installs in parallel
	mise exec -- go install github.com/sw33tLie/sns@latest > /dev/null &
	mise exec -- go install github.com/glitchedgitz/cook/v2/cmd/cook@latest > /dev/null &
	mise exec -- go install github.com/x90skysn3k/brutespray@latest > /dev/null &
	mise exec -- go install github.com/sensepost/gowitness@latest > /dev/null &
	wait

	# Install GitHub binary releases -- gobypass403 & wpprobe (sequential)
	( wget -q "$$(curl -sL https://api.github.com/repos/slicingmelon/gobypass403/releases/latest | jq -r '.assets[] | select(.name | contains("linux_amd64")) | .browser_download_url')" -O /tmp/gobypass403 \
		&& chmod +x /tmp/gobypass403 && sudo mv /tmp/gobypass403 /usr/local/bin/gobypass403 ) || true
	( wget -q "$$(curl -sL https://api.github.com/repos/Chocapikk/wpprobe/releases/latest | jq -r '.assets[] | select(.name | test("linux_amd64")) | .browser_download_url')" -O /tmp/wpprobe \
		&& chmod +x /tmp/wpprobe && sudo mv /tmp/wpprobe /usr/local/bin/wpprobe \
		&& wpprobe update-db ) || true

	# massdns: required by shuffledns (PD tool) - Build from source into ~/.local/bin
	ska_clone https://github.com/blechschmidt/massdns && make -C /opt/massdns 2>/dev/null && cp /opt/massdns/bin/massdns $$HOME/.local/bin/ || true
	# Check for massdns update
	[[ -d /opt/massdns ]] && git -C /opt/massdns pull | grep -q -v "Already up to date" && make -C /opt/massdns 2>/dev/null && cp /opt/massdns/bin/massdns $$HOME/.local/bin/ || true

	# pdtm via mise/aqua (avoids the AUR pdtm-bin churn). -install-all still hits the
	# GitHub API rate limit (60 req/h unauthenticated) -- keep the retry-after-reset loop.
	mise use -g aqua:projectdiscovery/pdtm@latest
	for attempt in 1 2 3 4 5; do \
		mise exec -- pdtm -ia && break || { \
			$(call WARN,pdtm install failed (attempt $$attempt/5)$(comma) likely rate-limited. Waiting 4m for reset...) ; \
			sleep 240 ; \
		} ; \
	done || true
	mise exec -- pdtm -ua || true
	zsh -c "source ~/.zshrc && nuclei -update-templates -update-template-dir ~/.nuclei-templates" || true
	rm -rf /tmp/nuclei[0-9]*

	# Clone custom tools -- run in parallel
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
	$(call DONE,Offensive tools installed!)

install-wordlists: sanity-check ## Install wordlists (SecLists, rockyou, etc.)
	$(call INFO,Installing wordlists...)
	[[ ! -d /opt/lists ]] && sudo mkdir -p /opt/lists && sudo chown "$$USER:$$USER" /opt/lists || true
	# Download all wordlists in parallel
	ska_clone_list() { local pkg=$${1##*/}; [[ ! -d "/opt/lists/$$pkg" ]] && git clone --depth=1 "$$1" "/var/tmp/$$pkg" && sudo mv "/var/tmp/$$pkg" "/opt/lists/$$pkg" || true ; }
	( [[ ! -f /opt/lists/rockyou.txt ]] && curl -sL "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt" -o /opt/lists/rockyou.txt || true ) &
	( [[ ! -f /opt/lists/confusables.txt ]] && curl -sL "https://www.unicode.org/Public/security/latest/confusables.txt" -o /opt/lists/confusables.txt || true ) &
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
	$(call DONE,Wordlists installed!)

install-hardening: sanity-check ## Install hardening tools (opensnitch)
	$(call INFO,Installing hardening tools...)
	$(PACMAN_INSTALL) opensnitch
	# OPT-IN opensnitch as an egress firewall
	# sudo systemctl enable --now opensnitchd.service
	$(call DONE,Hardening tools installed!)

cloud: sanity-check ## (Standalone) Install KasmVNC + cloud-init for cloud/remote desktop - NOT part of make install
	$(call INFO,Installing cloud/remote desktop tools...)

	# -- KasmVNC --
	# openssl-1.1: KasmVNC binary is linked against libssl.so.1.1
	yay --noconfirm --needed -S openssl-1.1 || $(call WARN,Failed to install openssl-1.1$(comma) continuing...)
	# KasmVNC: browser-based VNC remote desktop (per-user, no systemd daemon)
	yay --noconfirm --needed -S kasmvncserver-bin || $(call WARN,Failed to install kasmvncserver-bin$(comma) continuing...)

	# -- KasmVNC config --
	mkdir -p ~/.vnc
	$(call ska-link,/opt/skillarch/config/kasmvnc.yaml,$$HOME/.vnc/kasmvnc.yaml)
	$(call ska-link,/opt/skillarch/config/vnc-xstartup,$$HOME/.vnc/xstartup)
	# Self-signed SSL cert (one-time)
	[[ ! -f ~/.vnc/self.pem ]] && openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
		-keyout ~/.vnc/self.key -out ~/.vnc/self.pem -subj "/CN=vnc" 2>/dev/null && chmod 600 ~/.vnc/self.key || true
	# Dummy kasmpasswd - KasmVNC refuses to start without one; -DisableBasicAuth makes it unused.
	# Password MUST be >= 6 chars or kasmvncpasswd silently fails.
	[[ ! -f ~/.kasmpasswd ]] && echo -e "kasmvnc\nkasmvnc" | kasmvncpasswd -u dummy -w -ow ~/.kasmpasswd 2>/dev/null && chmod 600 ~/.kasmpasswd || true
	# Mark DE as already selected - xstartup is pre-configured; skips interactive DE picker
	touch ~/.vnc/.de-was-selected
	# Polkit: allow wheel group to act without password - VNC sessions have no local seat for polkit prompts
	sudo tee /etc/polkit-1/rules.d/49-nopasswd-wheel.rules > /dev/null <<< 'polkit.addRule(function(action, subject) { if (subject.isInGroup("wheel")) { return polkit.Result.YES; } });'

	# -- tmux: cloud theme (dark purple-blue status bar) --
	sed -i "s|^set-option -g status-bg.*|set-option -g status-bg '#1e1e2e'  # deep dark purple-blue|" /opt/skillarch/config/tmux.conf
	sed -i "s|^set-option -g status-fg.*|set-option -g status-fg '#cba6f7'  # soft lavender|" /opt/skillarch/config/tmux.conf

	# -- cloud-init --
	# Replace gnu-netcat with openbsd-netcat (cloud-init dependency, nothing depends on gnu-netcat)
	sudo pacman -Rdd --noconfirm gnu-netcat 2>/dev/null || true
	$(PACMAN_INSTALL) cloud-init
	# Enable cloud-init services so the VM auto-configures on first boot (network, SSH keys, hostname, etc.)
	# cloud-init 25.x split services: cloud-init-local, cloud-init-main, cloud-init-network, cloud-config, cloud-final
	[[ ! -f /.dockerenv ]] && sudo systemctl enable cloud-init-local.service cloud-init-main.service cloud-init-network.service cloud-config.service cloud-final.service || true
	# Proxmox compatibility: enable NoCloud + ConfigDrive datasources (Proxmox uses NoCloud via CDROM/SMBIOS)
	# DigitalOcean compatibility: enable DigitalOcean datasource
	sudo sed -i 's/^#\?\s*datasource_list:.*/datasource_list: [NoCloud, ConfigDrive, DigitalOcean, None]/' /etc/cloud/cloud.cfg 2>/dev/null \
		|| echo 'datasource_list: [NoCloud, ConfigDrive, DigitalOcean, None]' | sudo tee -a /etc/cloud/cloud.cfg > /dev/null
	# Preserve the existing user instead of creating a default "arch" user
	sudo sed -i 's/^\(\s*name:\s*\).*/\1'"$$USER"'/' /etc/cloud/cloud.cfg 2>/dev/null || true
	# Allow password & root SSH login via cloud-init (prevents 50-cloud-init.conf from disabling them on boot)
	grep -q '^ssh_pwauth' /etc/cloud/cloud.cfg && sudo sed -i 's/^#\?\s*ssh_pwauth:.*/ssh_pwauth: true/' /etc/cloud/cloud.cfg \
		|| echo 'ssh_pwauth: true' | sudo tee -a /etc/cloud/cloud.cfg > /dev/null
	grep -q '^disable_root' /etc/cloud/cloud.cfg && sudo sed -i 's/^#\?\s*disable_root:.*/disable_root: false/' /etc/cloud/cloud.cfg \
		|| echo 'disable_root: false' | sudo tee -a /etc/cloud/cloud.cfg > /dev/null

	# -- Sudoers (passwordless sudo for hacker) --
	echo 'hacker ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/99-hacker > /dev/null && sudo chmod 440 /etc/sudoers.d/99-hacker

	# -- SSH --
	$(PACMAN_INSTALL) openssh
	[[ ! -f /.dockerenv ]] && sudo systemctl enable --now sshd.service || true
	sudo sed -i 's/^#\?\s*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
	sudo sed -i 's/^#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
	sudo sed -i 's/^#\?\s*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
	[[ ! -f /.dockerenv ]] && sudo systemctl restart sshd.service || true
	sudo ufw allow 22/tcp comment 'SSH' || true

	# -- Delete all Snapper snapshots --
	# Snapper read-only snapshots cause libguestfs to detect multiple OS roots,
	# breaking virt-sysprep during cloud-export. Clean slate for smaller exports too.
	$(call INFO,Deleting all Snapper snapshots...)
	sudo snapper delete $$(sudo snapper list --columns number | tail -n +4 | tr -d ' ' | tr '\n' ' ') 2>/dev/null || true

	$(call DONE,Cloud tools installed! Start KasmVNC with: ska-vnc)

cloud-export: ## Export a libvirt VM to a clean qcow2 (for Proxmox/DO import)
	@$(call INFO,Scanning libvirt VMs via virsh...)
	echo ""
	# -- Discover VMs --
	VM_LIST=$$(virsh -c qemu:///session list --all --name | sed '/^$$/d')
	[[ -z "$$VM_LIST" ]] && $(call ERR,No VMs found in qemu:///session) && exit 1
	# -- Build a nice picker --
	i=0
	declare -A VM_MAP
	while IFS= read -r vm; do \
		((i++)) || true ; \
		STATE=$$(virsh -c qemu:///session domstate "$$vm" 2>/dev/null | head -1) ; \
		VCPUS=$$(virsh -c qemu:///session dominfo "$$vm" 2>/dev/null | awk '/CPU\(s\)/{print $$2}') ; \
		RAM=$$(virsh -c qemu:///session dominfo "$$vm" 2>/dev/null | awk '/Max memory/{printf "%.0fG", $$3/1048576}') ; \
		DISK=$$(virsh -c qemu:///session domblklist "$$vm" --details 2>/dev/null | awk '/disk/{print $$4}') ; \
		DISK_SIZE=$$(qemu-img info "$$DISK" 2>/dev/null | awk '/virtual size/{print $$3, $$4}' || echo "?") ; \
		SNAPS=$$(virsh -c qemu:///session snapshot-list "$$vm" --name 2>/dev/null | sed '/^$$/d' | wc -l) ; \
		TITLE=$$(virsh -c qemu:///session dumpxml "$$vm" 2>/dev/null | grep -oP '(?<=<title>).*(?=</title>)' || echo "") ; \
		[[ -n "$$TITLE" ]] && LABEL="$$TITLE ($$vm)" || LABEL="$$vm" ; \
		printf "  $(C_BOLD)%d)$(C_RST)  %-30s  $(C_INFO)%-10s$(C_RST)  %s vCPU  %s RAM  %s  %d snapshot(s)\n" \
			"$$i" "$$LABEL" "[$$STATE]" "$$VCPUS" "$$RAM" "$$DISK_SIZE" "$$SNAPS" ; \
		VM_MAP[$$i]="$$vm" ; \
	done <<< "$$VM_LIST"
	echo ""
	# -- Interactive pick --
	read -rp "Select VM number: " PICK
	VM_NAME="$${VM_MAP[$$PICK]:-}"
	[[ -z "$$VM_NAME" ]] && $(call ERR,Invalid selection) && exit 1
	# -- Ensure VM is shut off --
	VM_STATE=$$(virsh -c qemu:///session domstate "$$VM_NAME" | head -1)
	[[ "$$VM_STATE" != "shut off" ]] && $(call ERR,VM \"$$VM_NAME\" is $$VM_STATE - please shut it down first) && exit 1
	# -- Locate source disk --
	SRC_DISK=$$(virsh -c qemu:///session domblklist "$$VM_NAME" --details | awk '/disk/{print $$4}')
	[[ ! -f "$$SRC_DISK" ]] && $(call ERR,Disk image not found: $$SRC_DISK) && exit 1
	SNAP_COUNT=$$(virsh -c qemu:///session snapshot-list "$$VM_NAME" --name 2>/dev/null | sed '/^$$/d' | wc -l)
	$(call INFO,Source disk: $$SRC_DISK)
	$(call INFO,Snapshots to flatten: $$SNAP_COUNT)
	# -- Output path --
	OUT_DIR="/DATA/VMs/exports"
	mkdir -p "$$OUT_DIR"
	TIMESTAMP=$$(date +%Y%m%d-%H%M%S)
	OUT_FILE="$$OUT_DIR/skillarch-$$TIMESTAMP.qcow2"
	# -- Flatten snapshots + convert to clean qcow2 --
	$(call INFO,Converting to clean qcow2 (flattening all snapshots)...)
	$(call WARN,This may take a while depending on disk size...)
	qemu-img convert -p -O qcow2 "$$SRC_DISK" "$$OUT_FILE"
	# -- Sparsify to reclaim zeroed blocks --
	$(call INFO,Sparsifying to shrink the image...)
	virt-sparsify --in-place "$$OUT_FILE"
	# -- Sysprep: clean machine-id, logs, SSH host keys for fresh cloud-init boot --
	$(call INFO,Sysprep: cleaning machine-id$(comma) SSH host keys$(comma) logs...)
	virt-sysprep -a "$$OUT_FILE" \
		--operations ssh-hostkeys,logfiles,tmp-files,bash-history,customize \
		--no-selinux-relabel \
		--run-command 'truncate -s0 /etc/machine-id || true' \
		--run-command 'rm -f /var/lib/cloud/instance /var/lib/cloud/instances/* 2>/dev/null; true'
	# -- Summary --
	FINAL_SIZE=$$(du -h "$$OUT_FILE" | cut -f1)
	echo ""
	$(call OK,Export complete!)
	echo ""
	echo "  File:   $$OUT_FILE"
	echo "  Size:   $$FINAL_SIZE"
	echo "  Format: qcow2 (no snapshots$(comma) BIOS/GRUB$(comma) cloud-init ready)"
	echo ""
	echo "  Import to Proxmox:"
	echo "    scp $$OUT_FILE root@proxmox:/var/lib/vz/images/"
	echo "    qm importdisk <VMID> /var/lib/vz/images/$$(basename $$OUT_FILE) local-lvm"
	echo ""
	echo "  Import to DigitalOcean:"
	echo "    doctl compute image create skillarch --image-url <upload-url> --region nyc1"
	echo ""

update: sanity-check ## Update SkillArch (pull & prompt reinstall)
	@[[ -n "$$(git status --porcelain)" ]] && echo "Error: git state is dirty, please \"git stash\" your changes before updating" && exit 1 || true
	[[ "$$(git rev-parse --abbrev-ref HEAD)" != "main" ]] && echo "Error: current branch is not main, please switch to main before updating" && exit 1 || true
	git pull
	$(call DONE,SkillArch updated$(comma) please run make install to apply changes)

# ============================================================
# Smoke Tests
# ============================================================

test: ## Validate installation (smoke tests)
	$(call INFO,Running SkillArch smoke tests...)
	@PASS=0 FAIL=0 TOTAL=0
	ska_check() {
		tool="$$1"
		cmd="$$2"
		((TOTAL++)) || true
		if eval "$$cmd" > /dev/null 2>&1 ; then
			$(call OK,  [PASS]$(C_RST) $$tool)
			((PASS++))
		else
			$(call ERR,  [FAIL]$(C_RST) $$tool ($$cmd))
			((FAIL++))
		fi || true
	}
	$(call BOLD,\n--- Critical Binaries ---)
	for bin in zsh git nvim tmux nmap curl wget jq rg bat eza trash-put; do
		ska_check "$$bin" "which $$bin"
	done
	ska_check "fzf"        "which fzf || [[ -f ~/.fzf/bin/fzf ]]"
	$(call BOLD,\n--- Offensive Tools ---)
	for bin in nmap ffuf msfconsole hashcat bettercap gobypass403 wpprobe; do
		ska_check "$$bin" "which $$bin"
	done
	ska_check "sqlmap"      "which sqlmap || [[ -f ~/.local/bin/sqlmap ]]"
	ska_check "hexhttp"     "which hexhttp || [[ -f ~/.local/bin/hexhttp ]]"
	ska_check "nuclei"      "which nuclei || [[ -f ~/.pdtm/go/bin/nuclei ]]"
	ska_check "httpx"       "which httpx || [[ -f ~/.pdtm/go/bin/httpx ]]"
	ska_check "subfinder"   "which subfinder || [[ -f ~/.pdtm/go/bin/subfinder ]]"
	ska_check "gef"         "[[ -f ~/.gdbinit-gef.py ]]"
	$(call BOLD,\n--- Shell & Config ---)
	ska_check "oh-my-zsh"  "[[ -d ~/.oh-my-zsh ]]"
	ska_check "zshrc link" "[[ -L ~/.zshrc ]]"
	ska_check "tmux.conf"  "[[ -L ~/.tmux.conf ]]"
	ska_check "vimrc"      "[[ -L ~/.vimrc ]]"
	ska_check "nvim init"  "[[ -L ~/.config/nvim/init.lua ]]"
	ska_check "ssh dir"    "[[ -d ~/.ssh ]]"
	$(call BOLD,\n--- Runtimes (mise) ---)
	ska_check "python"     "mise exec -- python --version"
	ska_check "node"       "mise exec -- node --version"
	ska_check "go"         "mise exec -- go version"
	ska_check "rust"       "mise exec -- rustc --version"
	$(call BOLD,\n--- Directories ---)
	ska_check "/DATA"      "[[ -d /DATA ]]"
	ska_check "/opt/skillarch" "[[ -d /opt/skillarch ]]"
	echo ""
	if [[ "$$FAIL" -eq 0 ]]; then
		$(call OK,$(C_BOLD) All $$TOTAL tests passed!)
	else
		$(call WARN,$(C_BOLD) $$PASS/$$TOTAL passed$(comma) $$FAIL failed)
		$(call INFO,Some failures may be expected if you ran a partial install (e.g.$(comma) lite only))
	fi

test-lite: ## Validate lite Docker image install
	$(call INFO,$(C_BOLD) Running SkillArch LITE smoke tests...)
	@PASS=0 FAIL=0 TOTAL=0
	ska_check() {
		((TOTAL++)) || true
		tool="$$1"
		cmd="$$2"
		if eval "$$cmd" > /dev/null 2>&1 ; then
			$(call OK,  [PASS]$(C_RST) $$tool)
			((PASS++))
		else
			$(call ERR,  [FAIL]$(C_RST) $$tool ($$cmd))
			((FAIL++))
		fi || true
	}
	$(call BOLD,\n--- Core Binaries ---)
	for bin in zsh git nvim tmux nmap curl wget jq rg bat eza trash-put; do
		ska_check "$$bin" "which $$bin"
	done
	$(call BOLD,\n--- Offensive Tools ---)
	for bin in ffuf hashcat bettercap msfconsole gobypass403 wpprobe; do
		ska_check "$$bin" "which $$bin"
	done
	ska_check "hexhttp"   "which hexhttp || [[ -f ~/.local/bin/hexhttp ]]"
	ska_check "nuclei"    "which nuclei || [[ -f ~/.pdtm/go/bin/nuclei ]]"
	ska_check "httpx"     "which httpx || [[ -f ~/.pdtm/go/bin/httpx ]]"
	ska_check "gef"       "[[ -f ~/.gdbinit-gef.py ]]"
	$(call BOLD,\n--- Shell & Config ---)
	ska_check "oh-my-zsh" "[[ -d ~/.oh-my-zsh ]]"
	ska_check "zshrc"     "[[ -L ~/.zshrc ]]"
	ska_check "nvim init" "[[ -L ~/.config/nvim/init.lua ]]"
	$(call BOLD,\n--- Runtimes ---)
	ska_check "python"    "mise exec -- python --version"
	ska_check "node"      "mise exec -- node --version"
	ska_check "go"        "mise exec -- go version"
	echo ""
	if [[ "$$FAIL" -eq 0 ]]; then
		$(call OK,$(C_BOLD) All $$TOTAL lite tests passed!)
	else
		$(call ERR,$(C_BOLD) $$PASS/$$TOTAL passed$(comma) $$FAIL failed)
		exit 1
	fi

test-full: test ## Validate full Docker image install (runs test + extras)
	$(call INFO,$(C_BOLD) Running SkillArch FULL extra tests...)
	@PASS=0 FAIL=0 TOTAL=0
	ska_check() {
		((TOTAL++)) || true
		tool="$$1"
		cmd="$$2"
		if eval "$$cmd" > /dev/null 2>&1 ; then
			$(call OK,  [PASS]$(C_RST) $$tool)
			((PASS++))
		else
			$(call ERR,  [FAIL]$(C_RST) $$tool ($$cmd))
			((FAIL++))
		fi || true
	}
	$(call BOLD,\n--- GUI Binaries ---)
	for bin in i3 kitty polybar rofi picom code; do
		ska_check "$$bin" "which $$bin"
	done
	$(call BOLD,\n--- GUI Config Symlinks ---)
	ska_check "i3 config"      "[[ -L ~/.config/i3/config ]]"
	ska_check "polybar config" "[[ -L ~/.config/polybar/config.ini ]]"
	ska_check "polybar launch" "[[ -L ~/.config/polybar/launch.sh ]]"
	ska_check "kitty config"   "[[ -L ~/.config/kitty/kitty.conf ]]"
	ska_check "picom config"   "[[ -L ~/.config/picom.conf ]]"
	ska_check "rofi config"    "[[ -L ~/.config/rofi/config.rasi ]]"
	$(call BOLD,\n--- Wordlists ---)
	ska_check "/opt/lists"        "[[ -d /opt/lists ]]"
	ska_check "rockyou.txt"       "[[ -f /opt/lists/rockyou.txt ]]"
	ska_check "SecLists"          "[[ -d /opt/lists/SecLists ]]"
	ska_check "PayloadsAllThings" "[[ -d /opt/lists/PayloadsAllTheThings ]]"
	echo ""
	if [[ "$$FAIL" -eq 0 ]]; then
		$(call OK,$(C_BOLD) All $$TOTAL full tests passed!)
	else
		$(call ERR,$(C_BOLD) $$PASS/$$TOTAL passed$(comma) $$FAIL failed)
		exit 1
	fi

# ============================================================
# Diagnostics & Utilities
# ============================================================

doctor: ## Diagnose system health & common issues
	$(call INFO,$(C_BOLD) SkillArch Doctor)
	$(call BOLD,=================\n)
	# Disk space
	$(call BOLD,--- Disk Space ---)
	df -h / /DATA /opt 2>/dev/null | grep -vF "Filesystem" | awk '{printf "  %-20s %s used / %s total (%s)\n", $$6, $$3, $$2, $$5}'
	echo ""
	# Docker daemon
	$(call BOLD,--- Docker ---)
	if docker info > /dev/null 2>&1; then
		echo -e "  $(C_OK)[OK]$(C_RST) Docker daemon running"
		echo "  Images: $$(docker images -q 2>/dev/null | wc -l), Containers: $$(docker ps -aq 2>/dev/null | wc -l)"
	else
		echo -e "  $(C_WARN)[WARN]$(C_RST) Docker daemon not running or not accessible"
	fi
	echo ""
	# Backup files
	$(call BOLD,--- Backed-up Configs (.skabak) ---)
	SKABAK_FILES=$$(find ~ /etc/X11 -name "*.skabak" 2>/dev/null || true)
	if [[ -n "$$SKABAK_FILES" ]]; then
		echo "$$SKABAK_FILES" | while read -r f; do echo "  $$f"; done
	else
		echo "  None found (clean install)"
	fi
	echo ""
	# Broken symlinks
	$(call BOLD,--- Broken Symlinks (config) ---)
	BROKEN=""
	for link in ~/.zshrc ~/.tmux.conf ~/.vimrc ~/.config/nvim/init.lua ~/.config/i3/config ~/.config/polybar/config.ini ~/.config/polybar/launch.sh ~/.config/kitty/kitty.conf ~/.config/picom.conf ~/.config/rofi/config.rasi; do
		if [[ -L "$$link" ]] && [[ ! -e "$$link" ]]; then
			echo -e "  $(C_ERR)[BROKEN]$(C_RST) $$link -> $$(readlink $$link)"
			BROKEN="yes"
		fi
	done
	[[ -z "$$BROKEN" ]] && echo -e "  $(C_OK)[OK]$(C_RST) All config symlinks valid"
	echo ""
	# System info
	$(call BOLD,--- System Info ---)
	echo "  OS: $$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo 'unknown')"
	echo "  Kernel: $$(uname -r)"
	echo "  Shell: $$SHELL"
	echo "  User: $$USER"
	echo "  SkillArch: $$(cd /opt/skillarch 2>/dev/null && git log -1 --format='%h (%cr)' || echo 'unknown')"
	echo ""

list-tools: ## List installed offensive tools & versions
	$(call INFO,$(C_BOLD) SkillArch Tool Inventory)
	$(call BOLD,==========================\n)
	ska_ver() {
		VER=$$(eval "$$2" 2>/dev/null | head -1 || echo "not found")
		printf "  %-20s %s\n" "$$1" "$$VER"
	}
	PATH=$$PATH:~/.local/bin:~/.pdtm/go/bin
	$(call BOLD,--- Core ---)
	ska_ver "git"       "git --version"
	ska_ver "zsh"       "zsh --version"
	ska_ver "nvim"      "nvim --version | head -1"
	ska_ver "tmux"      "tmux -V"
	ska_ver "docker"    "docker --version"
	$(call BOLD,\n--- Runtimes (mise) ---)
	ska_ver "python"    "mise exec -- python --version"
	ska_ver "node"      "mise exec -- node --version"
	ska_ver "go"        "mise exec -- go version"
	ska_ver "rust"      "mise exec -- rustc --version"
	$(call BOLD,\n--- Offensive ---)
	ska_ver "nmap"       "nmap --version | head -1"
	ska_ver "ffuf"       "ffuf -V 2>&1 | head -1"
	ska_ver "nuclei"     "nuclei -version 2>&1 | head -1"
	ska_ver "httpx"      "httpx -version 2>&1 | tail -1"
	ska_ver "subfinder"  "subfinder -version 2>&1 | head -1"
	ska_ver "sqlmap"     "sqlmap --version 2>&1 | head -1"
	ska_ver "hexhttp"    "hexhttp --version 2>&1 | head -1"
	ska_ver "msfconsole" "msfconsole --version 2>&1 | head -1"
	ska_ver "hashcat"    "hashcat --version 2>&1 | head -1"
	ska_ver "bettercap"  "bettercap -version"
	ska_ver "gitleaks"   "gitleaks version 2>&1"
	ska_ver "caido"      "caido --version 2>&1 | head -1"
	ska_ver "ghidra"     "cat /opt/ghidra/bom.json| jq -r '.components[].version'|head -1" ## "echo 'installed (GUI)'"
	ska_ver "wireshark"  "wireshark --version 2>&1 | head -1"
	$(call BOLD,\n--- uv Tools ---)
	eval "$$(mise activate bash)" || true
	uv tool list 2>/dev/null | grep -v '-' | pr -o2 -t || echo "  uv not available"
	$(call BOLD,\n--- Pdtm Tools ---)
	## ls ~/.pdtm/go/bin/ 2>/dev/null | while read -r tool; do echo "  %$$tool"; echo "$$($$tool --version 2>&1|tail -1)"; done || echo "  pdtm not installed"
	pdtm 2>&1 | awk '/^[0-9]+\./ {gsub(/\033\[[0-9;]*[mK]/, ""); sub(/^[0-9]+\./, " "); print}'  || echo "  pdtm not installed"
	echo ""

backup: ## Backup current configs before overwriting
	BACKUP_DIR="$$HOME/.skillarch-backup-$$(date +%Y%m%d-%H%M%S)"
	mkdir -p "$$BACKUP_DIR"
	$(call INFO,Backing up configs to $$BACKUP_DIR)
	for file in ~/.zshrc ~/.tmux.conf ~/.vimrc ~/.config/nvim/init.lua ~/.config/i3/config ~/.config/polybar/config.ini ~/.config/polybar/launch.sh ~/.config/kitty/kitty.conf ~/.config/picom.conf ~/.config/rofi/config.rasi /etc/X11/xorg.conf.d/30-touchpad.conf; do
		if [[ -f "$$file" ]] || [[ -L "$$file" ]]; then
			DEST="$$BACKUP_DIR/$$(basename $$file)"
			cp -L "$$file" "$$DEST" 2>/dev/null && echo "  Backed up: $$file" || true
		fi
	done
	$(call OK,Backup complete: $$BACKUP_DIR)

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
	[[ ! -f /.dockerenv ]] && exit 0
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
