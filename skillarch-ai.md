# SkillArch AI Skill

> Load this file as a skill in Claude Code or opencode to get full awareness of the SkillArch hacker workstation: tools, aliases, bindings, services, and workflows.

---

## Environment

- **OS**: CachyOS (Arch Linux, performance-tuned)
- **Shell**: Zsh + Oh-My-Zsh + Powerlevel10k (`af-magic` theme)
- **WM/DE**: i3-gaps (local X11) + KDE Plasma (Wayland, local or browser remote desktop)
- **Editors**: Neovim (LazyVim), VS Code (`code`)
- **Install root**: `/opt/skillarch/` — all dotfiles symlinked from here
- **Data root**: `/DATA/` — long-lived user data
- **Wordlists**: `/opt/lists/`
- **Offensive tools**: mix of pacman, yay, pdtm, uv, go, GitHub releases, git clones

---

## Make Targets

```bash
make install            # Full install (~15 min), logs to /var/tmp/skillarch-install_<date>.log
make install-base       # Repo setup, pacman config, chaotic-aur, /DATA dir
make install-cli-tools  # CLI tools, mise runtimes (Python/Node/Go/Rust), uv tools, neovim+LazyVim
make install-shell      # Zsh, oh-my-zsh, fzf, tmux, vim, dotfile symlinks
make install-docker     # Docker + Docker Compose, user added to docker group
make install-gui        # i3, KDE Plasma, and GUI/touchpad config
make install-remote-desktop # KRDP, PipeWire, and WirePlumber for the full Docker image
make install-gui-tools  # Chrome, VSCode, Ghidra, Discord, VLC, Wireshark
make install-offensive  # Metasploit, ffuf, pdtm tools, go binaries, GitHub releases, cloned tools
make install-wordlists  # All wordlists to /opt/lists/
make install-hardening  # opensnitch (installed, opt-in)
make update             # git pull + prompt to re-run make install
make cloud              # (Standalone, NOT in make install) cloud-init and SSH
make test               # Full smoke tests
make test-lite          # Lite Docker image smoke tests
make test-full          # Full Docker image smoke tests (GUI + wordlists)
make doctor             # Diagnose disk space, Docker, broken symlinks, .skabak files
make list-tools         # Print versions of all installed offensive tools
make backup             # Backup current dotfiles to timestamped dir
make docker-build       # Build thelaluka/skillarch:lite locally
make docker-build-full  # Build thelaluka/skillarch:full locally
make docker-run         # Run lite container (--net=host, /tmp volume)
make docker-run-full    # Run full container with X11 socket (GUI)
make docker-run-remote  # Run full container with the Plasma browser desktop
make docker-stop-remote # Remove the browser desktop containers and session state
make clean              # Docker-only: clear caches (pacman, yay, pip, mise, go, npm, logs)
```

---

## Shell Aliases (config/aliases)

### SkillArch Helpers
| Alias | Action |
|---|---|
| `ska` | `cd /opt/skillarch` |
| `skao` | `cd /opt/skillarch-original` |
| `ska-help-aliases` | fzf fuzzy-search all aliases |
| `ska-help-bindings` | fzf fuzzy-search i3 keybindings |
| `ska-help-packages` | fzf fuzzy-search installed pacman packages |
| `ska-update-simple` | `ska && make update && make install` |
| `ska-update-advanced` | Interactive upstream-merge for forks (commit local → fetch → preview → merge → push → reapply, all Y/n-prompted) |
| `ska-sudo-unlock` | Reset faillock after 3 bad sudo attempts |
| `ska-remote` | Start the full Docker image's Plasma desktop in a browser |
| `ska-vbox-install-guestutils` | Install VirtualBox guest utils |
| `fastfetch` / `neofetch` / `hifetch` | fastfetch with SkillArch logo |

### Editors & Navigation
| Alias | Action |
|---|---|
| `v` | `nvim` |
| `c` | `code` |
| `C` | `code .` |
| `p` | `python` |
| `b` | `bat` |
| `batall` | `find . -type f \| xargs bat` |
| `batsh` | `bat -l sh` (Bash/Zsh/Shell syntax) |
| `dl` | `cd ~/Downloads` |
| `da` | `cd /DATA` |
| `cdtmp` | `pushd $(mktemp -d)` |
| `ff` | `find . -iname "*<arg>*"` |

