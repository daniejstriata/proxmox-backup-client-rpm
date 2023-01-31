#!/usr/bin/env bash
set -e

outdir="${1}"

git_dir="$(dirname "$(dirname "$(readlink -e "${0}")")")"
rpm_sourcedir="$(rpm --eval "%{_sourcedir}")"
rpm_srcrpmdir="$(rpm --eval "%{_srcrpmdir}")"

echo "Copying source files"
find "${git_dir}" -maxdepth 1 -type f -execdir cp --verbose "{}" "${rpm_sourcedir}" ";"

echo "Building srpm"
rpmbuild -bs "${git_dir}"/proxmox-backup-client.spec

echo "Moving srpm to \$(outdir)"
mkdir -p "${outdir}"
mv --verbose "${rpm_srcrpmdir}"/*.src.rpm "${outdir}"
