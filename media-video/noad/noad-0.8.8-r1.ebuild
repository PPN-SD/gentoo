# Copyright 2021-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools ffmpeg-compat

DESCRIPTION="Mark commercial breaks in VDR recordings"
HOMEPAGE="https://github.com/madmartin/noad"
SRC_URI="https://github.com/madmartin/noad/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+ffmpeg imagemagick libmpeg2"
REQUIRED_USE="|| ( ffmpeg libmpeg2 )"

DEPEND="
	libmpeg2? ( media-libs/libmpeg2 )
	ffmpeg? ( media-video/ffmpeg-compat:4= )
	imagemagick? ( media-gfx/imagemagick:= )"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	# bug #834408, https://github.com/madmartin/noad/issues/2
	ffmpeg_compat_setup 4

	econf \
		$(usev imagemagick --with-magick) \
		$(usev !ffmpeg --without-ffmpeg) \
		$(usev !libmpeg2 --without-libmpeg2) \
		--with-tools
}

src_install() {
	dobin noad showindex checkMarks
	use imagemagick && dobin markpics

	dodoc README* INSTALL
	# example scripts are installed as dokumentation
	dodoc allnewnoad allnoad allnoadnice allnoaduncut checkAllMarks clearlogos noadcall.sh noadifnew stat2html statupd

	newconfd "${FILESDIR}"/confd_vdraddon.noad vdraddon.noad

	insinto /usr/share/vdr/record
	doins "${FILESDIR}"/record-50-noad.sh

	insinto /usr/share/vdr/shutdown
	doins "${FILESDIR}"/pre-shutdown-15-noad.sh

	insinto /etc/vdr/reccmds
	doins "${FILESDIR}"/reccmds.noad.conf

	exeinto /usr/share/vdr/bin
	doexe "${FILESDIR}"/noad-reccmd
}

pkg_postinst() {
	elog
	elog "To integrate noad in VDR you should do this:"
	elog
	elog "start and set Parameter in /etc/conf.d/vdraddon.noad"
	elog
	elog "Note: You can use here all parameters for noad,"
	elog "please look in the documentation of noad."
}