### File Management
| Alias | Action |
|---|---|
| `l` | `eza -ll --group-directories-first` |
| `la` | `l -a` |
| `t` / `t2` / `t3` | eza tree (depth 1/2/3) |
| `rm` | `trash-put` (safe delete) |
| `te` | `trash-empty` |

### Git
| Alias | Action |
|---|---|
| `git-clone-all-github` | Clone all repos from `$GITHUB_USER` via API |
| `git-clone-all-gitlab` | Clone all owned GitLab repos |
| `git-pull-all` | `git pull` in all subdirs (parallel) |
| `gdh` | `git diff HEAD` |
| `gst` | `git status --short` |

### Networking
| Alias | Action |
|---|---|
| `ipa` / `ipaa` | `ip -br a` (filter/full) |
| `nc` | `ncat` |
| `ncl` | `ncat -lnvp` (listen) |
| `ssh-yolo` | SSH ignoring host key checks |
| `get-ip` | Public IP via ipinfo.io |
| `pub` | Public IP to clipboard |
| `dns-1/8/9/127` | Switch DNS to 1.1.1.1/8.8.8.8/9.9.9.9/127.0.0.1 |
| `ipv6-disable` / `ipv6-enable` | Toggle IPv6 via sysctl |
| `digall` | `dig +answer +multiline <domain> any @8.8.8.8` |

### Web Fuzzing
| Alias | Action |
|---|---|
| `fu` | ffuf with JSON output, browser UA, `-mc all` |
| `lfu` | ffuf + save JSON + auto-filter results |
| `cfu` | Parse ffuf JSON: status/length/lines/words/url |
| `cfu-clean` | Deduplicated cfu output |
| `cfu-clean-url` | URLs only from cfu-clean |
| `crl` | curl with real browser UA |
| `crli` | crl + dump response headers to stderr |
| `crlix` | crli proxied through Caido (127.0.0.1:8080) |
| `probe-urls` | Bulk HTTP probe from URL list file |

### Web Recon
| Alias | Action |
|---|---|
| `getinfo-known-creds` | Open cirt.net for default creds |
| `getinfo-known-port` | Open speedguide.net for port info |
| `getinfo-bookhacktricks` | Search HackTricks |
| `getinfo-certspotter` | CT log lookup via certspotter API |
| `getinfo-virustotal` | Open VirusTotal for domain |
| `getinfo-crtsh` | crt.sh JSON certificate search |
| `getinfo-wayback` | Wayback Machine URL enumeration |
| `getinfo-leakix` | LeakIX hostname/IP graph lookup |

### Encoding & Data
> Most converters accept either an argument or stdin (via `args_to_stdin`), so `b64 foo` and `echo foo \| b64` both work and chain naturally.

| Alias / Function | Action |
|---|---|
| `b64` / `b64d` / `b64e` | base64 encode (alias `b64e`=`b64`) / decode |
| `b64url` / `b64urld` / `b64urle` | base64 url-safe encode / decode |
| `toHex` / `fromHex` (aliases `hexe`/`hexd`) | hex encode / decode |
| `hex2py` / `hex2c` | Format hex as Python list / C `\xNN` string |
| `toDec` / `fromDec` | Decimal encode / decode |
| `base10to16` / `base16to10` / `base10to2` / `base2to10` (+ short aliases `10to16` etc.) | base conversion via `bc` |
| `urlencode` / `urldecode` / `urlencodeall` (aliases `urle`/`urld`/`urleall`) | URL encode/decode |
| `htmlencode` / `htmlunescape` / `xmlescape` / `xmlunescape` | HTML/XML entity encode/decode |
| `jsonescape` / `jsonunescape` | JSON string escape/unescape |
| `unicodeencode` / `unicodedecode` / `unicodeencodeall` | `\uNNNN` escape |
| `utf16le` / `utf16be` / `utf16to8` / `utf8toLatin` / `latinToUtf8` | iconv shortcuts |
| `nthash` / `NThash` | NTLM hash (lowercase / uppercase) |
| `md5` / `sha1` / `sha256` | One-shot hash, hex digest only |
| `toUpper` / `toLower` | Case transforms |
| `xor` / `xorh` | XOR text/hex with key (also accepts pipe input) |
| `fromEpoch` | Unix timestamp → ISO-8601 |
| `nocolor` | Strip ANSI color codes |
| `nonullbyte` (alias `nnb`) | Strip null bytes |
| `get-badchars` | Print common injection characters |
| `get-bytes-hex/raw/url` | All 256 bytes in hex/raw/URL form |
| `get-chars` / `get-alpha` / `get-alphanum` | Printable / alpha / alphanumeric character sets |
| `get-homoglyph` | Homoglyph confusables for input chars (uses `/opt/lists/confusables.txt`) |
| `suc` / `suq` | `sort\|uniq -c\|sort -h` / `sort -u` shortcuts |
| `fzf-w` | fzf-pick a wordlist from `/opt/lists` |

