# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PLOCALES="cs da de en_GB es fi fr hu it ja ko nl pl pt_BR ru zh_CN"
inherit cmake plocale xdg

DESCRIPTION="Featureful and configurable Qt client for the music player daemon (MPD)"
HOMEPAGE="https://github.com/nullobsi/cantata"
SRC_URI="https://codeload.github.com/nullobsi/${PN}/tar.gz/refs/tags/v${PV} -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc64 ~x86"
IUSE="cdda cddb cdio http-server mtp musicbrainz replaygain streaming taglib udisks zeroconf"
REQUIRED_USE="
	?? ( cdda cdio )
	cdda? ( udisks || ( cddb musicbrainz ) )
	cddb? ( || ( cdio cdda ) taglib )
	cdio? ( udisks || ( cddb musicbrainz ) )
	mtp? ( taglib udisks )
	musicbrainz? ( || ( cdio cdda ) taglib )
	replaygain? ( taglib )
"
# cantata has no tests
RESTRICT="test"

COMMON_DEPEND="
	dev-qt/qtbase:6[dbus,gui,network,sqlite,widgets,xml]
	dev-qt/qtsvg:6
	sys-libs/zlib
	virtual/libudev:=
	cdda? ( media-sound/cdparanoia )
	cddb? ( media-libs/libcddb )
	cdio? ( dev-libs/libcdio-paranoia:= )
	mtp? ( media-libs/libmtp:= )
	musicbrainz? ( media-libs/musicbrainz:5= )
	replaygain? (
		media-libs/libebur128:=
		media-sound/mpg123
		media-video/ffmpeg:0=
	)
	streaming? ( dev-qt/qtmultimedia:6 )
	taglib? ( media-libs/taglib[asf(+),mp4(+)] )
	udisks? ( kde-frameworks/solid:6 )
	zeroconf? ( net-dns/avahi )
"
RDEPEND="${COMMON_DEPEND}
	dev-lang/perl[perl_features_ithreads]
"
DEPEND="${COMMON_DEPEND}
	dev-qt/qtbase:6[concurrent]
"
BDEPEND="dev-qt/qttools:6[linguist]"

PATCHES=( "${FILESDIR}"/${PN}-3.3.0-rm_vendor.patch )

src_prepare() {
	remove_locale() {
		rm "translations/${PN}_${1}".ts || die
	}

	cmake_src_prepare

	# Unbundle 3rd party libs
	# keep knotifications : https://github.com/nullobsi/cantata/commit/719adb5
	rm -r 3rdparty/{ebur128,kcategorizedview,qtsingleapplication,qxt,solid-lite} || die

	plocale_find_changes "translations" "${PN}_" ".ts"
	plocale_for_each_disabled_locale remove_locale
}

src_configure() {
	local mycmakeargs=(
		-DENABLE_CATEGORIZED_VIEW=OFF
		-DENABLE_CDPARANOIA=$(usex cdda)
		-DENABLE_CDDB=$(usex cddb)
		-DENABLE_CDIOPARANOIA=$(usex cdio)
		-DENABLE_HTTP_SERVER=$(usex http-server)
		-DENABLE_MTP=$(usex mtp)
		-DENABLE_MUSICBRAINZ=$(usex musicbrainz)
		-DENABLE_FFMPEG=$(usex replaygain)
		-DENABLE_MPG123=$(usex replaygain)
		-DENABLE_HTTP_STREAM_PLAYBACK=$(usex streaming)
		-DENABLE_TAGLIB=$(usex taglib)
		-DENABLE_DEVICES_SUPPORT=$(usex udisks)
		-DENABLE_AVAHI=$(usex zeroconf)
		-DENABLE_REMOTE_DEVICES=OFF
		-DENABLE_UDISKS2=ON
	)

	cmake_src_configure
}

pkg_postinst() {
	xdg_pkg_postinst

	has_version media-sound/mpd || \
		elog "An instance of media-sound/mpd, local or remote, is required to set up Cantata."

	if ! has_version app-misc/media-player-info; then
		elog "Install app-misc/media-player-info to enable identification"
		elog "and querying of portable media players"
	fi
}
