# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## High-Level Architecture

This repository contains a build system for creating custom OpenWrt firmware. The build process is orchestrated through GitHub Actions, as defined in the `.github/workflows` directory.

The core components are:
- **`configs/`**: This directory holds the build configurations for different devices (e.g., `x86-64.config`). These are standard OpenWrt `.config` files.
- **`diy-script.sh`**: This shell script is the heart of the customization. It's executed during the build process to perform a wide range of modifications, including:
    - Cloning additional LuCI apps and other packages from various GitHub repositories.
    - Applying patches and tweaks to the source code.
    - Modifying default settings like the IP address and shell.
- **`build.sh`**: This script orchestrates the entire build process, from cloning the OpenWrt source code to compiling the firmware and packaging the binaries.
- **`scripts/`**: Contains miscellaneous helper scripts.

The build process is as follows:
1.  The GitHub Actions workflow is triggered.
2.  The OpenWrt source code is checked out.
3.  The `diy-script.sh` script is run to customize the build.
4.  The appropriate `.config` file from the `configs/` directory is used to configure the build.
5.  The firmware is compiled using `make`.
6.  The resulting firmware images are packaged and uploaded as a release artifact.

## Common Development Tasks

### Building the Firmware

To build the firmware, you need to trigger the corresponding GitHub Actions workflow. For example, to build the `x86-64` firmware, you would run the `X86-64` workflow.

The general steps for a local build are:
1.  Set the `BUILD_PROFILE` environment variable to the name of the config file in the `configs` directory (e.g., `x86-64.config`).
2.  Run the `build.sh` script: `./build.sh`

### Customizing the Build

To customize the build, you will most likely need to modify the `diy-script.sh` file. This is where you can add or remove packages, change default settings, and apply patches.

For example, to add a new package, you would add a `git clone` command to `diy-script.sh` to clone the package repository into the `package/` directory.

### Modifying the Configuration

To change the build configuration (e.g., to enable or disable certain kernel modules or packages), you need to modify the corresponding `.config` file in the `configs/` directory.

After modifying the `.config` file, you'll need to run the build again to apply the changes.
