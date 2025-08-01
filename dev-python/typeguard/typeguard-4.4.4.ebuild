# Copyright 2021-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3_11 python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Run-time type checker for Python"
HOMEPAGE="
	https://pypi.org/project/typeguard/
	https://github.com/agronholm/typeguard/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"

RDEPEND="
	>=dev-python/typing-extensions-4.14.0[${PYTHON_USEDEP}]
"
BDEPEND="
	>=dev-python/setuptools-scm-6.4[${PYTHON_USEDEP}]
"

distutils_enable_tests pytest

python_test() {
	local EPYTEST_IGNORE=(
		# mypy changes results from version to version
		tests/mypy
	)

	local -x PYTHONDONTWRITEBYTECODE=
	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
	# the XFAIL test pass due to some package being installed
	epytest -o xfail_strict=False -p typeguard
}
