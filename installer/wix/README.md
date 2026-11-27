# Windows installers

`go.wxs` packages an unpacked `go-legacy-win7` release tree into a per-machine
Windows Installer package. `bundle.wxs` wraps that MSI in a single-file EXE
bootstrapper, which is the installer most users should download.

Both installers:

- install to `C:\Program Files\Go` by default (the directory can be changed in
  the wizard);
- append `<install dir>\bin` to the system `PATH`, and remove it on uninstall;
- register the installation in Programs and Features;
- upgrade older versions, including rebuilds with the same
  `major.minor.patch` version.

They deliberately do not set `GOROOT`. The `go` command finds its own root, and
a system-wide `GOROOT` breaks as soon as a second toolchain is installed.

## Build

WiX builds Windows installers only on Windows. Install WiX 6 once:

```powershell
dotnet tool install --global wix --version 6.0.2
wix extension add -g WixToolset.UI.wixext/6.0.2
wix extension add -g WixToolset.BootstrapperApplications.wixext/6.0.2
```

Then unzip a Windows release and point the script at the unpacked tree:

```powershell
Expand-Archive go-legacy-win7-1.27.3.windows_amd64.zip release
.\installer\wix\build.ps1 -SourceDir release\go-legacy-win7 -Version 1.27.3
```

The script produces both
`go-legacy-win7-1.27.3.windows_amd64.msi` and
`go-legacy-win7-1.27.3.windows_amd64.exe`. Pass `-NoExe` to build only the
MSI.

For unattended deployments, the EXE accepts the standard Burn switches and an
overridable `InstallFolder` variable:

```powershell
.\go-legacy-win7-1.27.3.windows_amd64.exe /quiet InstallFolder="D:\Go"
```

The MSI exposes `INSTALLFOLDER` as a public property:

```powershell
msiexec /i go-legacy-win7-1.27.3.windows_amd64.msi /qn INSTALLFOLDER="D:\Go"
```

The release workflow does this automatically for `windows_amd64`: it uploads
the cleaned release zip as an artifact, builds the MSI and EXE on
`windows-latest`, and attaches both to the same draft release.

Only the 64-bit build gets installers. The 32-bit and ARM64 releases remain zip
archives.
