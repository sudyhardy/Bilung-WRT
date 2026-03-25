#!/bin/bash

. ./scripts/INCLUDE.sh

branch_major="${BRANCH%%.*}"
package_ext="ipk"

if [[ "$branch_major" =~ ^[0-9]+$ ]] && [ "$branch_major" -ge 24 ]; then
    package_ext="apk"
fi

nikki_branch="${VEROP}"
if [[ "${BASE}" == "openwrt" && "$branch_major" =~ ^[0-9]+$ && "$branch_major" -ge 25 ]]; then
    nikki_branch="24.10"
    log "WARNING" "Nikki packages for OpenWrt ${VEROP} are unavailable upstream; using ${nikki_branch} compatibility build"
fi

get_openclash_core_url() {
    local meta_file
    if [[ "${ARCH_3}" == "x86_64" ]]; then
        meta_file="mihomo-linux-${ARCH_1}-compatible"
    else
        meta_file="mihomo-linux-${ARCH_1}"
    fi
    curl -s "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" | grep "browser_download_url" | grep -oE "https.*${meta_file}-v[0-9]+\.[0-9]+\.[0-9]+\.gz" | head -n 1 || true
}

get_openclash_package_url() {
    local package_name="luci-app-openclash"
    curl -s "https://api.github.com/repos/vernesong/OpenClash/releases/latest" | grep "browser_download_url" | grep -oE "https.*${package_name}[-_].*\.${package_ext}" | head -n 1 || true
}

get_passwall_package_url() {
    local package_name="luci-24.10_luci-app-passwall"
    curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall/releases" | grep "browser_download_url" | grep -oE "https.*${package_name}.*\.ipk" | head -n 1 || true
}

get_passwall_core_url() {
    local archive_name="passwall_packages_ipk_${ARCH_3}"
    curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall/releases" | grep "browser_download_url" | grep -oE "https.*${archive_name}.*\.zip" | head -n 1 || true
}

get_nikki_package_url() {
    local package_name="nikki_${ARCH_3}-openwrt-${nikki_branch}"
    curl -s "https://api.github.com/repos/rizkikotet-dev/OpenWrt-nikki-Mod/releases/latest" | grep "browser_download_url" | grep -oE "https.*${package_name}\.tar\.gz" | head -n 1 || true
}

# Function to download and setup OpenClash
setup_openclash() {
    local openclash_file_ipk_down
    local openclash_core
    local openclash_output="packages/openclash.${package_ext}"

    log "INFO" "Downloading OpenClash packages"
    openclash_file_ipk_down=$(get_openclash_package_url)
    openclash_core=$(get_openclash_core_url)
    [ -n "${openclash_file_ipk_down}" ] || error_msg "OpenClash package not found for ${BASE} ${BRANCH}"
    [ -n "${openclash_core}" ] || error_msg "OpenClash core not found for ${ARCH_1}"
    ariadl "${openclash_file_ipk_down}" "${openclash_output}"
    ariadl "${openclash_core}" "files/etc/openclash/core/clash_meta.gz"
    gzip -d "files/etc/openclash/core/clash_meta.gz" || error_msg "Error: Failed to extract OpenClash package."
}

# Function to download and setup PassWall
setup_passwall() {
    local passwall_file_ipk_down
    local passwall_core_file_zip_down

    log "INFO" "Downloading PassWall packages"
    passwall_file_ipk_down=$(get_passwall_package_url)
    passwall_core_file_zip_down=$(get_passwall_core_url)
    [ -n "${passwall_file_ipk_down}" ] || error_msg "PassWall package not found"
    [ -n "${passwall_core_file_zip_down}" ] || error_msg "PassWall core archive not found for ${ARCH_3}"
    ariadl "${passwall_file_ipk_down}" "packages/passwall.ipk"
    ariadl "${passwall_core_file_zip_down}" "packages/passwall.zip"
    unzip -qq "packages/passwall.zip" -d packages && rm "packages/passwall.zip" || error_msg "Error: Failed to extract PassWall package."
}

# Function to download and setup Nikki
setup_nikki() {
    local nikki_file_ipk_down

    log "INFO" "Downloading Nikki packages"
    nikki_file_ipk_down=$(get_nikki_package_url)
    [ -n "${nikki_file_ipk_down}" ] || error_msg "Nikki package not found for ${BASE} ${VEROP} (${ARCH_3})"
    ariadl "${nikki_file_ipk_down}" "packages/nikki.tar.gz"
    tar -xzvf "packages/nikki.tar.gz" -C packages > /dev/null 2>&1 && rm "packages/nikki.tar.gz" || error_msg "Error: Failed to extract Nikki package."
}

case "$1" in
    openclash)
        setup_openclash
        ;;
    nikki)
        setup_nikki
        ;;
    openclash-passwall)
        setup_openclash
        setup_passwall
        ;;
    nikki-openclash)
        setup_nikki
        setup_openclash
        ;;
    no-tunnel)
        ;;
    *)
        log "INFO" "Invalid option. Usage: $0 {openclash|nikki|openclash-passwall|nikki-openclash|no-tunnel}"
        exit 1
        ;;
esac

# Check final status
if [ "$?" -ne 0 ]; then
    error_msg "Download or extraction failed."
    exit 1
else
    log "INFO" "Download and installation completed successfully."
fi
