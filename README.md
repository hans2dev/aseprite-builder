# Aseprite Builder 🎨

This project provides an easy, automated way to get your own copy of **Aseprite** by building it directly from the official source code for **Windows, Linux, and macOS**.

Aseprite is "source-available" software. This means while the pre-made versions are paid, the creators allow you to compile the code yourself for personal use. This repository does all the hard work for you—automatically setting up the environment and creating ready-to-use builds for all platforms.

---

## ✨ Features

* **Multi-Platform Support:** Build for Windows, Linux (multiple distros), and macOS (Intel & Apple Silicon)
* **Free & Legal:** Automatically builds your own personal copy from the official code
* **Cloud Builds (GitHub Actions):** Everything can happen on GitHub's servers without installing anything
* **Local Builds:** Scripts for building on your own machine (Windows batch, Linux/macOS bash)
* **Multiple Output Formats:**
  - Windows: Portable ZIP
  - Linux: Portable TAR.GZ + .deb package
  - macOS: ZIP (Apple Silicon & Intel)
* **Automated Dependency Resolution:** Installs required tools and libraries automatically
* **Dynamic Resource Optimization:** Uses available CPU cores for faster builds

---

## 🚀 How to Get Aseprite

### Method 1: Cloud Build (Recommended - No Setup Required)

#### Option A: Multi-Platform Build (All Platforms at Once)
1. **Fork** this repository to your account
2. Go to the **Actions** tab in your new repository
3. Click **"Build Aseprite (All Platforms)"** on the left
4. Click the **Run workflow** button (optionally specify a version)
5. **Wait 60-90 minutes.** All platforms build in parallel. When complete, go to the **Releases** section to download:
   - Windows: `Aseprite-*-Windows.zip`
   - Linux: `Aseprite-*-Linux.tar.gz` (portable) or `Aseprite-*-Linux.deb` (package)
   - macOS (Apple Silicon): `Aseprite-*-macOS-arm64.zip`
   - macOS (Intel): `Aseprite-*-macOS-x64.zip`

#### Option B: Build Single Platform
1. Fork the repository
2. Go to **Actions** → select your platform:
   - **"Build Aseprite"** → Windows only (portable ZIP + Setup.exe installer, optional version input)
   - **"Build Aseprite (Linux)"** → Linux only
3. Click **Run workflow**
4. Download from **Releases** when complete

### Method 2: Local Build

#### Windows
1. Install **Visual Studio 2022** (or Build Tools) with the *Desktop development with C++* workload, plus **CMake** and **Ninja** (`choco install cmake ninja`)
2. Download or clone this repository
3. Open Command Prompt and run: `aseprite_build.bat` (or `aseprite_build.bat v1.3.17` for a specific version)
4. The script loads the MSVC x64 environment automatically
5. Find the build in `workspace/dist/` (installer is created too if Inno Setup 6 is installed)

#### Linux
1. Clone this repository: `git clone <repo-url>`
2. Make the script executable: `chmod +x aseprite_build.sh`
3. Run it: `./aseprite_build.sh`
4. Script auto-installs dependencies for your distro (Debian/Ubuntu, Fedora, Arch, etc.)
5. Find outputs in `workspace/output/`

#### macOS
1. Ensure Xcode Command Line Tools are installed: `xcode-select --install`
2. Clone this repository: `git clone <repo-url>`
3. Make the script executable: `chmod +x aseprite_build.sh`
4. Run it: `./aseprite_build.sh`
5. Script auto-installs Ninja via Homebrew if needed
6. Find outputs in `workspace/output/`

---

## 📋 System Requirements

### Windows
- Visual Studio 2022 (Build Tools or Full)
- CMake 3.15+
- Ninja 1.11+
- Git 2.20+
- Chocolatey (optional - script can install it)

### Linux
- GCC or Clang
- CMake 3.15+
- Ninja 1.11+
- Git 2.20+
- Development libraries (auto-installed by script)

**Supported Distros:**
- Debian/Ubuntu (apt)
- Fedora/RHEL (yum)
- Arch Linux (pacman)
- Others with standard tools

