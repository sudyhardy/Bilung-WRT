# Bilung-WRT

Custom OpenWrt and ImmortalWrt firmware builder powered by ImageBuilder and GitHub Actions.

## Overview

Bilung-WRT is a build repository for generating customized firmware images across multiple target types:

- Official firmware builds
- ULO builds
- Ophub builds

The current default stable OpenWrt target in this project is `25.12.1`.

## Supported Base Targets

- OpenWrt `25.12.1`
- OpenWrt `24.10.x`
- OpenWrt `23.05.x`
- ImmortalWrt `24.10.x`
- ImmortalWrt `23.05.x`

## Build Workflows

This repository includes GitHub Actions workflows for:

- `Generate Firmware Official`
- `Generate ULO Firmware`
- `Generate Ophub Firmware`

Each workflow can be started manually with `workflow_dispatch` and supports selectable release branch, target device, tunnel package set, and clean build mode.

## Main Features

- ImageBuilder-based automated firmware generation
- OpenClash, Nikki, and PassWall tunnel variants
- Support for Official, ULO, and Ophub build flows
- Modem Rakitan support with auto reconnect setup
- Internet Detector
- 3ginfo-Lite and Modeminfo
- Tailscale
- Eqosplus
- Connsmonitor
- Mactodong
- Automatic timezone and startup customization
- Default Bilung-WRT device naming

## Default Identity

- Default hostname: `Bilung-WRT`
- Default Wi-Fi name: `Bilung-WRT`
- Default 5 GHz Wi-Fi name: `Bilung-WRT_5G`
- Default IP: `192.168.31.1`
- Default username: `root`
- Default password: `bilung`

## Project Notes

- The repo has been adjusted toward OpenWrt `25.12.1` compatibility.
- GitHub Actions workflows were updated for newer runtime behavior and current validation issues.
- External package and tunnel handling were also updated to better support newer OpenWrt package formats and upstream asset changes.

## Credits

- Bilung-WRT
- [RTA-WrtBuilder](https://github.com/rizkikotet-dev/RTA-WRT)
- [friWrt-MyWrtBuilder](https://github.com/frizkyiman/friWrt-MyWrtBuilder)
- [MyWrtBuilder](https://github.com/Revincx/MyWrtBuilder)
- [ULO Builder](https://github.com/armarchindo/ULO-Builder/blob/main/ulo)
- [Mod SDCARD](https://github.com/edikurexe)
