# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit libtool multilib-minimal

DESCRIPTION="Hybrid lossless audio compression tools"
HOMEPAGE="https://www.wavpack.com/"
SRC_URI="https://github.com/dbry/WavPack/releases/download/${PV}/${P}.tar.xz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv sparc x86 ~amd64-linux ~x86-linux"

RDEPEND=">=virtual/libiconv-0-r1"
DEPEND="${RDEPEND}"

src_prepare() {
	default
	elibtoolize
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf $(multilib_native_enable apps)
}

multilib_src_install_all() {
	einstalldocs
	find "${ED}" -name '*.la' -delete || die
}