**Auto-Installed Libraries:**
- libx11-dev, libxcursor-dev, libxi-dev, libxrandr-dev
- libgl1-mesa-dev, libfontconfig1-dev, libfreetype6-dev
- libharfbuzz-dev, libpixman-1-dev, zlib1g-dev

### macOS
- Xcode Command Line Tools (or full Xcode)
- CMake 3.15+
- Ninja 1.11+ (auto-installed via Homebrew)
- Git 2.20+
- Homebrew (optional, script uses it for Ninja)

---

## 🔧 Build Scripts

### Windows (aseprite_build.bat)
Non-interactive batch script that:
- Checks for CMake / Ninja and loads the Visual Studio x64 toolchain (via `vswhere` + `VsDevCmd`)
- Downloads latest Aseprite source (or specified version)
- Downloads the exact Skia build required by that version (`laf/misc/skia-tag.txt`)
- Compiles with parallel jobs (auto-detects CPU cores)
- Creates portable ZIP and, if Inno Setup 6 is available, an installer

**Usage:**
```batch
aseprite_build.bat
aseprite_build.bat v1.3.17
```

### Linux/macOS (aseprite_build.sh)
Bash script that:
- Auto-detects OS (Linux/macOS) and architecture
- Installs Ninja if missing
- Auto-installs platform-specific dependencies
- Downloads and compiles Aseprite
- Creates portable archives (TAR.GZ for Linux, ZIP for macOS)
- Generates .deb package on Linux (if dpkg-deb available)
- Creates DMG on macOS (if hdiutil available)
- Detects Apple Silicon vs Intel Macs
- Uses optimal Skia binaries for architecture

**Usage:**
```bash
chmod +x aseprite_build.sh
./aseprite_build.sh
```

**Features:**
- Colored output for clarity
- Detailed progress logging
- Automatic CPU core detection for parallel builds
- Error handling at each step
- Fallback to stable version if API fails

---

## 🔄 GitHub Actions Workflows

### 1. `build.yml` - Windows Build
- **Runs on:** `windows-latest`
- **Output:** Portable ZIP + Inno Setup installer (`Setup.exe`)
- **Trigger:** Manual via workflow dispatch (optional version / release toggle)
- **Time:** ~30-40 minutes

### 2. `build-linux.yml` - Linux Build
- **Runs on:** `ubuntu-latest`
- **Output:** TAR.GZ (portable) + .deb package
- **Trigger:** Manual with version input
- **Time:** ~40-50 minutes
- **Includes:** Desktop entry for application menu

### 3. `build-all-platforms.yml` - All Platforms (Recommended)
Parallel matrix build with:
- **build-windows:** Portable ZIP (~30-40 min)
- **build-linux:** TAR.GZ + .deb (~40-50 min)
- **build-macos-arm64:** Apple Silicon ZIP (~40-50 min)
- **build-macos-x64:** Intel Mac ZIP on macOS-13 (~40-50 min)
- **create-release:** Creates GitHub Release with all artifacts
- **Total Time:** ~50-90 minutes for all platforms
- **Cost:** Uses GitHub-hosted runners (free tier)

---

## 📦 Output Files

### Windows
```
Aseprite-vX.X.X-Windows-x64.zip
  ├── aseprite.exe
  ├── data/
  └── aseprite.ini
```
Extract anywhere and run `aseprite.exe`

### Linux
```
Aseprite-vX.X.X-Linux.tar.gz
  ├── aseprite (binary)
  ├── data/
  └── aseprite.ini

Aseprite-vX.X.X-Linux.deb
```
- TAR.GZ: Extract anywhere and run `./aseprite`
- DEB: Install via `sudo dpkg -i Aseprite-*-Linux.deb` then run `aseprite`

### macOS
```
Aseprite-vX.X.X-macOS-arm64.zip  (for M1/M2/M3)
Aseprite-vX.X.X-macOS-x64.zip    (for Intel)
  ├── Aseprite.app (full macOS app)
  └── aseprite.ini
```
Extract and double-click `Aseprite.app` or add to Applications

---

## 📝 Recent Improvements (Version 2.0)

### New Features
✅ **Full Linux Support**
  - Auto-detects distro and installs dependencies
  - Supports Debian, Fedora, Arch, and others
  - Creates both portable TAR.GZ and .deb packages
  - Adds desktop entry for application menus