### Monitoring & System
| Alias | Action |
|---|---|
| `show-disk-io` / `sdi` | `watch iostat -h` |
| `show-open-ports` / `sop` | `ss -lntup` (all listening TCP + UDP ports) |
| `get-du` | `du -ch -d 1` |
| `dirmon` | `inotifywait` recursive file monitoring |
| `get-pid-click` | Click a window to get its PID |
| `get-pid-ps` | fzf-select process to get PID |
| `killit` | `sudo kill -KILL` |

### Python
| Alias | Action |
|---|---|
| `pv 3.12` | Create mise-managed Python venv (version arg required) |
| `pyreq` | `pip install -r requirements.txt` |
| `pysrv` | HTTP server from empty /tmp dir |
| `uvv` | `uv venv .venv && source .venv/bin/activate` |
| `uvr` | `uv run` |
| `uvp` | `uv pip install` |
| `uvreq` | `uv pip install -r requirements.txt` |
| `uva` | `uv add --script` (add lib to script or via requirements.txt) |
| `uvpwn` | `uvx --with pwntools python` |

### Misc
| Alias | Action |
|---|---|
| `upload` | Upload file to 0x0.st |
| `cpy` | Copy stdin to clipboard (xclip) |
| `paste` | Paste from clipboard |
| `cheat` | `curl cheat.sh/<arg>` |
| `fab` | `fabric-ai -s` (AI-powered text processing) |
| `nosleep` | Prevent system sleep (systemd-inhibit) |
| `makeqrcode` | QR code in terminal |
| `get-meteo` | `curl wttr.in` weather |
| `nocolor` | Strip ANSI codes from stdin |

### Docker Management
| Alias | Action |
|---|---|
| `dockit` | `docker run --rm -it -v /tmp:/tmp -v "$PWD":/skahost -w /skahost` |
| `dex` | fzf-select container + exec into it |
| `dexr` | fzf-select container + exec as root |
| `dockns` | nsenter into container's namespaces |
| `dps` | `docker ps` |
| `dstopall` | Stop all containers |
| `dkillall` | Disable restart + stop all |
| `dwipe-all` | Full docker system prune |
| `di` / `dip` | Inspect container (fzf) / grep IPs |

### Docker Security Tools (use via `dockit`)
| Alias | Tool | Purpose |
|---|---|---|
| `dtrufflehog` | trufflesecurity/trufflehog | Secret scanning in git history |
| `dgitleaks` | zricethezav/gitleaks | Secret scanning |
| `drecon-amass` | caffix/amass | Subdomain enumeration |
| `drecon-findomain` | edu4rdshl/findomain | Fast subdomain discovery |
| `drecon-wappa` | wappalyzer/cli | Tech fingerprinting |
| `dsecator` | freelabz/secator | Normalize offensive arsenal |
| `drustscan` | rustscan/rustscan | Fast port scanner |
| `doneforall` | shmilylty/oneforall | Comprehensive recon |
| `dssh-audit` | positronsecurity/ssh-audit | SSH config audit |
| `dssl-test` | drwetter/testssl.sh | TLS/SSL testing |
| `djohn` | phocean/john_the_ripper_jumbo | Password cracking |
| `djwt-tool` | ticarpi/jwt_tool | JWT testing |
| `dhashcat` | dizcza/docker-hashcat | GPU hash cracking |
| `dmsfconsole` / `dmsfvenom` | metasploitframework | Metasploit |
| `dwpscan` | wpscanteam/wpscan | WordPress scanner |
| `ddroopescan` | droope/droopescan | Drupal scanner |
| `dretdec` | blacktop/retdec | Binary → C decompiler |
| `dsysdig` | sysdig/sysdig | System-level introspection |
| `dcarbonyl` | fathyb/carbonyl | Chrome in terminal |

