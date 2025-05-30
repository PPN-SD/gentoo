# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit gnustep-2

DESCRIPTION="A workspace manager for GNUstep"
HOMEPAGE="https://www.gnustep.org/experience/GWorkspace.html"
SRC_URI="https://ftp.gnustep.org/pub/gnustep/usr-apps/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"

IUSE="+gwmetadata"

DEPEND=">=gnustep-base/gnustep-gui-0.25.0
	gwmetadata? (
		>=gnustep-apps/systempreferences-1.0.1_p24791
		>=dev-db/sqlite-3.2.8
	)"
RDEPEND="${DEPEND}"

src_configure() {
	local myconf=""
	use kernel_linux && myconf="${myconf} --with-inotify"
	use gwmetadata && myconf="${myconf} --enable-gwmetadata"

	egnustep_env
	econf ${myconf}
}

src_install() {
	egnustep_env
	egnustep_install

	if use doc;
	then
		dodir /usr/share/doc/${PF}
		cp "${S}"/Documentation/*.pdf "${D}"/usr/share/doc/${PF}
	fi
}
