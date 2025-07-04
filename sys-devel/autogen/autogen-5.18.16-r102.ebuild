# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 2-2 3-0 )
GUILE_REQ_USE="deprecated"
inherit flag-o-matic autotools guile-single toolchain-funcs

DESCRIPTION="Program and text file generation"
HOMEPAGE="https://www.gnu.org/software/autogen/"
SRC_URI="
	mirror://gnu/${PN}/rel${PV}/${P}.tar.xz
	https://git.savannah.gnu.org/gitweb/?p=gnulib.git;a=blob_plain;f=lib/verify.h;h=3b57ddee0acffd23cc51bc8910a15cf879f90619;hb=537a5511ab0b1326e69b32f87593a50aedb8a589 -> ${P}-gnulib-3b57ddee0acffd23cc51bc8910a15cf879f90619-lib-verify.h
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="libopts static-libs"

REQUIRED_USE="${GUILE_REQUIRED_USE}"

RDEPEND="
	${GUILE_DEPS}
	dev-libs/libxml2:=
"
DEPEND="${RDEPEND}"

# We don't pass the flag explicitly, bug #796776.
# Let's fix it upstream after next autogen release if it happens.
QA_CONFIGURE_OPTIONS+=" --enable-snprintfv-convenience"

QA_CONFIG_IMPL_DECL_SKIP+=(
	# libgen.h is legacy and linux doesn't include -lgen nor nonstandard
	# functions. bug #924961
	pathfind
)

PATCHES=(
	"${FILESDIR}"/${PN}-5.18.16-no-werror.patch
	"${FILESDIR}"/${PN}-5.18.16-rpath.patch
	"${FILESDIR}"/${PN}-5.18.16-respect-TMPDIR.patch
	"${FILESDIR}"/${PN}-5.18.16-make-4.3.patch
	"${FILESDIR}"/${PN}-5.18.16-guile-3.patch
	"${FILESDIR}"/${PN}-5.18.16-configure-c99.patch
	"${FILESDIR}"/${PN}-5.18.16-FORTIFY_SOURCE.patch
	"${FILESDIR}"/${PN}-5.18.16-no-which.patch
)

src_prepare() {
	guile-single_src_prepare

	# missing tarball file
	cp "${DISTDIR}"/${P}-gnulib-3b57ddee0acffd23cc51bc8910a15cf879f90619-lib-verify.h autoopts/verify.h || die

	# May be able to drop this on next release (>5.18.16)
	eautoreconf
}

src_configure() {
	# suppress possibly incorrect -R flag
	export ag_cv_test_ldflags=

	# autogen requires run-time sanity of regex and string functions.
	# Use defaults of linux-glibc until we need somethig more advanced.
	if tc-is-cross-compiler ; then
		export ag_cv_run_strcspn=no
		export libopts_cv_with_libregex=yes
	fi

	# bug 920174
	use elibc_musl && append-cppflags -D_LARGEFILE64_SOURCE

	econf $(use_enable static-libs static)
}

src_install() {
	guile-single_src_install

	find "${ED}" -name '*.la' -delete || die

	if ! use libopts ; then
		rm "${ED}"/usr/share/autogen/libopts-*.tar.gz || die
	fi
}
