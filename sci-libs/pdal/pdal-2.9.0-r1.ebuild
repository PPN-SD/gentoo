# Copyright 2021-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="A C++ library for translating and manipulating point cloud data"
HOMEPAGE="https://pdal.io/"
SRC_URI="https://github.com/PDAL/PDAL/releases/download/${PV}/PDAL-${PV}-src.tar.bz2"
S="${WORKDIR}/PDAL-${PV}-src"

LICENSE="BSD"
SLOT="0/19"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="debug postgres test"

BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig
"
RDEPEND="
	net-misc/curl
	app-arch/zstd:=
	dev-libs/libxml2
	dev-libs/openssl:=
	sci-libs/gdal:=
	>=sci-libs/libgeotiff-1.7.0:=
	sys-libs/zlib
	debug? ( sys-libs/libunwind:= )
	postgres? ( dev-db/postgresql:*[xml] )
"

DEPEND="
	test? ( sci-libs/gdal[geos,jpeg,png,sqlite] )
	${RDEPEND}
"

RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}"/${P}-fix-includes.patch
)

src_configure() {
	local mycmakeargs=(
		-DBUILD_PLUGIN_PGPOINTCLOUD="$(usex postgres)"
		-DWITH_COMPLETION=ON
		-DWITH_BACKTRACE="$(usex debug)"
	)

	cmake_src_configure
}

src_test() {
	local myctestargs=(
		--exclude-regex '(pgpointcloudtest|pdal_info_test|pdal_io_bpf_base_test|pdal_io_bpf_zlib_test|pdal_filters_overlay_test|pdal_filters_stats_test|pdal_app_plugin_test|pdal_merge_test|pdal_io_stac_reader_test)'
		--output-on-failure
		-j1
	)

	cmake_src_test
}
