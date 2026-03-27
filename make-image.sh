#!/bin/bash

. ./scripts/INCLUDE.sh

# Exit on error
set -e

# Profile info
make info

# Main configuration name
PROFILE=""
PACKAGES=""
EXCLUDED=""
LEGACY_OVERLAY_DIR=".legacy-package-overlay"

# Base
PACKAGES+=" liblua libc libubus-lua libiwinfo libiwinfo-data libiwinfo-lua libjson-script \
liblucihttp liblucihttp-lua luci-lib-base luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio \
busybox curl wget-ssl tar unzip uuidgen zoneinfo-core zoneinfo-asia screen jq \
coreutils-base64 coreutils-stty coreutils-stat coreutils-sleep block-mount cgi-io dnsmasq-full \
rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns \
uhttpd uhttpd-mod-ubus luci-base luci-compat luci luci-ssl \
luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp"

# Modem and UsbLAN Driver
PACKAGES+=" kmod-usb-ohci kmod-usb-uhci kmod-usb2 kmod-usb-ehci kmod-usb3 \
kmod-mii kmod-usb-wdm kmod-usb-acm \
kmod-usb-serial kmod-usb-serial-wwan kmod-usb-serial-option kmod-usb-serial-qualcomm \
kmod-usb-storage kmod-usb-storage-uas kmod-nls-utf8 kmod-macvlan usbutils \
kmod-usb-net kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-cdc-mbim kmod-usb-net-rndis kmod-usb-net-qmi-wwan \
kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179 \
kmod-usb-net-huawei-cdc-ncm kmod-usb-net-sierrawireless kmod-usb-serial-sierrawireless \
usb-modeswitch libqmi qmi-utils umbim libmbim mbim-utils modemmanager \
luci-proto-qmi luci-proto-mbim luci-proto-modemmanager xmm-modem"

# Modem Tools
PACKAGES+=" modeminfo luci-app-modeminfo atinout modemband luci-app-modemband luci-app-mmconfig sms-tool luci-app-sms-tool-js luci-app-3ginfo-lite picocom minicom"

# ModemInfo
PACKAGES+=" modeminfo-serial-tw modeminfo-serial-dell modeminfo-serial-xmm modeminfo-serial-fibocom modeminfo-serial-sierra"

# Tunnel VPN
OPENCLASH+="coreutils-nohup bash ca-certificates ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag kmod-nft-tproxy luci-app-openclash"
NIKKI+="nikki luci-app-nikki"
PASSWALL+="chinadns-ng resolveip dns2socks dns2tcp ipt2socks microsocks tcping xray-core xray-plugin luci-app-passwall"

# Handle_Tunnel
handle_tunnel_option() {
    case "$1" in
        "openclash")
            PACKAGES+=" $OPENCLASH"
            ;;
        "nikki")
            PACKAGES+=" $NIKKI"
            ;;
        "openclash-passwall")
            PACKAGES+=" $OPENCLASH $PASSWALL"
            ;;
        "nikki-openclash")
            PACKAGES+=" $NIKKI $OPENCLASH"
            ;;
        "no-tunnel")
            PACKAGES+=""
            ;;
    esac
}

# Nas And Storage
PACKAGES+=" luci-app-diskman luci-app-tinyfm"

# Bandwidth And Network Monitoring
PACKAGES+=" internet-detector luci-app-internet-detector internet-detector-mod-modem-restart vnstat2 vnstati2 luci-app-netmonitor"

# Remote Services
PACKAGES+=" tailscale luci-app-tailscale"

# Bandwidth And Speedtest
PACKAGES+=" speedtestcli luci-app-eqosplus"

# Keep the stock LuCI look on latest OpenWrt.
PACKAGES+=" luci-theme-bootstrap"

# Php8
PACKAGES+=" php8 php8-fastcgi php8-fpm php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv php8-mod-mbstring"

# Custom Packages And More
PACKAGES+=" adb htop lolcat python3-pip zram-swap luci-app-ramfree luci-app-ttyd luci-app-lite-watchdog luci-app-ipinfo luci-app-droidnet luci-app-mactodong"

# Handle_profile
handle_profile_packages() {
    if [ "$1" == "rpi-4" ]; then
        PACKAGES+=" kmod-i2c-bcm2835 i2c-tools kmod-i2c-core kmod-i2c-gpio"
    elif [ "$ARCH_2" == "x86_64" ]; then
        PACKAGES+=" kmod-iwlwifi iw-full pciutils"
    fi

    case "${TYPE}" in
        "OPHUB")
            PACKAGES+=" btrfs-progs kmod-fs-btrfs luci-app-amlogic"
            EXCLUDED+=" -procd-ujail"
            ;;
        "ULO")
            PACKAGES+=" luci-app-amlogic"
            EXCLUDED+=" -procd-ujail"
            ;;
    esac
}

# Handle_release
handle_release_packages() {
    if [ "${BASE}" == "openwrt" ]; then
        PACKAGES+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211"
        EXCLUDED+=" -dnsmasq"
    elif [ "${BASE}" == "immortalwrt" ]; then
        PACKAGES+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211"
        EXCLUDED+=" -dnsmasq -cpusage -automount -libustream-openssl -default-settings-chn -luci-i18n-base-zh-cn"
        if [ "$ARCH_2" == "x86_64" ]; then
            EXCLUDED+=" -kmod-usb-net-rtl8152-vendor"
        fi
    fi
}

