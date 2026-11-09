# Windows MSI installer

`go.wxs` packages an unpacked `go-legacy-win7` release tree into a per-machine
Windows Installer package. The installer:

- installs to `C:\Program Files\Go` by default (the directory can be changed in
  the wizard);
- appends `<install dir>\bin` to the system `PATH`, and removes it on uninstall;
- registers the installation in Programs and Features;
- upgrades older versions in place, including rebuilds with the same
  `major.minor.patch` version.

It deliberately does not set `GOROOT`. The `go` command finds its own root, and
a system-wide `GOROOT` breaks as soon as a second toolchain is installed.

## Build

WiX builds MSI packages only on Windows. Install WiX 6 once:

```powershell
dotnet tool install --global wix --version 6.0.2
wix extension add -g WixToolset.UI.wixext/6.0.2
```

Then unzip a Windows release and point the script at the unpacked tree:

```powershell
Expand-Archive go-legacy-win7-1.27.3.windows_amd64.zip release
.\installer\wix\build.ps1 -SourceDir release\go-legacy-win7 -Version 1.27.3
```

For unattended deployments, `INSTALLFOLDER` is a public property:

```powershell
msiexec /i go-legacy-win7-1.27.3.windows_amd64.msi /qn INSTALLFOLDER="D:\Go"
```

The release workflow does this automatically for `windows_amd64`: it uploads
the cleaned release zip as an artifact, builds the MSI on `windows-latest`, and
attaches the result to the same draft release.

Only the 64-bit build gets an installer. The 32-bit and ARM64 releases remain
zip archives.
