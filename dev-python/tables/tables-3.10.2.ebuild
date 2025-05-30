# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 pypy3_11 python3_{10..13} )
PYTHON_REQ_USE="threads(+)"

inherit distutils-r1 prefix pypi

DESCRIPTION="Hierarchical datasets for Python"
HOMEPAGE="
	https://www.pytables.org/
	https://github.com/PyTables/PyTables/
	https://pypi.org/project/tables/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~loong ppc64 ~riscv ~sparc x86 ~amd64-linux ~x86-linux"
IUSE="+cpudetection examples test"
RESTRICT="!test? ( test )"

DEPEND="
	app-arch/bzip2:0=
	app-arch/lz4:0=
	>=app-arch/zstd-1.0.0:=
	>=dev-libs/c-blosc-1.11.1:0=
	>=dev-libs/c-blosc2-2.11.0:=
	dev-libs/lzo:2=
	>=dev-python/numpy-1.19.0:=[${PYTHON_USEDEP}]
	>=sci-libs/hdf5-1.8.4:=
"
RDEPEND="
	${DEPEND}
	>=dev-python/numexpr-2.6.2[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	cpudetection? ( dev-python/py-cpuinfo[${PYTHON_USEDEP}] )
"
BDEPEND="
	>=dev-python/cython-3.0.10[${PYTHON_USEDEP}]
	virtual/pkgconfig
	cpudetection? ( dev-python/py-cpuinfo[${PYTHON_USEDEP}] )
	test? (
		${RDEPEND}
	)
"

python_prepare_all() {
	rm -r c-blosc/{blosc,internal-complibs} || die

	distutils-r1_python_prepare_all

	sed -i -e '/blosc2/d' pyproject.toml || die
	hprefixify -w '/prefixes =/' setup.py

	export PYTABLES_NO_EMBEDDED_LIBS=1
	export USE_PKGCONFIG=TRUE
}

python_test() {
	cd "${BUILD_DIR}/install$(python_get_sitedir)" || die
	"${EPYTHON}" tables/tests/test_all.py -v || die
}

python_install_all() {
	distutils-r1_python_install_all

	if use examples; then
		dodoc -r contrib examples
		docompress -x /usr/share/doc/${PF}/{contrib,examples}
	fi
}
