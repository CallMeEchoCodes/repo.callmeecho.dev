#!/bin/bash
GPG_KEY_FINGERPRINT="0B0F7A231A84F7EE9B8128CABEBCAB631F88D239"
OUTPUT_DIR="publish"

cd "$(dirname "$0")" || exit 1

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/{rootrw,rootless}

dirs=(./pool ./pool/iphoneos-arm ./pool/iphoneos-arm64)

set_arch_vars() {
    case $(basename "$1") in
        pool)
            output_dir=$OUTPUT_DIR
            ;;
        iphoneos-arm)
            output_dir=$OUTPUT_DIR/rootrw
            ;;
        iphoneos-arm64)
            output_dir=$OUTPUT_DIR/rootless
            ;;
    esac
}

for dir in "${dirs[@]}"; do
    set_arch_vars "$dir"
    apt-ftparchive packages "$dir" > "$output_dir/Packages"
    echo >> "$output_dir/Packages"

    zstd -q -c19 "$output_dir/Packages" > "$output_dir/Packages.zst"
    xz -c9 "$output_dir/Packages" > "$output_dir/Packages.xz"
    bzip2 -c9 "$output_dir/Packages" > "$output_dir/Packages.bz2"
    gzip -nc9 "$output_dir/Packages" > "$output_dir/Packages.gz"
    lzma -c9 "$output_dir/Packages" > "$output_dir/Packages.lzma"
    lz4 -c9 "$output_dir/Packages" > "$output_dir/Packages.lz4"
done

for dir in "${dirs[@]}"; do
    set_arch_vars "$dir"
    apt-ftparchive \
        -o APT::FTPArchive::Release::Origin="Echo's Repo" \
        -o APT::FTPArchive::Release::Label="Echo's Repo" \
        -o APT::FTPArchive::Release::Suite="stable" \
        -o APT::FTPArchive::Release::Version="1.0" \
        -o APT::FTPArchive::Release::Codename="echos-repo" \
        -o APT::FTPArchive::Release::Architectures="iphoneos-arm iphoneos-arm64" \
        -o APT::FTPArchive::Release::Components="main" \
        -o APT::FTPArchive::Release::Description="A repo for small but helpful tweaks. Made by CallMeEcho" \
        release "$output_dir" > "$output_dir/Release"
done

for dir in "${dirs[@]}"; do
    set_arch_vars "$dir"
    gpg -abs -u "$GPG_KEY_FINGERPRINT" -o "$output_dir/Release.gpg" "$output_dir/Release"
    gpg -abs -u "$GPG_KEY_FINGERPRINT" --clearsign -o "$output_dir/InRelease" "$output_dir/Release"
done

cp -R pool "$OUTPUT_DIR"
cp static/* "$OUTPUT_DIR"