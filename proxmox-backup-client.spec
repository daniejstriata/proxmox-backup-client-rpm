Name:           proxmox-backup-client
Version:        3.2.7
Release:        1%{?dist}
Summary:        Client for Proxmox Backup Server

License:        AGPL-3
URL:            https://pbs.proxmox.com/docs/backup-client.html
# actual sources are blatantly downloaded during %prep
Source0:        prep.sh
Source1:        elf-strip-unused-dependencies.sh
Patch0:         0001-re-route-dependencies-not-available-on-crates.io-to-.patch
Patch1:         0002-docs-drop-all-but-client-man-pages.patch
Patch2:         0101-remove-noflush-attr.patch

BuildRequires:  clang-devel
BuildRequires:  fuse3-devel
BuildRequires:  git
BuildRequires:  libacl-devel
BuildRequires:  libuuid-devel
BuildRequires:  openssl-devel
BuildRequires:  patchelf
BuildRequires:  python3-docutils
BuildRequires:  python3-sphinx

Requires:       fuse3-libs
Requires:       glibc
Requires:       libacl
Requires:       libgcc
Requires:       libxcrypt
Requires:       openssl-libs

%description
Client for Proxmox Backup Server

%prep
%{_sourcedir}/prep.sh

%build
source "$HOME/.cargo/env"

cd %{_sourcedir}/proxmox-backup
cargo build --release \
    --package %{name} \
    --bin %{name} \
    --bin dump-catalog-shell-cli \
    --package pxar-bin \
    --bin pxar

%{_sourcedir}/elf-strip-unused-dependencies.sh target/release/%{name}
%{_sourcedir}/elf-strip-unused-dependencies.sh target/release/pxar

cp debian/copyright %{_builddir}/copyright

cd docs
DEB_VERSION_UPSTREAM="%{version}" DEB_VERSION="${DEB_VERSION_UPSTREAM%.*}" BUILD_MODE=release make %{name}.1 pxar.1

%check
source "$HOME/.cargo/env"

cd %{_sourcedir}/proxmox-backup
mkdir -p target/testout/
cargo test --release \
    --package %{name} \
    --bin %{name} \
    --package pxar-bin \
    --bin pxar

%install
cd %{_sourcedir}/proxmox-backup

rm -rf %{buildroot}

install -Dm755 "target/release/%{name}" "%{buildroot}%{_bindir}/%{name}"
install -Dm755 "target/release/pxar" "%{buildroot}%{_bindir}/pxar"

install -Dm644 "docs/output/man/%{name}.1" "%{buildroot}%{_mandir}/man1/%{name}.1"
install -Dm644 "docs/output/man/pxar.1" "%{buildroot}%{_mandir}/man1/pxar.1"

install -Dm644 "debian/%{name}.bc" "%{buildroot}%{_datadir}/bash-completion/completions/%{name}"
install -Dm644 "debian/pxar.bc" "%{buildroot}%{_datadir}/bash-completion/completions/pxar"

install -Dm644 "zsh-completions/_%{name}" "%{buildroot}%{_datadir}/zsh/site-functions/_%{name}"
install -Dm644 "zsh-completions/_pxar" "%{buildroot}%{_datadir}/zsh/site-functions/_pxar"

%files
%license copyright
%{_bindir}/%{name}
%{_bindir}/pxar
%{_mandir}/man1/%{name}.1*
%{_mandir}/man1/pxar.1*
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/bash-completion/completions/pxar
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/zsh/site-functions/_pxar

%changelog
* Fri Aug 23 2024 DerEnderKeks <derenderkeks@gmail.com>
- Updated patches and dependencies for 3.2.7
* Fri Apr 05 2024 DerEnderKeks <derenderkeks@gmail.com>
- Updated patches and dependencies for 3.1.2
* Mon Jan 30 2023 DerEnderKeks <derenderkeks@gmail.com>
- Initial package
