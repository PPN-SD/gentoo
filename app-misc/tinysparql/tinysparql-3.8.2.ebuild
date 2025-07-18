# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{11..14} )

inherit bash-completion-r1 flag-o-matic gnome.org gnome2-utils linux-info meson python-any-r1 systemd vala xdg

DESCRIPTION="Low-footprint RDF triple store with SPARQL 1.1 interface"
HOMEPAGE="https://gnome.pages.gitlab.gnome.org/tinysparql"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="3/0" # libtracker-sparql-3.0 soname version
KEYWORDS="~alpha amd64 ~arm arm64 ~loong ~ppc ~ppc64 ~riscv ~sparc x86"
IUSE="gtk-doc +localsearch stemmer systemd test vala zeroconf"
RESTRICT="!test? ( test )"

PV_SERIES=$(ver_cut 1-2)

RDEPEND="
	>=dev-libs/glib-2.52:2
	>=sys-apps/dbus-1.3.2
	>=dev-libs/gobject-introspection-1.54:=
	>=dev-libs/icu-4.8.1.2:=
	>=dev-libs/json-glib-1.4
	>=net-libs/libsoup-2.99.2:3.0
	>=dev-libs/libxml2-2.7:=
	>=dev-db/sqlite-3.29.0:3
	zeroconf? ( net-dns/avahi )
	systemd? ( >=sys-apps/systemd-2.42 )
	stemmer? ( dev-libs/snowball-stemmer:= )
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-util/glib-utils
	app-text/asciidoc
	dev-libs/libxslt
	$(vala_depend)
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	gtk-doc? (
		dev-util/gi-docgen
		media-gfx/graphviz
		app-text/xmlto
	)
	test? (
		$(python_gen_any_dep 'dev-python/pygobject[${PYTHON_USEDEP}]')
		$(python_gen_any_dep 'dev-python/tap-py[${PYTHON_USEDEP}]')
	)
	${PYTHON_DEPS}
"
PDEPEND="localsearch? ( >=app-misc/localsearch-3.6_rc )"

python_check_deps() {
	python_has_version -b \
		"dev-python/pygobject[${PYTHON_USEDEP}]" \
		"dev-python/tap-py[${PYTHON_USEDEP}]"
}

pkg_setup() {
	local CONFIG_CHECK="~INOTIFY_USER"
	linux-info_pkg_setup

	use test && python-any-r1_pkg_setup
}

src_prepare() {
	default
	vala_setup
	xdg_environment_reset
}

src_configure() {
	append-cflags -DTRACKER_DEBUG -DG_DISABLE_CAST_CHECKS

	local emesonargs=(
		$(meson_use gtk-doc docs)
		-Dman=true
		$(meson_feature stemmer)
		-Dunicode_support=icu
		$(meson_feature zeroconf avahi)
		-Dbash_completion_dir="$(get_bashcompdir)"
		-Dsystemd_user_services_dir="$(systemd_get_userunitdir)"
		$(meson_use test tests)
		-Dintrospection=enabled
		$(meson_feature vala vapi)
	)
	meson_src_configure
}

src_test() {
	dbus-run-session meson test -C "${BUILD_DIR}" || die 'tests failed'
}

src_install() {
	meson_src_install

	if use gtk-doc; then
		mkdir -p "${ED}"/usr/share/gtk-doc/html/ || die
		mv "${ED}"/usr/share/doc/Tsparql-3.0 "${ED}"/usr/share/gtk-doc/html/ || die
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