---

## i3 Keybindings

`$mod` = Super/Win key

### Launch & System
| Binding | Action |
|---|---|
| `$mod+Return` | Open Kitty terminal |
| `$mod+Shift+Return` | Open Google Chrome |
| `$mod+space` | Rofi app launcher (drun) |
| `$mod+Shift+space` | Rofi run launcher |
| `$mod+Control+space` | Rofi window switcher |
| `$mod+Escape` | Rofi power menu (shutdown/reboot/logout/suspend) |
| `$mod+l` | Lock screen (i3lock-fancy) |
| `$mod+Shift+Q` | Kill focused window |
| `$mod+Shift+c` | Reload i3 config |
| `$mod+Shift+r` | Restart i3 inplace |
| `$mod+Shift+e` | Exit i3 (with confirmation) |

### Apps
| Binding | Action |
|---|---|
| `$mod+c` | VS Code |
| `$mod+v` | VLC |
| `$mod+p` | Flameshot GUI (screenshot) |
| `$mod+Shift+p` | Flameshot full → ~/Pictures/ |
| `$mod+s` | KDE Sound settings (Plasma audio panel) |
| `$mod+Shift+s` | PulseAudio volume control (pavucontrol) |
| `$mod+e` | Emote (emoji picker) |
| `$mod+b` | Blueman (Bluetooth) |
| `$mod+w` | KDE WiFi/Network settings |
| `$mod+n` | Thunar file manager |
| `$mod+m` | Toggle microphone mute |

### Help
| Binding | Action |
|---|---|
| `$mod+h` | fzf i3 bindings |
| `$mod+Shift+h` | fzf shell aliases |
| `$mod+Control+h` | fzf installed packages |

### Window & Workspace
| Binding | Action |
|---|---|
| `$mod+Arrow` | Focus window (directional) |
| `$mod+Shift+Arrow` | Move window (directional) |
| `$mod+f` | Fullscreen toggle |
| `$mod+Shift+f` | Floating toggle |
| `$mod+BackSpace` | Split toggle |
| `$mod+Shift+BackSpace` | Focus mode toggle |
| `$mod+shift+a` | Move to scratchpad |
| `$mod+a` | Show scratchpad |
| `$mod+r` | Resize mode |
| `$mod+1..0` | Switch workspace (AZERTY: `&éàçèù-_`) |
| `$mod+Shift+1..0` | Move container to workspace |

