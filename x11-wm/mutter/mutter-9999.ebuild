# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{11..14} )
inherit gnome.org gnome2-utils meson python-any-r1 udev xdg

DESCRIPTION="GNOME compositing window manager based on Clutter"
HOMEPAGE="https://mutter.gnome.org"
LICENSE="GPL-2+"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.gnome.org/GNOME/mutter.git"
	SRC_URI=""
	SLOT="0/15" # This can get easily out of date, but better than 9967
else
	KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~x86"
	SLOT="0/$(($(ver_cut 1) - 32))" # 0/libmutter_api_version - ONLY gnome-shell (or anything using mutter-clutter-<api_version>.pc) should use the subslot
fi

IUSE="debug elogind gnome gtk-doc input_devices_wacom +introspection screencast sysprof systemd test udev wayland X +xwayland video_cards_nvidia"
# native backend requires gles3 for hybrid graphics blitting support, udev and a logind provider
REQUIRED_USE="
	|| ( X wayland )
	gtk-doc? ( introspection )
	wayland? ( ^^ ( elogind systemd ) udev )
	test? ( screencast wayland )"
RESTRICT="!test? ( test )"

# gnome-settings-daemon is build checked, but used at runtime only for org.gnome.settings-daemon.peripherals.keyboard gschema
# USE=libei was first introduced in xwayland-23.2.1; we min dep on that to ensure the [libei(+)] works right, as missing USE flag with
# previous versions meant that it's not there, while the intention seems to be to make it always enabled without USE flag in the future;
# this ensures have_enable_ei_portal is always there in xwayland.pc, which affects how Xwayland is launched, thus if it were toggled off
# in Xwayland after mutter is installed, Xwayland would fail to be started by mutter. mutter already hard-depends on libei, so there's
# really no extra deps here (besides xdg-desktop-portal, but we want that too, anyhow).
# v3.32.2 has many excessive or unused *_req variables declared, thus currently the dep order ignores those and goes via dependency() call order
# dev-libs/wayland is always needed at build time due to https://bugs.gentoo.org/937632
RDEPEND="
	>=media-libs/graphene-1.10.2[introspection?]
	x11-libs/gdk-pixbuf:2
	>=x11-libs/pango-1.46[introspection?]
	>=x11-libs/cairo-1.14[X]
	>=x11-libs/pixman-0.42
	>=dev-libs/fribidi-1.0.0
	>=gnome-base/gsettings-desktop-schemas-47_beta[introspection?]
	>=dev-libs/glib-2.81.1:2
	gnome-base/gnome-settings-daemon
	>=x11-libs/libxkbcommon-0.4.3[X?]
	>=app-accessibility/at-spi2-core-2.46:2[introspection?]
	sys-apps/dbus
	>=x11-misc/colord-1.4.5:=
	>=media-libs/lcms-2.6:2
	>=media-libs/harfbuzz-2.6.0:=
	>=dev-libs/libei-1.0.901
	>=media-libs/libdisplay-info-0.2:=

	gnome? ( gnome-base/gnome-desktop:4= )

	>=media-libs/libcanberra-0.26

	media-libs/libglvnd

	>=dev-libs/wayland-1.23.0
	wayland? (
		>=dev-libs/wayland-protocols-1.36

		>=x11-libs/libdrm-2.4.118
		media-libs/mesa[gbm(+)]
		>=dev-libs/libinput-1.26.0:=

		elogind? ( sys-auth/elogind )
		xwayland? ( >=x11-base/xwayland-23.2.1[libei(+)] )
		video_cards_nvidia? ( gui-libs/egl-wayland )
	)
	udev? (
		>=virtual/libudev-232-r1:=
		>=dev-libs/libgudev-238
	)
	systemd? ( sys-apps/systemd )
	input_devices_wacom? ( >=dev-libs/libwacom-0.13:= )
	screencast? ( >=media-video/pipewire-1.2.0:= )
	introspection? ( >=dev-libs/gobject-introspection-1.54:= )
	test? (
		>=x11-libs/gtk+-3.19.8:3[X,introspection?]
	)
	sysprof? ( >=dev-util/sysprof-capture-3.40.1:4 >=dev-util/sysprof-3.46.0 )
"

X11_CLIENT_DEPS="
	>=gui-libs/gtk-4.0.0:4[X,introspection?]
	media-libs/libglvnd[X]
	>=x11-libs/libX11-1.7.0
	>=x11-libs/libXcomposite-0.4
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	>=x11-libs/libXfixes-6
	>=x11-libs/libXi-1.7.4
	x11-misc/xkeyboard-config
	>=x11-libs/libXrandr-1.5.0
	x11-libs/libxcb:=
	x11-libs/libXinerama
	x11-libs/libXau
	>=x11-libs/startup-notification-0.7
