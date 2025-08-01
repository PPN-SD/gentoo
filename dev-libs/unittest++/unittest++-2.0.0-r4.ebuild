# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake dot-a

MY_PN="unittest-cpp"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="A lightweight unit testing framework for C++"
HOMEPAGE="https://unittest-cpp.github.io/"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

PATCHES=(
	# https://github.com/unittest-cpp/unittest-cpp/commit/2423fcac7668aa9c331a2dcf024c3ca06742942d
	"${FILESDIR}"/${P}-fix-tests-with-clang.patch

	"${FILESDIR}"/${P}-cmake-fix-pkgconfig-dir-path-on-FreeBSD.patch
	"${FILESDIR}"/${P}-Add-support-for-LIB_SUFFIX.patch
	"${FILESDIR}"/${P}-cmake4.patch
)

src_prepare() {
	cmake_src_prepare

	# https://github.com/unittest-cpp/unittest-cpp/pull/163
	sed -i '/run unit tests as post build step/,/Running unit tests/d' \
		CMakeLists.txt || die
}

src_configure() {
	lto-guarantee-fat

	local mycmakeargs=(
		# Don't build with -Werror: https://bugs.gentoo.org/747583
		-DUTPP_AMPLIFY_WARNINGS=OFF
		-DUTPP_INCLUDE_TESTS_IN_BUILD=$(usex test)
		# Workaround for bug #863974 and broken .pc file
		-DPACKAGE_VERSION=${PV}
	)
	cmake_src_configure
}

src_test() {
	"${BUILD_DIR}/TestUnitTest++" || die "Tests failed"
}

src_install() {
	cmake_src_install
	strip-lto-bytecode
}
