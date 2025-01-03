# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

JAVA_PKG_IUSE="doc source"

inherit java-pkg-2 java-pkg-simple prefix

DMF="R-${PV/_rc/RC}-202106111600"

DESCRIPTION="Eclipse Compiler for Java"
HOMEPAGE="https://projects.eclipse.org/projects/eclipse.jdt"
SRC_URI="https://archive.eclipse.org/eclipse/downloads/drops4/${DMF}/ecjsrc-${PV/_rc/RC}.jar"

LICENSE="EPL-1.0"
SLOT="4.20"
KEYWORDS="amd64 ~arm64 ~ppc64"

BDEPEND="app-arch/unzip"
COMMON_DEP="app-eselect/eselect-java"
DEPEND="${COMMON_DEP}
	dev-java/ant:0
	>=virtual/jdk-11:*"
RDEPEND="${COMMON_DEP}
	>=virtual/jre-1.8:*"

HTML_DOCS=( about.html )

JAVA_AUTOMATIC_MODULE_NAME="org.eclipse.jdt.core.compiler.batch"
JAVA_CLASSPATH_EXTRA="ant"
JAVA_JAR_FILENAME="ecj.jar"
JAVA_LAUNCHER_FILENAME="ecj-${SLOT}"
JAVA_MAIN_CLASS="org.eclipse.jdt.internal.compiler.batch.Main"
JAVA_RESOURCE_DIRS="res"

src_prepare() {
	java-pkg-2_src_prepare

	# Exception in thread "main" java.lang.SecurityException: Invalid signature file digest for Manifest main attributes
	rm META-INF/ECLIPSE_* || die
	mkdir "${JAVA_RESOURCE_DIRS}" || die
	find -type f \
		! -name '*.java' \
		| xargs cp --parent -t "${JAVA_RESOURCE_DIRS}" || die
}

src_install() {
	java-pkg-simple_src_install
	insinto /usr/share/java-config-2/compiler
	doins "${FILESDIR}/ecj-${SLOT}"
	eprefixify "${ED}"/usr/share/java-config-2/compiler/ecj-${SLOT}
}

pkg_postinst() {
	einfo "To select between slots of ECJ..."
	einfo " # eselect ecj"

	eselect ecj update ecj-${SLOT}
}

pkg_postrm() {
	eselect ecj update
}
