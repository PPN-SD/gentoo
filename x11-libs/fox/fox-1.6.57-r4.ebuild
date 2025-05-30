# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic

DESCRIPTION="C++ Toolkit for developing Graphical User Interfaces easily and effectively"
HOMEPAGE="http://www.fox-toolkit.org/"
SRC_URI="http://fox-toolkit.org/ftp/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="1.6"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~mips ~ppc ~ppc64 ~sparc ~x86"
IUSE="+bzip2 +jpeg +opengl +png tiff +truetype +zlib debug doc profile"

RDEPEND="
	x11-libs/fox-wrapper
	x11-libs/libXcursor
	x11-libs/libXrandr
	bzip2? ( app-arch/bzip2 )
	jpeg? ( media-libs/libjpeg-turbo:= )
	opengl? ( virtual/glu virtual/opengl )
	png? ( media-libs/libpng:= )
	tiff? ( media-libs/tiff:= )
	truetype? (
		media-libs/freetype:2
		x11-libs/libXft
	)
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}
	x11-base/xorg-proto
	x11-libs/libXt"
BDEPEND="doc? ( app-text/doxygen )"

src_prepare() {
	default

	local d
	for d in utils windows adie calculator pathfinder shutterbug; do
		sed -i -e "s:${d}::" Makefile.am || die
	done

	# Respect system CXXFLAGS
	sed -i -e 's:CXXFLAGS=""::' configure.ac || die "Unable to force cxxflags."

	# don't strip binaries
	sed -i -e '/LDFLAGS="-s ${LDFLAGS}"/d' configure.ac || die "Unable to prevent stripping."

	eautoreconf
}

src_configure() {
	# -Werror=strict-aliasing (bug #864412, bug #940648)
	# Do not trust it for LTO either.
	append-flags -fno-strict-aliasing
	filter-lto

	use debug || append-cppflags -DNDEBUG

	# Not using --enable-release because of the options it sets like no SSP
	econf \
		--disable-static \
		$(use_enable bzip2 bz2lib) \
		$(use_enable debug) \
		$(use_enable jpeg) \
		$(use_with opengl) \
		$(use_enable png) \
		$(use_enable tiff) \
		$(use_with truetype xft) \
		$(use_enable zlib) \
		$(use_with profile profiling)
}

src_compile() {
	emake
	use doc && emake -C doc docs
}

src_install() {
	emake install \
		DESTDIR="${D}" \
		htmldir="${EPREFIX}"/usr/share/doc/${PF}/html \
		artdir="${EPREFIX}"/usr/share/doc/${PF}/html/art \
		screenshotsdir="${EPREFIX}"/usr/share/doc/${PF}/html/screenshots

	local CP="${ED}"/usr/bin/ControlPanel
	if [[ -f ${CP} ]]; then
		mv "${CP}" "${ED}"/usr/bin/fox-ControlPanel-${SLOT} || \
			die "Failed to install ControlPanel"
	fi

	dodoc ADDITIONS AUTHORS LICENSE_ADDENDUM README TRACING

	if use doc; then
		# install class reference docs if USE=doc
		docinto html
		dodoc -r doc/ref
	else
		# remove documentation if USE=-doc
		rm -rf "${ED}"/usr/share/doc/${PF}/html || die
	fi

	# slot fox-config
	if [[ -f ${ED}/usr/bin/fox-config ]] ; then
		mv "${ED}"/usr/bin/fox-config "${ED}"/usr/bin/fox-${SLOT}-config \
		|| die "failed to install fox-config"
	fi

	# no static archives
	find "${D}" -name '*.la' -delete || die
}
