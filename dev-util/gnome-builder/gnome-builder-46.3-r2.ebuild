# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
LLVM_COMPAT=( {18..20} )
PYTHON_COMPAT=( python3_{11..13} )
DISABLE_AUTOFORMATTING=1
FORCE_PRINT_ELOG=1

inherit gnome.org gnome2-utils llvm-r2 meson optfeature python-single-r1 readme.gentoo-r1 virtualx xdg

DESCRIPTION="An IDE for writing GNOME-based software"
HOMEPAGE="https://apps.gnome.org/Builder/ https://gitlab.gnome.org/GNOME/gnome-builder"

# FIXME: Review licenses at some point
LICENSE="GPL-3+ GPL-2+ LGPL-3+ LGPL-2+ MIT CC-BY-SA-3.0 CC0-1.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="clang doc +d-spy flatpak +git gtk-doc spell +sysprof test +webkit"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	flatpak? ( git )
"

# When bumping, pay attention to all the included plugins/*/meson.build (and other) build files and the requirements within.
# `grep -rI dependency * --include='meson.build'` can give a good initial idea for external deps and their double checking.
# The listed RDEPEND order should roughly match that output as well, with toplevel one first then sorted by file path.
# Most plugins have no extra requirements and default to enabled; we need to handle the ones with extra requirements. Many of
# them have optional runtime dependencies, for which we try to at least notify the user via DOC_CONTENTS (but not all small
# things); `grep -rI -e 'command-pattern.*=' -e 'push_arg'` can give a (spammy) idea, plus python imports in try/except.

# Editorconfig needs old pcre, with vte migrating away, might want it optional or ported to pcre2?
# An introspection USE flag of a dep is required if any introspection based language plugin wants to use it (grep for gi.repository). Last full check at 3.28.4

# TODO: Handle llvm slots via llvm.eclass; see plugins/clang/meson.build
RDEPEND="
	>=dev-libs/glib-2.75:2
	>=gui-libs/gtk-4.10:4[introspection]
	>=gui-libs/libadwaita-1.5_alpha:1
	>=gui-libs/libpanel-1.5.0:1
	>=gui-libs/gtksourceview-5.8:5[introspection]
	>=dev-libs/json-glib-1.2.0
	>=dev-libs/jsonrpc-glib-3.43.0:=
	>=dev-libs/libdex-0.2:=
	>=dev-libs/libpeas-1.99.0:2[python,${PYTHON_SINGLE_USEDEP}]
	dev-libs/libportal:=[gtk,introspection]
	>=dev-libs/template-glib-3.36.1:=[introspection]
	>=gui-libs/vte-0.76.0:2.91-gtk4[introspection]
	>=dev-libs/libxml2-2.9.0:=
	webkit? ( >=net-libs/webkit-gtk-2.38.0:6=[introspection] )
	>=app-text/cmark-0.29.0:0=
	d-spy? ( >=dev-debug/d-spy-1.4.0:1 )
	app-text/editorconfig-core-c
	flatpak? (
		dev-util/ostree
		>=net-libs/libsoup-3:3.0
		>=sys-apps/flatpak-1.10.2
	)
	git? (
		dev-libs/libgit2:=[ssh,threads]
		>=dev-libs/libgit2-glib-1.1.0[ssh]
	)

	>=dev-libs/gobject-introspection-1.74.0:=
	${PYTHON_DEPS}
	clang? ( $(llvm_gen_dep "llvm-core/clang:${LLVM_SLOT}=") )
	spell? (
		app-text/enchant:2
		dev-libs/icu:=
	)
	sysprof? (
		>=dev-util/sysprof-45.0[gtk]
	)
"
DEPEND="${RDEPEND}"
# TODO: runtime ctags path finding..

# desktop-file-utils required for tests, but we have it in deptree for xdg update-desktop-database anyway, so be explicit and unconditional
# appstream-glib needed for validation with appstream-util with FEATURES=test
BDEPEND="
	doc? (
		$(python_gen_cond_dep '
			dev-python/sphinx[${PYTHON_USEDEP}]
			dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]
		')
	)
	gtk-doc? (
		dev-util/gi-docgen
		app-text/docbook-xml-dtd:4.3
	)
	test? (
		dev-libs/appstream-glib
		sys-apps/dbus
	)
	dev-util/desktop-file-utils
	dev-util/glib-utils
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
"

DOC_CONTENTS='gnome-builder can use various other dependencies on runtime to provide
extra capabilities beyond these expressed via USE flags. Some of these
that are currently available with packages include:

* dev-util/ctags with exuberant-ctags selected via "eselect ctags" for
  C, C++, Python, JavaScript, CSS, HTML and Ruby autocompletion, semantic
  highlighting and symbol resolving support.
* dev-python/python-lsp-server for more accurate Python
  autocompletion support.
* dev-debug/valgrind for integration with valgrind.
* dev-build/meson for integration with the Meson build system.
* dev-lang/rust{,-bin} for integration with the Rust Cargo build system.
* dev-build/cmake for integration with the CMake build system.
* net-libs/nodejs[npm] for integration with the NPM package system.
'
# FIXME: Package codespell and mention here
# FIXME: Package gnome-code-assistance and mention here, or maybe USE flag and default enable because it's rather important
# eslint for additional diagnostics in JavaScript files (what package has this? At least something via NPM..)
# jhbuild support
# rust support via rust-analyzer; Go via go-langserver
# autotools stuff for autotools plugin; gtkmm/autoconf-archive for C++ template
# gjs/gettext/mono/PHPize stuff, but most of these are probably installed for other reasons anyways, when needed inside IDE
# stylelint for stylesheet (CSS and co) linting
# gvls for vala language-server integration

