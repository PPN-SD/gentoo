# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ECM_HANDBOOK="optional"
ECM_TEST="forceoptional"
KFMIN=6.5.0
QTMIN=6.7.2
inherit ecm kde.org

DESCRIPTION="Note taking application"
HOMEPAGE="https://apps.kde.org/knotes/
https://kontact.kde.org/components/knotes/"
SRC_URI="https://dev.gentoo.org/~asturm/distfiles/${P/_p*/}.tar.xz"
S="${WORKDIR}/${P/_p*/}"

LICENSE="GPL-2+ handbook? ( FDL-1.2+ )"
SLOT="6"
KEYWORDS="amd64 arm64"
IUSE=""

COMMON_DEPEND="
	>=dev-libs/ktextaddons-1.5.4:6
	dev-libs/libxslt
	>=dev-qt/qtbase-${QTMIN}:6[dbus,gui,widgets,xml]
	=kde-apps/akonadi-24.08*:6
	=kde-apps/akonadi-notes-24.08*:6
	=kde-apps/akonadi-search-24.08*:6
	=kde-apps/grantleetheme-24.08*:6
	=kde-apps/kcalutils-24.08*:6
	=kde-apps/kmime-24.08*:6
	=kde-apps/kontactinterface-24.08*:6
	=kde-apps/libkdepim-24.08*:6
	=kde-apps/pimcommon-24.08*:6
	>=kde-frameworks/kcalendarcore-${KFMIN}:6
	>=kde-frameworks/kcmutils-${KFMIN}:6
	>=kde-frameworks/kcompletion-${KFMIN}:6
	>=kde-frameworks/kconfig-${KFMIN}:6
	>=kde-frameworks/kcontacts-${KFMIN}:6
	>=kde-frameworks/kcoreaddons-${KFMIN}:6
	>=kde-frameworks/kcrash-${KFMIN}:6
	>=kde-frameworks/kdnssd-${KFMIN}:6
	>=kde-frameworks/kglobalaccel-${KFMIN}:6
	>=kde-frameworks/ki18n-${KFMIN}:6
	>=kde-frameworks/kiconthemes-${KFMIN}:6
	>=kde-frameworks/kitemmodels-${KFMIN}:6
	>=kde-frameworks/kitemviews-${KFMIN}:6
	>=kde-frameworks/knewstuff-${KFMIN}:6
	>=kde-frameworks/knotifications-${KFMIN}:6
	>=kde-frameworks/kparts-${KFMIN}:6
	>=kde-frameworks/ktextwidgets-${KFMIN}:6
	>=kde-frameworks/kwidgetsaddons-${KFMIN}:6
	>=kde-frameworks/kwindowsystem-${KFMIN}:6[X]
	>=kde-frameworks/kxmlgui-${KFMIN}:6
	x11-libs/libX11
"
RDEPEND="${COMMON_DEPEND}
	=kde-apps/kdepim-runtime-24.08*:6
"
DEPEND="${COMMON_DEPEND}
	x11-base/xorg-proto
"