filter_unavailable_packages_for_apk() {
    local filtered_packages=""
    local pkg
    local branch_major="${BRANCH%%.*}"

    if [ "${BASE}" != "openwrt" ] || ! [[ "$branch_major" =~ ^[0-9]+$ ]] || [ "$branch_major" -lt 25 ]; then
        return 0
    fi

    log "INFO" "Filtering package list for OpenWrt ${BRANCH} apk compatibility"

    for pkg in $PACKAGES; do
        if [[ "$pkg" == -* ]]; then
            filtered_packages+=" $pkg"
            continue
        fi

        if [ -f "packages/${pkg}.apk" ] || find packages -maxdepth 1 -type f -name "${pkg}-*.apk" -print -quit | grep -q .; then
            filtered_packages+=" $pkg"
            continue
        fi

        if grep -qE "^Package: ${pkg}$" Packages.manifest 2>/dev/null; then
            filtered_packages+=" $pkg"
            continue
        fi

        log "WARNING" "Skipping unavailable apk package: ${pkg}"
    done

    PACKAGES="$filtered_packages"
}

extract_legacy_ipk_to_overlay() {
    local pkg_name="$1"
    local pkg_file="$2"
    local extract_root="$3"
    local tmp_dir
    local data_archive

    tmp_dir="$(mktemp -d)"
    gzip -dc "$pkg_file" > "${tmp_dir}/package.tar" || error_msg "Failed to decompress ${pkg_file}"
    tar -xf "${tmp_dir}/package.tar" -C "$tmp_dir" || error_msg "Failed to unpack ${pkg_file}"

    data_archive="$(find "$tmp_dir" -maxdepth 1 -type f \( -name 'data.tar.gz' -o -name 'data.tar.xz' -o -name 'data.tar.zst' \) | head -n 1)"
    [ -n "$data_archive" ] || error_msg "Missing data archive in ${pkg_file}"

    mkdir -p "$extract_root"
    case "$data_archive" in
        *.tar.gz) tar -xzf "$data_archive" -C "$extract_root" ;;
        *.tar.xz) tar -xJf "$data_archive" -C "$extract_root" ;;
        *.tar.zst) tar --zstd -xf "$data_archive" -C "$extract_root" ;;
        *) error_msg "Unsupported data archive format in ${pkg_file}" ;;
    esac

    rm -rf "$tmp_dir"
    log "WARNING" "Using legacy ipk fallback for package: ${pkg_name}"
}

fallback_to_legacy_ipk_overlay() {
    local filtered_packages=""
    local pkg
    local branch_major="${BRANCH%%.*}"
    local overlay_files="${FILES}/${LEGACY_OVERLAY_DIR}"
    local local_pkg=""
    local legacy_pkg=""

    if [ "${BASE}" != "openwrt" ] || ! [[ "$branch_major" =~ ^[0-9]+$ ]] || [ "$branch_major" -lt 25 ]; then
        return 0
    fi

    rm -rf "$overlay_files"
    mkdir -p "$overlay_files"

    for pkg in $PACKAGES; do
        if [[ "$pkg" == -* ]]; then
            filtered_packages+=" $pkg"
            continue
        fi

        if grep -qE "^Package: ${pkg}$" Packages.manifest 2>/dev/null; then
            filtered_packages+=" $pkg"
            continue
        fi

        if find packages -maxdepth 1 -type f -name "${pkg}-*.apk" -print -quit | grep -q . || [ -f "packages/${pkg}.apk" ]; then
            filtered_packages+=" $pkg"
            continue
        fi

        local_pkg="$(find packages -maxdepth 1 -type f \( -name "${pkg}_*.ipk" -o -name "${pkg}-*.ipk" \) | head -n 1)"
        legacy_pkg="$(find packages-legacy -maxdepth 1 -type f \( -name "${pkg}_*.ipk" -o -name "${pkg}-*.ipk" \) | head -n 1)"

        if [ -n "$local_pkg" ]; then
            extract_legacy_ipk_to_overlay "$pkg" "$local_pkg" "$overlay_files"
            continue
        fi

        if [ -n "$legacy_pkg" ]; then
            extract_legacy_ipk_to_overlay "$pkg" "$legacy_pkg" "$overlay_files"
            continue
        fi

        log "WARNING" "Skipping unavailable package: ${pkg}"
    done

    PACKAGES="$filtered_packages"
}

# Main Build Function
build_firmware() {
    local profile=$1
    local tunnel_option=$2

    log "INFO" "Starting build for profile: $profile"
    FILES="files"
    
    handle_profile_packages "$profile"
    handle_tunnel_option "$tunnel_option"
    handle_release_packages
    fallback_to_legacy_ipk_overlay
    
    make image PROFILE="$profile" PACKAGES="$PACKAGES $EXCLUDED" FILES="$FILES" 2>&1
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "INFO" "Build Completed Successfully!"
    else
        log "ERROR" "Build failed. Check log for details."
    fi
}

# Main script execution
if [ -z "$1" ]; then
    log "ERROR" "Profile not specified"
fi

build_firmware "$1" "$2"