### Audio/Brightness
| Binding | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume +10% |
| `XF86AudioLowerVolume` | Volume -10% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86MonBrightnessUp/Down` | Brightness ±20% |
| `$mod+Shift+l` | Set brightness to 1% |

---

## Installed Tools

### GUI / Desktops (pacman)
`i3-wm`, `polybar`, `rofi`, `picom`, `kitty`, `plasma-meta` (Wayland). The full Docker image also installs `krdp`, `pipewire`, `wireplumber`, `xorg-xwayland`, and `mesa` via pacman for remote Plasma sessions.

### CLI & Productivity (pacman)
`bat`, `eza`, `fzf`, `ripgrep`, `fd`, `jq`, `glow`, `jless`, `gron`, `htmlq`, `qsv`, `viu`, `superfile`, `fastfetch`, `asciinema`, `bottom`, `htop`, `tmux`, `git-delta`, `lazygit`, `fq`, `fx`, `websocat`, `cloc`, `tree`, `rlwrap`, `parallel`, `tmate`, `trash-cli`, `sysstat`, `inotify-tools`

### Security / Offensive (pacman)
`metasploit` (msfconsole, msfvenom), `hashcat`, `bettercap`, `nmap`, `wireshark-qt`, `ghidra`, `gdb+gef`, `gitleaks`, `opensnitch`, `bore` (TCP NAT tunnel — `bore local <PORT> --to bore.pub`)

### Security / Offensive (yay/AUR)
`ffuf`, `gau`, `waybackurls`, `fabric-ai-bin`, `caido-desktop`, `caido-cli`, `gobypass403` (GitHub release), `wpprobe` (GitHub release)

### pdtm Tools (Project Discovery)
`pdtm` itself is installed via mise (`aqua:projectdiscovery/pdtm`), then `pdtm -ia` pulls the tools below. `massdns` (built from source into `~/bin`) backs `shuffledns`.
`aix`, `alterx`, `asnmap`, `cdncheck`, `chaos-client`, `cloudlist`, `cvemap`, `dnsx`, `httpx`, `interactsh-client`, `interactsh-server`, `katana`, `mapcidr`, `naabu`, `notify`, `nuclei`, `proxify`, `shuffledns`, `simplehttpserver`, `subfinder`, `tldfinder`, `tlsx`, `tunnelx`, `uncover`, `urlfinder`

### Python uv Tools
`sqlmap`, `wafw00f`, `bypass-url-parser`, `exegol`, `semgrep`, `pre-commit`, `argcomplete`, `yt-dlp`, `defaultcreds-cheat-sheet`

### Go Tools (mise exec)
`sns` (sw33tLie), `cook` (glitchedgitz), `brutespray` (x90skysn3k), `gowitness` (sensepost)

### Cloned Tools (/opt/)
| Path | Repo | Purpose |
|---|---|---|
| `/opt/chisel` | jpillora/chisel | TCP tunnel via HTTP |
| `/opt/phpggc` | ambionics/phpggc | PHP gadget chain generator |
| `/opt/PyFuscation` | CBHue/PyFuscation | Python obfuscator |
| `/opt/CloudFlair` | christophetd/CloudFlair | Cloudflare origin IP finder |
| `/opt/minos-static` | minos-org/minos-static | Static Linux binaries |
| `/opt/exploit-database` | offensive-security/exploit-database | ExploitDB offline |
| `/opt/exploitdb` | exploit-database/exploitdb | ExploitDB (GitLab mirror) |
| `/opt/pty4all` | laluka/pty4all | PTY helper for shells |
| `/opt/pypotomux` | laluka/pypotomux | tmux session multiplexer |
| `/opt/HExHTTP` | c0dejump/HExHTTP | HTTP header vuln / cache-poisoning scanner (isolated venv, `hexhttp -u https://target.tld/`) |

### Runtimes (mise)
`python` (latest), `nodejs` (latest), `golang` (latest), `rust` (latest), `uv`, `pdm`, `terraform`

---

## Wordlists (/opt/lists/)

| Path | Source | Content |
|---|---|---|
| `rockyou.txt` | brannondorsey/naive-hashcat | Classic password list |
| `SecLists/` | danielmiessler/SecLists | Comprehensive security lists |
| `PayloadsAllTheThings/` | swisskyrepo/PayloadsAllTheThings | Web attack payloads |
| `BruteX/` | 1N3/BruteX | Brute-force wordlists |
| `IntruderPayloads/` | 1N3/IntruderPayloads | Fuzzing/intruder payloads |
| `Probable-Wordlists/` | berzerk0/Probable-Wordlists | Statistically likely passwords |
| `Open-Redirect-Payloads/` | cujanovic/Open-Redirect-Payloads | Open redirect bypass list |
| `Pwdb-Public/` | ignis-sec/Pwdb-Public | Pwned passwords DB |
| `Bug-Bounty-Wordlists/` | Karanxa/Bug-Bounty-Wordlists | Bug bounty paths |
| `richelieu/` | tarraschk/richelieu | French passwords |
| `webapp-wordlists/` | p0dalirius/webapp-wordlists | Web app specific lists |

---

## Services

All services below are **disabled/stopped by default** unless noted:

| Service | Status | Start | Purpose |
|---|---|---|---|
| `docker` | enabled (bare metal) | auto | Container runtime |
| `opensnitchd` | disabled (opt-in) | `sudo systemctl start opensnitchd` | Egress firewall |
### Cloud Target (`make cloud` — standalone, NOT part of `make install`)

