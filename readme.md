# SkillArch - [![Security Checks & Docker Builds](https://github.com/laluka/skillarch/actions/workflows/cicd.yml/badge.svg)](https://github.com/laluka/skillarch/actions/workflows/cicd.yml)

<img src='assets/logo-round-cold.png' width='250'><img src='assets/logo-round-hot.png' width='250'>

> The lite/full install takes 10/15 minutes 🕑️\
> And here is a gentle rice 😇

<img src='assets/rice-01.png' width='800'>

---

## How To Install

### SIMPLE / NO-CUSTOMIZE / NO-BACKUP

> 🔴🎬🙏 Please watch this 5mn intro video to onboard yourself! 🙏🎬🔴

[![](https://img.youtube.com/vi/HB1hxJgGoDo/0.jpg)](https://youtu.be/HB1hxJgGoDo)

- First, download the `Desktop Edition` at https://cachyos.org/download/
- Install it, pick the `Plasma` flavor (SkillArch installs i3 alongside Plasma and reuses KDE's settings and applications)
- In the installer's bootloader step, **pick BIOS (legacy)**; keeps qcow/cloud-image compatibility straightforward; UEFI works but complicates exports
- Then open `Console` and install SkillArch 🥂

```bash
git clone https://github.com/laluka/skillarch
sudo mv skillarch /opt/skillarch && cd /opt/skillarch
make install # Then reboot && pick i3 at login

# Update by running this command (will pull changes & apply them):
ska-update-simple
```

###  ADVANCED / FULL-CUSTOMIZE / FULL-BACKUP

> 🔴🎬🙏 Please watch this 10mn intro video to onboard yourself! 🙏🎬🔴

[![](https://img.youtube.com/vi/Wq6CmJJnTJk/0.jpg)](https://youtu.be/Wq6CmJJnTJk)

1. [Fork this repo](https://github.com/laluka/skillarch/fork)
1. Install `your` SkillArch with the [usual install process](#simple--no-customize--no-backup)
1. Add the upstream source: `git remote add upstream https://github.com/laluka/skillarch.git`
1. When you'll want to `add a tweak` or  `update your setup` 🫶

```bash
# Interactive upstream-merge, just follow the Y/n prompts:
ska-update-advanced

# Under the hood it walks you through:
#   1. detect local changes → prompt to commit + push
#   2. git fetch upstream
#   3. show incoming commit graph + overall diff-stat + FULL patch (pagers disabled)
#   4. prompt to merge upstream/main
#   5. prompt to push origin/main
#   6. prompt to reapply via ska-update-simple (make update && make install)
#   7. show your final drift vs upstream (commits + stat + full patch)
#   8. nudge you toward the SkillArch Discord channel
```

> ⚠️ Remember to NEVER add secrets in your dotfiles 🙏\
> ⚠️ Your fork is also PUBLIC, use `source ~/.myaliases` instead!\
> ⚠️ I know git is hard, but it's so powerful it's worth it, trust me.

---

## Documentation

> 🔴🎬🙏 Please watch this 1h FULL TOUR video so you can make the most out of your SkillArch Adventure! 🙏🎬🔴

[![](https://img.youtube.com/vi/pUm7KEgM2g8/0.jpg)](https://youtu.be/pUm7KEgM2g8)

### Get Help

```bash
make help
# Welcome to SkillArch! <3
#
# Usage: make [target]
# Targets:
#
#   help                Show this help message
#   install             Install SkillArch (full)
#   install-base        Install base packages
#   install-cli-tools   Install CLI tools & runtimes
#   install-shell       Install shell, zsh, oh-my-zsh, fzf, tmux
#   install-docker      Install Docker & Docker Compose
#   install-gui         Install i3, KDE Plasma, and Xfce for KasmVNC
#   install-gui-tools   Install GUI apps (Chrome, VSCode, Ghidra, etc.)
#   install-offensive   Install offensive & security tools
#   install-wordlists   Install wordlists (SecLists, rockyou, etc.)
#   install-hardening   Install hardening tools (opensnitch)
#   cloud               (Standalone) Install KasmVNC + cloud-init for cloud/remote desktop (NOT part of make install)
#   cloud-export        Export a libvirt VM to a clean qcow2 (for Proxmox/DO import)
#   update              Update SkillArch (pull & prompt reinstall)
#   test                Validate installation (smoke tests)
#   test-lite           Validate lite Docker image install
#   test-full           Validate full Docker image install (runs test + extras)
#   doctor              Diagnose system health & common issues
#   list-tools          List installed offensive tools & versions
#   backup              Backup current configs before overwriting
#   docker-build        Build lite Docker image locally
#   docker-build-full   Build full Docker image locally
#   docker-run          Run lite Docker image locally
#   docker-run-full     Run full Docker image locally
#   clean               Clean up system and remove unnecessary files
```

> Or join the SkillArch Discord server 🍀\
> ➡️ https://discord.gg/2T8GGAnwv5 ⬅️\
> Yes, I help in the SkillArch channel, not in DMs! 😇

### Ska Helpers, i3 bindings, aliases, tools

| Alias | Description |
|-------|-------------|
| `ska-help-aliases` | Fuzzy-find aliases |
| `ska-help-bindings` | Fuzzy-find i3 bindings |
| `ska-help-packages` | Fuzzy-find installed packages |
| `ska-sudo-unlock` | Unlock current user after 3 sudo fails |
| `ska-update-simple` | Update SkillArch repo & starts install |
| `ska-update-advanced` | Interactive upstream-merge for forks (prompts at each step) |
| `ska-vnc` | Start a click-friendly Xfce desktop via KasmVNC (browser at https://127.0.0.1:8443) |

### MISC Gotchas

- If `make install` or `ska-update-simple` loop on a y/n question, fix your pacman config first! 😉
- The main config is azerty (shhh I know), here is a reference to [tweak your config back to qwerty](https://github.com/CachyOS/cachyos-i3wm-settings/blob/develop/etc/skel/.config/i3/config)
- Kitty visual/rectangle select is done with `ctrl+alt+click/drag`, you're welcome!
- The docker `latest` is actually the `lite` image with everything CLI related
- The docker `full` image contains GUI stuff and wordlists
- Why `sleep` in `Makefile`? Building TOO fast was triggering github limit-rate
- No [CachyOs on ARM](https://discuss.cachyos.org/t/arm-future-for-cachyos/727), therefore no SkillArch on ARM.
- Chrome extensions are not installed by default. Have a look to [/config/chrome-extensions.lst](/config/chrome-extensions.lst)

### VM Hosts

> **GNOME Boxes is now the first-class citizen** 🥳: zero-config, dead-simple, "just works" with the SkillArch qcow image below. `virt-manager` (from `qemu-full`) remains a great power-user alternative. VirtualBox had too many regressions (not recommended anymore but still supported on a best-effort basis).

- GNOME Boxes: `sudo pacman -S gnome-boxes` (not in SkillArch's default install), launch it, "New" → pick the downloaded qcow, done.
- `virt-manager`: `sudo pacman -S qemu-full virt-manager` then `virt-manager` → New VM → import existing qcow.
- VirtualBox (legacy path):
  - `ska-vbox-install-guestutils`: auto-installs `virtualbox-guest-utils`
  - When i3 starts it runs `VBoxClient-all` for clipboard & goodies
  - Transparency `CAN` work with `picom` but:
    - It requires to enable `enable hardware virtualization`
    - It is basically `very slow` even with a good GPU
    - I advise to `not` use it, but do your things, PR opens!
    - Currently it's only started in i3 while not running in an hypervisor
    - In `~/config/i3/config` : `killall -q picom ; grep -qF hypervisor /proc/cpuinfo || picom`

### Pre-Built SkillArch qcow (no install, just boot)

I maintain a ready-to-boot SkillArch qcow2 image on a private basic-auth mirror. No install needed, just download and boot in GNOME Boxes / virt-manager / Proxmox / any qemu frontend.

```bash
BASE='http://skillarch:mercilaluuu@bs.offenskill.com:42069/skillarch'

# --- List available images ---
curl -s -H 'Accept: application/json' "$BASE/" | jq -r '.[].name' | sort -r

# --- Download the latest in one shot ---
LATEST=$(curl -s -H 'Accept: application/json' "$BASE/" | jq -r '.[].name' | sort -r | head -1)
echo "Downloading: $LATEST"
wget --continue --user-agent='Mozilla/5.0 (X11; Linux x86_64)' "$BASE/$LATEST"
echo "Downloaded: $LATEST"
```

- Image is built from the cloud target (`make cloud`); KasmVNC + cloud-init + SSH already wired.
- BIOS boot (not UEFI); import works everywhere without firmware fiddling.
- Default user: `hacker`, password: `skillarch` ⚠️ **change it on first boot** (`passwd`) -- the image ships with a known password for convenience, do NOT expose it to the internet without changing it first.
- Passwordless sudo enabled (cloud-init).
- See the [Cloud Target](#cloud-target-standalone----make-cloud) section for how the image is produced (`make cloud-export` flattens snapshots, sparsifies, and sysprep's).

#### Boot it with libvirt / virsh (pure CLI, no GUI importer)

Proven reliable params for the SkillArch qcow: q35, host-passthrough CPU, virtio disk/net, qemu-guest-agent, SPICE + QXL:

```bash
QCOW="$PWD/$LATEST"     # from the download block above

virt-install --connect qemu:///session \
  --name skillarch \
  --memory 8192 --vcpus 4 \
  --machine q35 --cpu host-passthrough \
  --osinfo detect=on,require=off \
  --disk path="$QCOW",bus=virtio,format=qcow2 \
  --network network=default,model=virtio \
  --channel unix,target_type=virtio,target_name='org.qemu.guest_agent.0' \
  --rng /dev/urandom \
  --graphics spice --video qxl \
  --import --noautoconsole

# Manage it with virsh:
virsh -c qemu:///session list --all
virsh -c qemu:///session domdisplay skillarch     # prints spice://... URI
virsh -c qemu:///session domifaddr skillarch      # show VM IP once booted
# Connect:   remote-viewer $(virsh -c qemu:///session domdisplay skillarch)
# Or SSH:    ssh hacker@<vm-ip>
# Stop/start/destroy: virsh -c qemu:///session {shutdown,start,destroy} skillarch
```

### Multiple Monitor

1. Open arandr & set your screen layout: Drag & Drop
1. Set your Primary screen: Right Click > Check `Primary`
1. Save your layout: Layout > Save As > `arandr-main-layout.sh`
1. Auto apply layout at login time:

```bash
echo "$HOME/.screenlayout/arandr-main-layout.sh &" > ~/.xprofile
chmod +x ~/.xprofile
# Logout, Login, should work first try!
```

- If for some reasons, multiple polybar appear, it's because no primary monitor is assigned
 - Check it's actually true: `polybar  --list-monitors` # Should have one primary label
 - Fix it by openin `arandr` + right click to set `primary` on your main screen.
 - Reload i3 with `mod+Shift+r`, then make it permanent, aka goto doc `Multiple Monitor`

### Docker Usage

https://hub.docker.com/r/thelaluka/skillarch

```bash
# lite image: CLI only
make docker-run
# full image: GUI stuff with X11 socket mounted!
make docker-run-full
```

### Main i3 bindings & aliases

- For aliases checkout [config/aliases](/config/aliases)

```bash
# Help
bindsym $mod+h exec kitty --title "Help: SkillArch Bindings" zsh -ic "ska-help-bindings"
bindsym $mod+Shift+h exec kitty --title "Help: SkillArch Aliases" zsh -ic "ska-help-aliases"
bindsym $mod+Control+h exec kitty --title "Help: SkillArch packages" zsh -ic "ska-help-packages"

# Sound & Light
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status
bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +20%   # && notify-send --icon=/dev/null --expire-time=500 "Brightness +20%"
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 20%- # && notify-send --icon=/dev/null --expire-time=500 "Brightness -20%"
bindsym $mod+Shift+l exec --no-startup-id brightnessctl set 1%
bindsym $mod+m exec pactl set-source-mute @DEFAULT_SOURCE@ toggle

# Term & Apps
bindsym $mod+Return exec /usr/bin/kitty
bindsym $mod+Shift+Return exec /usr/bin/google-chrome-stable
bindsym $mod+Shift+Q kill
bindsym $mod+space exec --no-startup-id rofi -show drun
bindsym $mod+Shift+space exec --no-startup-id rofi -show run
bindsym $mod+Control+space exec --no-startup-id rofi -show window

# Power & Lock
bindsym $mod+Escape exec rofi -show power-menu -modi power-menu:rofi-power-menu
bindsym $mod+l exec i3lock-fancy -f Bitstream-Vera-Serif -t 'Welcome back to SkillArch'

# Window & Workspace
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right
bindsym $mod+h split h
bindsym $mod+v split v
bindsym $mod+f fullscreen toggle
bindsym $mod+BackSpace split toggle
bindsym $mod+s layout stacking
bindsym $mod+z layout tabbed
bindsym $mod+BackSpace layout toggle split
bindsym $mod+Shift+f floating toggle
bindsym $mod+Shift+BackSpace focus mode_toggle
bindsym $mod+q focus parent
bindsym $mod+ampersand workspace number $ws1
bindsym $mod+eacute workspace number $ws2
bindsym $mod+quotedbl workspace number $ws3
bindsym $mod+apostrophe workspace number $ws4
bindsym $mod+parenleft workspace number $ws5
bindsym $mod+minus workspace number $ws6
bindsym $mod+egrave workspace number $ws7
bindsym $mod+underscore workspace number $ws8
bindsym $mod+ccedilla workspace number $ws9
bindsym $mod+agrave workspace number $ws10
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+eacute move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+egrave move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+ccedilla move container to workspace number $ws9
bindsym $mod+Shift+agrave move container to workspace number $ws10
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

# Resize & Scratchpad
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"
bindsym Left resize shrink width 10 px or 10 ppt
bindsym Down resize grow height 10 px or 10 ppt
bindsym Up resize shrink height 10 px or 10 ppt
bindsym Right resize grow width 10 px or 10 ppt
bindsym Return mode "default"
bindsym Escape mode "default"
bindsym $mod+r mode "default"
bindsym $mod+r mode "resize"
bindsym $mod+shift+a move to scratchpad
bindsym $mod+a scratchpad show

# Custom Apps & Settings
bindsym $mod+p exec flameshot gui
bindsym $mod+Shift+p exec flameshot full -p ~/Pictures/
bindsym $mod+s exec systemsettings kcm_pulseaudio
bindsym $mod+shift+s exec pavucontrol
bindsym $mod+e exec emote
bindsym $mod+b exec blueman-manager
bindsym $mod+w exec systemsettings kcm_networkmanagement
bindsym $mod+n exec thunar
bindsym $mod+v exec vlc
bindsym $mod+c exec code
```

### Installed Packages, Plugins, Tools

- For an exhaustive view inspect [/Makefile](/Makefile)

```bash
# Pacman Packages
arandr asciinema base-devel bat bettercap bison blueman bore bottom brightnessctl bzip2 ca-certificates cachyos-kde-settings cloc cmake visual-studio-code-bin curl discord dmenu docker docker-compose dos2unix dragon-drop-git dunst emote eza expect fastfetch feh ffmpeg filezilla flameshot foremost fq fx gdb ghex ghidra git git-delta gitleaks glow gnupg google-chrome gparted gron guvcview hashcat htmlq htop hwinfo xorg-server i3-gaps i3blocks i3lock i3lock-fancy-git i3status icu inotify-tools iproute2 jless jq kdenlive kitty kompare lazygit libedit libffi libjpeg-turbo libpcap libpng libreoffice-fresh libxml2 libzip llvm lsof ltrace make meld metasploit mise mlocate mplayer ncurses neovim net-tools ngrep nm-connection-editor nmap okular opencode opensnitch openssh openssl parallel perl-image-exiftool php-gd picom pkgconf plasma-meta polybar postgresql-libs python-virtualenv qbittorrent re2c readline ripgrep rlwrap rofi signal-desktop socat sqlite sshpass superfile sysstat tmate tmux tor torbrowser-launcher traceroute trash-cli tree unzip vbindiff veracrypt vim viu vlc vlc-plugin-ffmpeg flatpak websocat wget wireshark-qt xclip qsv xfce4-appfinder xfce4-panel xfce4-session xfce4-settings xfce4-terminal xfdesktop xfwm4 xz yay zip zsh zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting zsh-theme-powerlevel10k cronie tree-sitter audacity xorg-xhost archlinux-keyring jdk21-openjdk polkit-kde-agent kamoso plasma-desktop konsole alacritty thunar thunar-archive-plugin thunar-volman tumbler ffmpegthumbnailer gvfs gvfs-mtp file-roller

# Yay packages
ffuf gau waybackurls fswebcam caido-desktop caido-cli i3-battery-popup-git rofi-power-menu fabric-ai-bin

# Yay packages (cloud target only, not part of make install)
openssl-1.1 kasmvncserver-bin

# Flatpak packages
com.obsproject.Studio

# Mise tools
uv usage pdm rust terraform golang python nodejs pdtm (aqua:projectdiscovery/pdtm)

# Source builds (into ~/bin)
blechschmidt/massdns (required by shuffledns)

# Mise golang tools
sw33tLie/sns glitchedgitz/cook x90skysn3k/brutespray sensepost/gowitness

# GitHub binary releases
slicingmelon/gobypass403 Chocapikk/wpprobe

# Pdtm tools
aix alterx asnmap cdncheck chaos-client cloudlist cvemap dnsx httpx interactsh-client interactsh-server katana mapcidr naabu notify nuclei proxify shuffledns simplehttpserver subfinder tldfinder tlsx tunnelx uncover urlfinder

# Python uv tools
argcomplete bypass-url-parser exegol pre-commit sqlmap wafw00f yt-dlp semgrep defaultcreds-cheat-sheet

# OMZ plugins
colored-man-pages docker extract fzf mise npm terraform tmux zsh-autosuggestions zsh-completions zsh-syntax-highlighting ssh-agent z

# VsCode Extensions
bibhasdn.unique-lines
eriklynd.json-tools
mechatroner.rainbow-csv
mitchdenny.ecdc
ms-azuretools.vscode-docker
ms-python.debugpy
ms-python.python
ms-python.vscode-pylance
ms-vscode-remote.remote-containers
ms-vscode-remote.remote-ssh
ms-vscode-remote.remote-ssh-edit
ms-vscode.remote-explorer
ms-vsliveshare.vsliveshare
pomdtr.excalidraw-editor
trailofbits.weaudit
yzane.markdown-pdf
zobo.php-intellisense

# Cloned Tools
https://github.com/LazyVim/starter
https://github.com/jpillora/chisel
https://github.com/ambionics/phpggc
https://github.com/CBHue/PyFuscation
https://github.com/christophetd/CloudFlair
https://github.com/minos-org/minos-static
https://github.com/offensive-security/exploit-database
https://gitlab.com/exploit-database/exploitdb
https://github.com/laluka/pty4all
https://github.com/laluka/pypotomux
https://github.com/hugsy/gef
https://github.com/c0dejump/HExHTTP

# Clones Wordlists
https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
https://github.com/swisskyrepo/PayloadsAllTheThings
https://github.com/1N3/BruteX
https://github.com/1N3/IntruderPayloads
https://github.com/berzerk0/Probable-Wordlists
https://github.com/cujanovic/Open-Redirect-Payloads
https://github.com/danielmiessler/SecLists
https://github.com/ignis-sec/Pwdb-Public
https://github.com/Karanxa/Bug-Bounty-Wordlists
https://github.com/tarraschk/richelieu
https://github.com/p0dalirius/webapp-wordlists
```

### Services

The following systemd services are installed but **disabled and stopped by default**. Enable only what you need:

| Service | Package | Start | Enable at Boot | Purpose |
|---------|---------|-------|---------------|---------|
| `docker` | `docker` | auto-started on install (bare metal) | yes (bare metal) | Container runtime |
| `opensnitchd` | `opensnitch` | `sudo systemctl start opensnitchd` | `sudo systemctl enable opensnitchd` | Egress firewall (opt-in) |
### Cloud Target (standalone -- `make cloud`)

> **Not part of `make install`** -- this is a standalone target for cloud/remote desktop VMs.

Installs KasmVNC + cloud-init + SSH. After `make install-gui` and `make cloud`, the `ska-vnc` alias starts a conventional Xfce desktop in KasmVNC's X11 server, accessible from a browser and comfortable with mouse or touch input. Plasma remains available as the local Wayland desktop, and i3 remains available locally.

| Service | Package | Start | Purpose |
|---------|---------|-------|---------|
| *(user-level)* | `kasmvncserver-bin` | `ska-vnc` | Xfce desktop via browser (VNC over websocket) |
| `sshd` | `openssh` | auto-enabled | SSH access |
| `cloud-init` | `cloud-init` | auto-enabled | VM auto-config (network, SSH keys, hostname) |

**Quick start:**

```bash
ska-vnc
# KasmVNC running on https://127.0.0.1:8443 (no auth)

# From your local machine, SSH port-forward then open in browser:
ssh -L 8443:localhost:8443 user@host
# Access: https://localhost:8443

# Stop:
vncserver -kill :1
```

**How it works:** Plasma 6.8 no longer provides an X11 session, while KasmVNC provides an X server rather than a Wayland compositor. The `vnc-xstartup` script therefore starts Xfce for a familiar panel/menu/desktop workflow and forces software rendering for Qt/KDE applications because Xvnc has no GLX extension.

#### Experimental browser desktop: KDE Plasma on Wayland

This standalone Docker Compose experiment uses [Selkies](https://github.com/selkies-project/docker-selkies-egl-desktop) to stream a headless Plasma Wayland session over a single HTTPS port. The pinned Ubuntu image ships Plasma 6.6.6, uses software rendering in this configuration, and downloads about 2.4 GiB on ARM64. Use it to evaluate the desktop and browser experience. Testing Plasma 6.8 on CachyOS with the SkillArch tools, dotfiles, and `/DATA` would need a separate integration pass.

```bash
export SKA_KDE_PASSWORD="$(openssl rand -hex 16)"
docker compose -f compose.kde-experiment.yml up -d
```

Open <https://localhost:8444> and sign in as `ubuntu` with the generated password (`printenv SKA_KDE_PASSWORD`). Selkies generates a self-signed certificate. For a remote Docker host, forward its loopback port with `ssh -L 8444:127.0.0.1:8444 user@host` and open the same URL locally.

Open Konsole and run `printenv WAYLAND_DISPLAY` to check the session. Try the application menu, browser resizing, clipboard, and touch input before comparing it with the Xfce session. Use `docker compose -f compose.kde-experiment.yml down` to remove the test container and its session state.

### Security

- `opensnitch` is here to help you block outgoing packets and connections (opt-in, start manually)
- `ufw` is here to help you block incoming packets and requests
- Be careful though, [docker iptables shenanigans bypass ufw rules](https://richincapie.medium.com/docker-ufw-and-iptables-a-security-flaw-you-need-to-solve-now-40c85587b563)

---

## Main Changes Since [Lalubuntu](https://github.com/laluka/lalubuntu)

| What | Lalubuntu | SkillArch |
|------|-----------|-----------|
| OS | Ubuntu | Arch |
| Install time | 60mn | 20mn |
| Terminal | Gnome Terminal | Kitty |
| i3 config | regolith | homemade |
| Install tool | ansible | Makefile |
| Img builds | packer | docker |
| Images | base,offensive,gui | lite,full |
| Quality of Life | decent | wow! |

---

## Kudos

> Let's be honest, I put stuff together, but the heavy lifting is done by these true gods 😉

- https://github.com/bernsteining/beep-beep
- https://github.com/CachyOS/cachyos-desktop
- https://github.com/davatorium/rofi
- https://github.com/Hyde-project/hyde
- https://github.com/jluttine/rofi-power-menu
- https://github.com/newmanls/rofi-themes-collection
- https://github.com/orhun/config
- https://github.com/regolith-linux/regolith-desktop