"

RDEPEND+="
	X? (
		${X11_CLIENT_DEPS}
		x11-libs/libICE
		x11-libs/libxkbfile
		x11-libs/libXtst
		x11-libs/libSM
	)
	wayland? ( xwayland? ( ${X11_CLIENT_DEPS} ) )
"
DEPEND="${RDEPEND}
	x11-base/xorg-proto
	sysprof? ( >=dev-util/sysprof-common-3.38.0 )
"
BDEPEND="
	dev-util/wayland-scanner
	dev-util/gdbus-codegen
	dev-util/glib-utils
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	gtk-doc? ( >=dev-util/gi-docgen-2021.1 )
	test? (
		${PYTHON_DEPS}
		$(python_gen_any_dep '
			>=dev-python/python-dbusmock-0.28[${PYTHON_USEDEP}]
		')
		app-text/docbook-xml-dtd:4.5
		X? (
			gnome-extra/zenity
			x11-misc/xvfb-run
		)
	)
	wayland? (
		>=sys-kernel/linux-headers-4.4
		x11-libs/libxcvt
	)
"

PATCHES=(
	"${FILESDIR}"/${PN}-43.0-Disable-anonymous-file-test.patch
)

python_check_deps() {
	if use test; then
		python_has_version ">=dev-python/python-dbusmock-0.28[${PYTHON_USEDEP}]"
	fi
}

src_configure() {
	use debug && EMESON_BUILDTYPE=debug
	local emesonargs=(
		# Mutter X11 renderer only supports gles2 and GLX, thus do NOT pass
		#
		#   -Dopengl_libname=libOpenGL.so.0
		#
		# while we build the x11 renderer, as we currently enable gles2 only
		# with USE=wayland and x11 renderer wouldn't find the needed GLX symbols
		# in a configuration where wayland is disabled, as libOpenGL doesn't
		# include them.
		#
		# See
		# - https://bugs.gentoo.org/835786
		# - https://forums.gentoo.org/viewtopic-p-8695669.html

		-Dopengl=true
		$(meson_use wayland gles2)
		#gles2_libname
		-Degl=true
		$(meson_use X glx)
		$(meson_use wayland)
	)

	if use wayland; then
		emesonargs+=(
			$(meson_use xwayland)
		)
	else
		emesonargs+=(
			-Dxwayland=false
		)
	fi

	emesonargs+=(
		$(meson_use systemd)
		$(meson_use wayland native_backend)
		$(meson_use screencast remote_desktop)
		$(meson_use gnome libgnome_desktop)
		$(meson_use udev)
		-Dudev_dir=$(get_udevdir)
		$(meson_use input_devices_wacom libwacom)
		-Dsound_player=true
		-Dstartup_notification=true
		$(meson_use X sm)
		$(meson_use introspection)
		$(meson_use gtk-doc docs)
		$(meson_use test cogl_tests)
		$(meson_use test clutter_tests)
		$(meson_use test mutter_tests)
		$(meson_feature test tests)
		-Dkvm_tests=false
		-Dtty_tests=false
		$(meson_use sysprof profiler)
		-Dinstalled_tests=false
		$(meson_use X x11)

		#verbose # Let upstream choose default for verbose mode
		#xwayland_path
		# TODO: relies on default settings, but in Gentoo we might have some more packages we want to give Xgrab access (mostly virtual managers and remote desktops)
		#xwayland_grab_default_access_rules
	)

	if use wayland && use video_cards_nvidia; then
		emesonargs+=(
			-Degl_device=true
			-Dwayland_eglstream=true
		)
	else
		emesonargs+=(
			-Degl_device=false
			-Dwayland_eglstream=false
		)
	fi

	meson_src_configure
}

src_test() {
	# Reset variables to avoid issues from /etc/profile.d/flatpak.sh file
	gnome2_environment_reset
	export XDG_DATA_DIRS="${EPREFIX}"/usr/share
	glib-compile-schemas "${BUILD_DIR}"/data
	GSETTINGS_SCHEMA_DIR="${BUILD_DIR}"/data meson_src_test
}

pkg_postinst() {
	use udev && udev_reload
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	use udev && udev_reload
	xdg_pkg_postrm
	gnome2_schemas_update
}