Configures cloud-init and SSH. The full Docker image runs Plasma on KWin's virtual display and streams it through KRDP and Apache Guacamole. The Linux Docker daemon host needs `/dev/udmabuf`; Make discovers the device group inside Docker. The browser port is published on host loopback and the RDP service stays on the Compose network.

```bash
export SKA_REMOTE_PASSWORD="$(openssl rand -hex 16)"
make docker-run-remote  # after make docker-build-full
# Local SSH tunnel for a cloud VM:
ssh -L 8080:127.0.0.1:8080 user@host
```

Open `http://localhost:8080/guacamole/` and sign in as `hacker` using `SKA_REMOTE_PASSWORD`. Ctrl+C stops the stack. `make docker-stop-remote` removes the stopped containers and writable session state.

---

## Dotfile Symlinks

All configs live in `/opt/skillarch/config/` and are symlinked into `$HOME`:

| Symlink | Source |
|---|---|
| `~/.zshrc` | `config/zshrc` |
| `~/.tmux.conf` | `config/tmux.conf` |
| `~/.vimrc` | `config/vimrc` |
| `~/.config/nvim/init.lua` | `config/nvim/init.lua` |
| `~/.config/i3/config` | `config/i3/config` |
| `~/.config/polybar/config.ini` | `config/polybar/config.ini` |
| `~/.config/polybar/launch.sh` | `config/polybar/launch.sh` |
| `~/.config/kitty/kitty.conf` | `config/kitty/kitty.conf` |
| `~/.config/picom.conf` | `config/picom.conf` |
| `~/.config/rofi/config.rasi` | `config/rofi/config.rasi` |
| `~/.config/flameshot/flameshot.ini` | `config/flameshot/flameshot.ini` |
| `/etc/X11/xorg.conf.d/30-touchpad.conf` | `config/xorg.conf.d/30-touchpad.conf` |

---

## Common Workflows

### Recon Pipeline
```bash
subfinder -d target.com | httpx -title -tech-detect | tee alive.txt
katana -u https://target.com -o urls.txt
nuclei -l alive.txt -t ~/.nuclei-templates
gau target.com | uro | httpx
```

### Web Fuzzing
```bash
lfu -u https://target.com/FUZZ -w /opt/lists/SecLists/Discovery/Web-Content/raft-medium-files.txt
cfu fu-output.json
```

### Curl + Caido Proxy
```bash
crlix https://target.com/api/endpoint -d '{"foo":"bar"}'
# crlix = curl + headers dump + proxy to 127.0.0.1:8080
```

### Password Cracking
```bash
hashcat -a 0 -m 0 hashes.txt /opt/lists/rockyou.txt
hashcat -a 0 -m 1000 ntlm.txt /opt/lists/SecLists/Passwords/Leaked-Databases/rockyou.txt
```

### Network Recon
```bash
nmap -sV -sC -oA scan target.com
naabu -host target.com -p - | httpx
bettercap -iface eth0
```

### Exploit Dev / GDB
```bash
gdb ./binary
# GEF auto-loaded: pattern create, checksec, vmmap, rop, etc.
```

### Python Virtualenv
```bash
pv 3.12        # Creates .venv with mise in current dir
pyreq          # pip install -r requirements.txt
```

### Secret Scanning
```bash
gitleaks detect --source . --report-format sarif --report-path gitleaks.sarif
dtrufflehog git file://. --only-verified
```

### Docker Quick Run
```bash
dockit ubuntu:latest bash              # Run any image with cwd mounted
dex                                    # fzf-exec into running container
dexr                                   # same, as root
```

---

## Tips

- `ska-help-aliases` — interactive fzf search of all aliases (use it!)
- `ska-help-bindings` — interactive fzf search of all i3 keybindings
- `source ~/.myaliases` — private aliases for secrets/tokens (never commit this file)
- Kitty rectangle select: `ctrl+alt+click/drag`
- Keyboard layout is AZERTY by default; workspace numbers use `&éàçèù-_çà`
- picom transparency is disabled inside hypervisors (auto-detected via `/proc/cpuinfo`)
- `make doctor` — check for broken symlinks, disk space, Docker health
- `make list-tools` — print versions of all major tools
- Add `source ~/.myaliases` in `~/.zshrc` for private/sensitive aliases that should not be committed
