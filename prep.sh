#!/usr/bin/env bash
set -e

# URL may end with a tag/commits as fragment
source_repos=(
  "git://git.proxmox.com/git/proxmox-backup.git#tag=v3.2.7"
  "git://git.proxmox.com/git/proxmox.git#commit=3545d67b1f3624a920e0a2c2150041e2eb267029"
  "git://git.proxmox.com/git/proxmox-fuse.git"
  "git://git.proxmox.com/git/pathpatterns.git"
  "git://git.proxmox.com/git/pxar.git"
)

rust_version=1.77.1

rpmbuild_sources_dir="$(rpm --eval "%{_sourcedir}")"

pushd "${rpmbuild_sources_dir}"

## Download all proxmox repos
for repo in "${source_repos[@]}"; do
  repo_url=${repo%#*}
  repo_dir=$(basename "$repo_url" .git)
  repo_ref=""
  if [[ "$repo" == *"#"* ]]; then
    repo_ref=${repo##*#}
  fi

  git clone "${repo_url}" "${repo_dir}"

  # Checkout tag/commit, if specified
  if [ -n "${repo_ref}" ]; then
    pushd "${repo_dir}"
    git -c advice.detachedHead=false checkout "${repo_ref#*=}"
    popd
  fi
done

## Apply patches
pushd proxmox-backup
# Delete cargo registry overrides (hardcoded for Debian...)
rm -f .cargo/config.toml

for f in "${rpmbuild_sources_dir}"/00*.patch; do
  echo "Applying patch ${f}"
  patch --forward --strip=1 --input="${f}"
done

popd

pushd proxmox-fuse

for f in "${rpmbuild_sources_dir}"/01*.patch; do
  echo "Applying patch ${f}"
  patch --forward --strip=1 --input="${f}"
done

popd

popd

## Install Rust
curl -sSf https://sh.rustup.rs | sh -s -- --profile default -y --default-toolchain "${rust_version}"
