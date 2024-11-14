# dotfiles
Personal *nix and WSL cfg and stuff


## WSL config examples

## System `%UserProfile%/.wslconfig`(windows)
```ini
[wsl2]
swap=0
guiApplications=true
nestedVirtualization=false
vmIdleTimeout=60000
firewall=false

networkingMode=mirrored

[experimental]
sparseVhd=true
hostAddressLoopback=true
```
## Local `/etc/wsl.conf` (in guest)

```ini
[boot]
systemd=true

[network]
hostname=debian.wsl2

[interop]
enabled = true
appendWindowsPath = false
```