✅ **Full macOS Support**
  - Supports Intel (x64) and Apple Silicon (arm64)
  - Auto-detects architecture
  - Creates native .app bundles
  - Optional DMG creation

✅ **Multi-Platform CI/CD**
  - Single workflow for all platforms
  - Parallel builds (all 4 jobs run simultaneously)
  - Automatic GitHub Release creation with all artifacts
  - Supports version input for specific releases

✅ **Better Local Building**
  - Unified bash script for Linux/macOS
  - Color-coded console output
  - Detailed progress reporting
  - Automatic CPU core detection
  - Graceful fallback handling

✅ **Dependency Automation**
  - Windows: Auto-installs via Chocolatey
  - Linux: Detects package manager and installs
  - macOS: Uses Homebrew for Ninja
  - All scripts verify tool availability

### Previous Improvements (Version 1.0)
✅ Removed interactive prompts for CI compatibility
✅ Replaced 7z with PowerShell Expand-Archive (no dependencies)
✅ Proper error handling at each step
✅ Dynamic parallel compilation (CPU-aware)
✅ Stable Skia release URLs (no 404 errors)
✅ OpenSSL DLL conditional handling

---

## 🐛 Troubleshooting

### Windows
- **"Visual Studio not found"**
  - Solution: Install Visual Studio 2022 Build Tools or full version
  
- **"CMake not found" / "Ninja not found"**
  - Solution: `choco install cmake ninja` (or install manually and add to PATH)

- **CMake error: `Cannot find source file ... icudtl.dat`**
  - Cause: Skia version mismatch. The scripts now download the Skia tag listed in `laf/misc/skia-tag.txt` (currently `m124-08a5439a6b`)
  
- **"Build failed"**
  - Try running as Administrator: Right-click → "Run as Administrator"

### Linux
- **"Permission denied" on script**
  - Solution: `chmod +x aseprite_build.sh`
  
- **Missing dependencies**
  - Script auto-installs most; if one fails, install manually via your package manager
  
- **"apt-get not found"**
  - You're on a non-Debian distro; script will try yum/pacman
  
- **Build fails on Wayland**
  - Some X11 libraries may have issues; try Xvfb if headless

### macOS
- **"Ninja not found"**
  - Solution: Install Homebrew first, or run `brew install ninja` manually
  
- **"Skia not found" after download**
  - Check internet connection; try downloading manually
  
- **Apple Silicon build on Intel Mac**
  - Won't work; use the Intel build instead
  - Or cross-compile with: `-DCMAKE_OSX_ARCHITECTURES=arm64`

### All Platforms
- **GitHub Actions timeout (6 hours)**
  - Very large optimized builds may timeout
  - Solution: Reduce optimization flags or use local build
  
- **Out of disk space**
  - Builds use 10-15 GB; ensure free space in `workspace/`
  
- **Network/Download failures**
  - Manually download Aseprite source and Skia to `workspace/`
  - Script will detect and use existing files

---

## ⚖️ Legal & Support

* **Personal Use Only:** You can build this for yourself, but cannot sell or publicly share the executable files
* **Support the Creators:** If you enjoy Aseprite, please [buy it officially](https://www.aseprite.org/) to support development
* **EULA Compliance:** Review [Aseprite's EULA](https://github.com/aseprite/aseprite/blob/main/EULA.txt) - these builds are for personal/private use only

---

## 🔗 References & Credits

- [Aseprite Official Repository](https://github.com/aseprite/aseprite)
- [Aseprite Official Website](https://www.aseprite.org/)
- [Skia Graphics Library](https://github.com/aseprite/skia)
- [Reference Implementation](https://github.com/a1393323447/aseprite-builder)
- [LAF (Libre Application Framework)](https://github.com/libafteratom/laf)

---

## 💡 Tips & Best Practices

1. **GitHub Actions**: Use the "All Platforms" workflow for convenience
2. **Large Builds**: If on slow internet, use local build with cached Skia
3. **Version Control**: Specify exact versions for reproducible builds
4. **Disk Space**: Clean `workspace/` after successful builds to save space
5. **Updates**: Bookmark the Releases page to check for new builds
