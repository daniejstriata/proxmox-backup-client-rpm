#!/usr/bin/env bash
set -e

# URL may end with a tag/commits as fragment
source_repos=(
  "git://git.proxmox.com/git/proxmox-backup.git#tag=v2.3.1"
  "git://git.proxmox.com/git/proxmox.git#commit=d513ef78361cbdb505b4e0e6dbf74b1a10ee987e"
  "git://git.proxmox.com/git/proxmox-fuse.git"
  "git://git.proxmox.com/git/pxar.git"
)

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
rm -f .cargo/config

for f in "${rpmbuild_sources_dir}"/*.patch; do
  echo "Applying patch ${f}"
  patch --forward --strip=1 --input="${f}"
done

popd
popd
