# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYTHON_COMPAT=( python3_{10..12} )
PYPI_PN=${PN/-/_}
inherit readme.gentoo-r1 systemd distutils-r1 pypi

DESCRIPTION="BuildBot Worker (slave) Daemon"
HOMEPAGE="https://buildbot.net/
	https://github.com/buildbot/buildbot
	https://pypi.org/project/buildbot-worker/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~riscv ~sparc ~amd64-linux ~x86-linux"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	acct-user/buildbot
	!<dev-util/buildbot-3.0.0
	>=dev-python/autobahn-0.16.0[${PYTHON_USEDEP}]
	>=dev-python/msgpack-0.6.0[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	>=dev-python/twisted-18.7.0[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		${RDEPEND}
		dev-python/parameterized[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
	)
"

DOC_CONTENTS="The \"buildbot\" user and the \"buildbot_worker\" init script has been added
to support starting buildbot_worker through Gentoo's init system. To use this,
execute \"emerge --config =${CATEGORY}/${PF}\" to create a new instance.
Set up your build worker following the documentation, make sure the
resulting directories are owned by the \"buildbot\" user and point
\"${ROOT}/etc/conf.d/buildbot_worker.myinstance\" at the right location.
The scripts can	run as a different user if desired."

src_prepare() {
	# Remove shipped windows start script
	sed -e "/'buildbot_worker_windows_service=buildbot_worker.scripts.windows_service:HandleCommandLine',/d" \
		-i setup.py || die

	distutils-r1_src_prepare
}

python_test() {
	"${EPYTHON}" -m twisted.trial buildbot_worker || die "Tests failed with ${EPYTHON}"
}

python_install_all() {

	distutils-r1_python_install_all

	doman docs/buildbot-worker.1

	newconfd "${FILESDIR}/buildbot_worker.confd2" buildbot_worker
	newinitd "${FILESDIR}/buildbot_worker.initd2" buildbot_worker
	systemd_dounit "${FILESDIR}/buildbot_worker.target"
	systemd_newunit "${FILESDIR}/buildbot_worker_at.service" "buildbot_worker@.service"
	systemd_install_serviced "${FILESDIR}/buildbot_worker_at.service.conf" "buildbot_worker@.service"

	dodir /var/lib/buildbot_worker
	cp "${FILESDIR}/buildbot.tac.sample" "${D}/var/lib/buildbot_worker"|| die "Install failed!"

	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog

	if [[ -n ${REPLACING_VERSIONS} ]]; then
		ewarn
		ewarn "More than one instance of a buildbot_worker can be run simultaneously."
		ewarn " Note that \"BASEDIR\" in the buildbot_worker configuration file"
		ewarn "is now the common base directory for all instances. If you are migrating from an older"
		ewarn "version, make sure that you copy the current contents of \"BASEDIR\" to a subdirectory."
		ewarn "The name of the subdirectory corresponds to the name of the buildbot_worker instance."
		ewarn "In order to start the service running OpenRC-based systems need to link to the init file:"
		ewarn "    ln --symbolic --relative /etc/init.d/buildbot_worker /etc/init.d/buildbot_worker.myinstance"
		ewarn "    rc-update add buildbot_worker.myinstance default"
		ewarn "    /etc/init.d/buildbot_worker.myinstance start"
		ewarn "Systems using systemd can do the following:"
		ewarn "    systemctl enable buildbot_worker@myinstance.service"
		ewarn "    systemctl enable buildbot_worker.target"
		ewarn "    systemctl start buildbot_worker.target"
	fi
}

pkg_config() {
	local buildworker_path="/var/lib/buildbot_worker"
	local log_path="/var/log/buildbot_worker"

	einfo "This will prepare a new buildbot_worker instance in ${buildworker_path}."
	einfo "Press Control-C to abort."

	einfo "Enter the name for the new instance: "
	read instance_name
	[[ -z "${instance_name}" ]] && die "Invalid instance name"

	local instance_path="${buildworker_path}/${instance_name}"
	local instance_log_path="${log_path}/${instance_name}"

	if [[ -e "${instance_path}" ]]; then
		eerror "The instance with the specified name already exists:"
		eerror "${instance_path}"
		die "Instance already exists"
	fi

	if [[ ! -d "${instance_path}" ]]; then
		mkdir --parents "${instance_path}" || die "Unable to create directory ${buildworker_path}"
	fi
	chown --recursive buildbot:buildbot "${instance_path}" || die "Setting permissions for instance failed"
	cp "${buildworker_path}/buildbot.tac.sample" "${instance_path}/buildbot.tac" \
		|| die "Moving sample configuration failed"
	ln --symbolic --relative "/etc/init.d/buildbot_worker" "/etc/init.d/buildbot_worker.${instance_name}" \
		|| die "Unable to create link to init file"

	if [[ ! -d "${instance_log_path}" ]]; then
		mkdir --parents "${instance_log_path}" || die "Unable to create directory ${instance_log_path}"
		chown --recursive buildbot:buildbot "${instance_log_path}" \
			|| die "Setting permissions for instance failed"
	fi
	ln --symbolic --relative "${instance_log_path}/twistd.log" "${instance_path}/twistd.log" \
		|| die "Unable to create link to log file"

	einfo "Successfully created a buildbot_worker instance at ${instance_path}."
	einfo "To change the default settings edit the buildbot.tac file in this directory."
}
