#!/bin/sh
# Copyright (C) 2012, Canonical Group, Ltd.
#
# Author: Ben Howard <ben.howard@canonical.com>
# Author: Scott Moser <scott.moser@ubuntu.com>
# (c) 2012, Canonical Group, Ltd.
#
# This file is part of cloud-init. See LICENSE file for license information.
 
# Purpose: Detect invalid locale settings and inform the user
#  of how to fix them.

locale_warn() {
	local bad_names="" bad_lcs="" key="" val="" var="" vars="" bad_kv=""
	local w1 w2 w3 w4 remain

	# if shell is zsh, act like sh only for this function (-L).
	# The behavior change will not permenently affect user's shell.
	[ "${ZSH_NAME+zsh}" = "zsh" ] && emulate -L sh

	# locale is expected to output either:
	# VARIABLE=
	# VARIABLE="value"
	# locale: Cannot set LC_SOMETHING to default locale
	while read -r w1 w2 w3 w4 remain; do
		case "$w1" in
			locale:) bad_names="${bad_names} ${w4}";;
			*)
				key=${w1%%=*}
				val=${w1#*=}
				val=${val#\"}
				val=${val%\"}
				vars="${vars} $key=$val";;
		esac
	done
	for bad in $bad_names; do
		for var in ${vars}; do
			[ "${bad}" = "${var%=*}" ] || continue
			val=${var#*=}
			[ "${bad_lcs#* ${val}}" = "${bad_lcs}" ] &&
				bad_lcs="${bad_lcs} ${val}"
			bad_kv="${bad_kv} $bad=$val"
			break
		done
	done
	bad_lcs=${bad_lcs# }
	bad_kv=${bad_kv# }
	[ -n "$bad_lcs" ] || return 0

	printf "_____________________________________________________________________\n"
	printf "WARNING! Your environment specifies an invalid locale.\n"
	printf " The unknown environment variables are:\n   %s\n" "$bad_kv"
	printf " This can affect your user experience significantly, including the\n"
	printf " ability to manage packages. You may install the locales by running:\n\n"
	printf " sudo dpkg-reconfigure locales\n\n"
	printf " and select the missing language. Alternatively, you can install the\n"
	printf " locales-all package:\n\n"
	printf " sudo apt-get install locales-all\n\n"
	printf "To disable this message for all users, run:\n"
	printf "   sudo touch /var/lib/cloud/instance/locale-check.skip\n"
	printf "_____________________________________________________________________\n\n"

	# only show the message once
	: > ~/.cloud-locale-test.skip 2>/dev/null || :
}

[ -f ~/.cloud-locale-test.skip -o -f /var/lib/cloud/instance/locale-check.skip ] ||
	locale 2>&1 | locale_warn

unset locale_warn
# vi: ts=4 noexpandtab
