# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic fortran-2 toolchain-funcs

DESCRIPTION="Matrix elements (integrals) evaluation over Cartesian Gaussian functions"
HOMEPAGE="https://github.com/evaleev/libint"
SRC_URI="https://github.com/evaleev/libint/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
IUSE="static-libs doc"

DEPEND="
	dev-libs/boost
	dev-libs/gmp[cxx(+)]
	doc? (
		dev-texlive/texlive-latex
		dev-tex/latex2html
	)
"

PATCHES=(
	"${FILESDIR}"/libint-2.9.0-gcc15-include.patch
)

src_prepare() {
	default
	eautoreconf

	# bug 725454
	sed -i -e '/RANLIB/d' src/bin/libint/Makefile || die
}

src_configure() {
	# bug #862894
	append-flags -fno-strict-aliasing
	filter-lto

	econf \
		--with-cxx="$(tc-getCXX)" \
		--with-cxx-optflags="${CXXFLAGS}" \
		--with-cxxgen-optflags="${CXXFLAGS}" \
		--with-cxxdepend="$(tc-getCXX)" \
		--with-ranlib="$(tc-getRANLIB)" \
		--with-ar="$(tc-getAR)" \
		--with-ld="$(tc-getLD)" \
		--enable-eri=2 --enable-eri3=2 --enable-eri2=2 \
		--with-eri-max-am=7,5,4 --with-eri-opt-am=3 \
		--with-eri3-max-am=7 --with-eri2-max-am=7 \
		--with-g12-max-am=5 --with-g12-opt-am=3 \
		--with-g12dkh-max-am=5 --with-g12dkh-opt-am=3 \
		--enable-contracted-ints \
		--enable-shared \
		$(use_enable static-libs static)
}

src_compile() {
	emake LDFLAGS="${LDFLAGS}"

	use doc && emake html pdf
}

src_install() {
	default
	if ! use static-libs; then
		find "${ED}" -name '*.la' -delete || die "Failed to remove .la files"
	fi

	if use doc; then
		DOCS=( doc/progman/progman.pdf )
		HTML_DOCS=( doc/progman/progman/*.{html,png,css} )
		einstalldocs
	fi
}
