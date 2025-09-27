# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="checkpassword-compatible authentication program w/pam support"
HOMEPAGE="https://checkpasswd-pam.sourceforge.net/"
SRC_URI="https://downloads.sourceforge.net/project/${PN}/${PN}/${PV}/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm64 ~hppa ~ppc ~riscv x86"

DEPEND=">=sys-libs/pam-0.75"

DOCS=(
	AUTHORS
	NEWS
	README
)

PATCHES=(
	"${FILESDIR}"/${PN}-0.99-clang16-build-fix.patch
	"${FILESDIR}"/${PN}-0.99-fix_c23.patch
)

src_prepare() {
	default
	# bug 945512, use header from glibc/musl instead
	rm getopt.h || die
}