pkg_setup() {
	python-single-r1_pkg_setup
	use clang && llvm-r2_pkg_setup
}

src_configure() {
	local emesonargs=(
		-Dchannel=other

		-Ddevelopment=false
		-Dtracing=false
		-Dprofiling=false # not passing -pg to CFLAGS
		-Dtcmalloc=false
		-Dwith_safe_path=''
		-Dgnome_sdk_version=master
		$(meson_use doc help)
		$(meson_use gtk-doc docs)
		-Dnetwork_tests=false
		-Dctags_path=''
		$(meson_feature webkit)

		-Dplugin_autotools=true
		-Dplugin_bash_language_server=true
		-Dplugin_blueprint=true
		-Dplugin_buildstream=true
		-Dplugin_c_pack=true
		-Dplugin_cargo=true
		$(meson_use clang plugin_clang)
		$(meson_use clang plugin_clangd)
		$(meson_use clang plugin_clang_format)
		-Dplugin_cmake=true
		-Dplugin_codesearch=true
		-Dplugin_codeshot=true
		-Dplugin_codespell=true
		-Dplugin_code_index=true
		-Dplugin_copyright=true
		-Dplugin_ctags=true
		-Dplugin_deviced=false # libdeviced not packaged?
		$(meson_use d-spy plugin_dspy)
		-Dplugin_dub=true
		-Dplugin_editorconfig=true
		-Dplugin_elixir_ls=true
		-Dplugin_eslint=true
		-Dplugin_file_search=true
		$(meson_use flatpak plugin_flatpak)
		-Dplugin_flake8=true
		-Dplugin_gdb=true
		-Dplugin_gdiagnose=true
		-Dplugin_gettext=true
		$(meson_use git plugin_git)
		-Dplugin_glsl_language_server=true
		-Dplugin_golang=true
		-Dplugin_gopls=true
		-Dplugin_gradle=true
		-Dplugin_grep=true
		-Dplugin_hadolint=true
		-Dplugin_html_completion=true
		$(meson_use webkit plugin_html_preview)
		-Dplugin_intelephense=true
		-Dplugin_jdtls=true
		-Dplugin_jedi_language_server=false
		-Dplugin_jhbuild=true
		-Dplugin_lua_language_server=true
		-Dplugin_make=true
		-Dplugin_make_templates=true
		$(meson_use webkit plugin_markdown_preview)
		$(meson_use webkit plugin_markdown_indenter)
		-Dplugin_maven=true
		-Dplugin_meson=true
		-Dplugin_meson_templates=true
		-Dplugin_modelines=true
		-Dplugin_mono=true
		-Dplugin_newcomers=true
		-Dplugin_notification=true
		-Dplugin_npm=true
		-Dplugin_phpize=true
		-Dplugin_podman=true
		-Dplugin_pygi=true
		-Dplugin_python_lsp_server=true
		-Dplugin_qemu=true
		-Dplugin_quick_highlight=true
		-Dplugin_retab=true
		-Dplugin_rstcheck=true
		-Dplugin_rubocop=true
		-Dplugin_rust_analyzer=false # rust-analyzer not packaged
		-Dplugin_serve_d=true
		-Dplugin_shellcheck=true
		-Dplugin_shellcmd=true
		-Dplugin_sourcekit_lsp=true
		$(meson_use spell plugin_spellcheck)
		$(meson_use webkit plugin_sphinx_preview)
		-Dplugin_stylelint=true
		-Dplugin_swift=true
		-Dplugin_swift_mesonlsp=true
		-Dplugin_swiftformat=true
		-Dplugin_swiftlint=true
		$(meson_use sysprof plugin_sysprof)
		-Dplugin_todo=true
		-Dplugin_ts_language_server=true
		-Dplugin_update_manager=true
		-Dplugin_valac=true
		-Dplugin_vala_indenter=true
		-Dplugin_vala_language_server=true
		-Dplugin_valgrind=true
		-Dplugin_waf=true
		-Dplugin_words=true
		-Dplugin_xml_pack=true
		-Dplugin_zls=true
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	python_optimize
	if use doc; then
		rm "${ED}"/usr/share/doc/gnome-builder/en/.buildinfo || die
		rm "${ED}"/usr/share/doc/gnome-builder/en/objects.inv || die
		# custom docdir in build system, blocked by https://github.com/mesonbuild/meson/issues/825
		mv "${ED}"/usr/share/doc/gnome-builder/en "${ED}"/usr/share/doc/${PF}/html || die
		# _sources subdir left in on purpose, as HTML links to the rst files as "View page source". Additionally default docompress exclusion of /html/ already ensures they aren't compressed, thus linkable as-is.
		rmdir "${ED}"/usr/share/doc/gnome-builder/ || die
	fi
	readme.gentoo_create_doc
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
	readme.gentoo_print_elog

	optfeature_header "Language support"
	optfeature "Rust's Cargo build system" dev-lang/rust dev-lang/rust-bin
	optfeature "CMake" dev-build/cmake
	optfeature "Java Maven build system" dev-java/maven-bin
	optfeature "Meson Build system" dev-build/meson
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}

src_test() {
	virtx dbus-run-session meson test -C "${BUILD_DIR}"
}
