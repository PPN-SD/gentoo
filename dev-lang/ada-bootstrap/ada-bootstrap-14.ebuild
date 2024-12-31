# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

BINPKG=gcc-14.2.1_p20241116-1

# The binaries in SRC_URI are generated by the following (roughly):
# * taking an amd64 stage3
# * adding USE=ada to make.conf
# * running `crossdev ${CHOST} --ex-gcc -S`
# * running `USE=ada ${CHOST}-emerge -v1 gcc`
# * copy /usr/${CHOST}/var/cache/binpkgs/sys-devel/gcc* into
#   ada-bootstrap-${PV}-${CHOST}.gpkg.tar
#
# The full script is at https://github.com/thesamesam/sam-gentoo-scripts/blob/91558fb51c56a661d6f374507888ff67725ca660/build-ada-bootstraps.
#
# Binaries in SRC_URI are regular Gentoo binpkgs in the GPKG format.
#
# Note: of course, the used GCC on both CBUILD and CHOST
# must be the same version, correspond to ${PV} in ada-bootstrap,
# and be at most the newest stable GCC (ideally older).
inherit unpacker

DESCRIPTION="Binary bootstrap compiler for GNAT (Ada compiler)"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:Ada"
SRC_URI="
	amd64? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-x86_64-pc-linux-gnu.gpkg.tar
	)
	arm64? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-aarch64-unknown-linux-gnu.gpkg.tar
	)
	arm? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-armv6j-softfp-linux-gnueabi.gpkg.tar
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-armv6j-unknown-linux-gnueabihf.gpkg.tar
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-armv7a-softfp-linux-gnueabi.gpkg.tar
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-armv7a-unknown-linux-gnueabihf.gpkg.tar
	)
	loong? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-loongarch64-unknown-linux-gnu.gpkg.tar
	)
	ppc? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-powerpc-unknown-linux-gnu.gpkg.tar
	)
	ppc64? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-powerpc64le-unknown-linux-gnu.gpkg.tar
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-powerpc64-unknown-linux-gnu.gpkg.tar
	)
	riscv? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-riscv64-unknown-linux-gnu.gpkg.tar
	)
	sparc? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-sparc64-unknown-linux-gnu.gpkg.tar
	)
	s390? (
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-s390-ibm-linux-gnu.gpkg.tar
		https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-s390x-ibm-linux-gnu.gpkg.tar
	)
"
S=${WORKDIR}

LICENSE="GPL-2 GPL-3"
SLOT="0"
KEYWORDS="-* amd64 ~arm ~arm64 ~ppc ~ppc64 ~riscv ~sparc"

RDEPEND="
	>=dev-libs/gmp-4.3.2:=
	>=dev-libs/mpfr-2.4.2:=
	>=dev-libs/mpc-0.8.1:=
	sys-libs/zlib
	virtual/libiconv
"

src_unpack() {
	# We want to unpack only the appropriate tarball for CHOST (e.g. on arm).
	TARBALL_TO_UNPACK=

	local archive
	for archive in ${A} ; do
		local tarball_chost=${archive/${P}-}
		tarball_chost=${tarball_chost%%.gpkg.tar}

		if [[ ${tarball_chost} == ${CHOST} ]] ; then
			TARBALL_TO_UNPACK=${archive}
			break
		fi
	done

	if [[ -z ${TARBALL_TO_UNPACK} ]] ; then
		die "No tarball found for CHOST=${CHOST}. Please file a bug at bugs.gentoo.org."
	fi

	unpack_gpkg "${TARBALL_TO_UNPACK}"
}

src_install() {
	local chost=${TARBALL_TO_UNPACK/${P}-}
	chost=${chost%%.gpkg.tar}

	dodir /usr/lib/ada-bootstrap
	mv "${WORKDIR}"/${BINPKG}/image/usr/ "${ED}"/usr/lib/ada-bootstrap || die

	# Make `gcc-config`-style symlinks
	insinto /usr/lib/ada-bootstrap/bin
	local tool
	for tool in gcc gnat{,bind,chop,clean,kr,link,ls,make,name,prep} ; do
		dosym -r /usr/lib/ada-bootstrap/usr/${chost}/gcc-bin/${PV}/${tool} /usr/lib/ada-bootstrap/bin/${tool}
		dosym -r /usr/lib/ada-bootstrap/usr/${chost}/gcc-bin/${PV}/${tool} /usr/lib/ada-bootstrap/bin/${chost}-${tool}
		dosym -r /usr/lib/ada-bootstrap/usr/${chost}/gcc-bin/${PV}/${tool} /usr/lib/ada-bootstrap/bin/${chost}-${tool}-${PV}
	done

	rm -rf "${ED}"/usr/lib/ada-bootstrap/usr/bin || die
	# This gives us the same layout as older dev-lang/ada-bootstrap
	dosym -r /usr/lib/ada-bootstrap/bin /usr/lib/ada-bootstrap/usr/bin
	dosym -r /usr/lib/ada-bootstrap/usr/libexec /usr/lib/ada-bootstrap/libexec
}

# TODO: pkg_postinst warning/log?
