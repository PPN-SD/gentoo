# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Python library to read from and write to FITS files"
HOMEPAGE="
	https://github.com/esheldon/fitsio/
	https://pypi.org/project/fitsio/
"
SRC_URI="
	https://github.com/esheldon/fitsio/archive/${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"

DEPEND="
	>=dev-python/numpy-1.11:=[${PYTHON_USEDEP}]
	>=sci-libs/cfitsio-4.4.0:0=
"
RDEPEND="
	${DEPEND}
"

distutils_enable_tests pytest

PATCHES=(
	# https://github.com/esheldon/fitsio/pull/430
	"${FILESDIR}/${P}-numpy-2.3.patch"
)

export FITSIO_USE_SYSTEM_FITSIO=1

python_test() {
	cd "${BUILD_DIR}/install$(python_get_sitedir)" || die
	epytest
}
