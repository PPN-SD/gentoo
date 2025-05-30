# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1

DESCRIPTION="Make tinydns and dnscache logs human-readable"
HOMEPAGE="https://michael.orlitzky.com/code/djbdns-logparse.xhtml"
SRC_URI="https://michael.orlitzky.com/code/releases/${P}.tar.gz"
LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="amd64 ~riscv"
IUSE="test"
RESTRICT="!test? ( test )"

# djbdns-logparse pipes the logs through the "tai64nlocal" program
# that comes with sys-process/daemontools.
RDEPEND="sys-process/daemontools"
BDEPEND="test? ( ${RDEPEND} )"

python_install_all() {
	doman "doc/man1/${PN}.1"
	local DOCS=( doc/README )
	distutils-r1_python_install_all
}

python_test() {
	"${EPYTHON}" -m doctest --verbose djbdns/*.py || die
}
