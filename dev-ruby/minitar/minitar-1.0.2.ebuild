# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
USE_RUBY="ruby31 ruby32 ruby33 ruby34"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_RECIPE_DOC="none"

RUBY_FAKEGEM_EXTRADOC="History.md README.rdoc"

RUBY_FAKEGEM_GEMSPEC="minitar.gemspec"

inherit ruby-fakegem

DESCRIPTION="Provides POSIX tarchive management from Ruby programs"
HOMEPAGE="https://github.com/halostatue/minitar"
SRC_URI="https://github.com/halostatue/minitar/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RUBY_S="minitar-${PV}"

LICENSE="|| ( BSD-2 Ruby-BSD )"
SLOT="$(ver_cut 1)"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="test"

ruby_add_bdepend "test? ( >=dev-ruby/minitest-5.3:5 )"

all_ruby_prepare() {
	sed -e '/focus/ s:^:#:' \
		-i test/minitest_helper.rb || die

	# Ensure all data is properly cast to string when writing the dummy
	# test tar files. For some reasons this does not work properly on
	# ruby32, although it does work on ruby31 and ruby33.
	sed -e '15 s/data << dat/data << dat.to_s/' \
		-i test/test_tar_writer.rb || die
}

each_ruby_test() {
	MT_NO_PLUGINS=true ${RUBY} -Ilib:test:. -e 'Dir["test/test_*.rb"].each{|f| require f}' || die
}
