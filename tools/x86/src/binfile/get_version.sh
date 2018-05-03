#!/bin/sh
#
# This scripts adds local version information from the version
# control systems git, mercurial (hg) and subversion (svn).
#
# It was originally copied from the Linux kernel v3.2.0-rc4 and modified
# to support the U-Boot build-system.
#

usage() {
	echo "Usage: $0 [--save-scmversion] [srctree]" >&2
	exit 1
}

scm_only=false
srctree=.
if test "$1" = "--save-scmversion"; then
	scm_only=true
	shift
fi
if test $# -gt 0; then
	srctree=$1
	shift
fi
if test $# -gt 0 -o ! -d "$srctree"; then
	usage
fi

scm_version()
{
	local short
	short=false

	cd "$srctree"
	if test -e .scmversion; then
		cat .scmversion
		return
	fi
	if test "$1" = "--short"; then
		short=true
	fi

	# Check for git and a git repo.
	if test -e .git && head=`git rev-parse --verify --short HEAD 2>/dev/null`; then

		# If we are at a tagged commit (like "v2.6.30-rc6"), we ignore
		# it, because this version is defined in the top level Makefile.
		if [ -z "`git describe --exact-match 2>/dev/null`" ]; then

			# If only the short version is requested, don't bother
			# running further git commands
			if $short; then
				echo "+"
				return
			fi
			# If we are past a tagged commit (like
			# "v2.6.30-rc5-302-g72357d5"), we pretty print it.
			if atag="`git describe 2>/dev/null`"; then
				echo "$atag" | awk -F- '{printf("-%s", $(NF))}'

			# If we don't have a tag at all we print -g{commitish}.
			else
				printf '%s%s' -g $head
			fi
		fi

		# Is this git on svn?
		if git config --get svn-remote.svn.url >/dev/null; then
			printf -- '-svn%s' "`git svn find-rev $head`"
		fi

		# Update index only on r/w media
		[ -w . ] && git update-index --refresh --unmerged > /dev/null

		# Check for uncommitted changes
		if git diff-index --name-only HEAD | grep -v "^scripts/package" \
		    | read dummy; then
			printf '%s' -dirty
		fi

		# All done with git
		return
	fi

	# Check for mercurial and a mercurial repo.
	if test -d .hg && hgid=`hg id 2>/dev/null`; then
		# Do we have an tagged version?  If so, latesttagdistance == 1
		if [ "`hg log -r . --template '{latesttagdistance}'`" == "1" ]; then
			id=`hg log -r . --template '{latesttag}'`
			printf '%s%s' -hg "$id"
		else
			tag=`printf '%s' "$hgid" | cut -d' ' -f2`
			if [ -z "$tag" -o "$tag" = tip ]; then
				id=`printf '%s' "$hgid" | sed 's/[+ ].*//'`
				printf '%s%s' -hg "$id"
			fi
		fi

		# Are there uncommitted changes?
		# These are represented by + after the changeset id.
		case "$hgid" in
			*+|*+\ *) printf '%s' -dirty ;;
		esac

		# All done with mercurial
		return
	fi

	# Check for svn and a svn repo.
	if rev=`svn info 2>/dev/null | grep '^Last Changed Rev'`; then
		rev=`echo $rev | awk '{print $NF}'`
		printf -- '-svn%s' "$rev"

		# All done with svn
		return
	fi
}

collect_files()
{
	local file res

	for file; do
		case "$file" in
		*\~*)
			continue
			;;
		esac
		if test -e "$file"; then
			res="$res$(cat "$file")"
		fi
	done
	echo "$res"
}

if $scm_only; then
	if test ! -e .scmversion; then
		res=$(scm_version)
		echo "$res" >.scmversion
	fi
	exit
fi

#if test -e include/config/auto.conf; then
#	. include/config/auto.conf
#else
#	echo "Error: kernelrelease not valid - run 'make prepare' to update it"
#	exit 1
#fi
CONFIG_LOCALVERSION=
CONFIG_LOCALVERSION_AUTO=y

# localversion* files in the build and source directory
res="$(collect_files localversion*)"
if test ! "$srctree" -ef .; then
	res="$res$(collect_files "$srctree"/localversion*)"
fi

# CONFIG_LOCALVERSION and LOCALVERSION (if set)
res="${res}${CONFIG_LOCALVERSION}${LOCALVERSION}"

# scm version string if not at a tagged commit
if test "$CONFIG_LOCALVERSION_AUTO" = "y"; then
	# full scm version string
	res="$res$(scm_version)"
else
	# append a plus sign if the repository is not in a clean
	# annotated or signed tagged state (as git describe only
	# looks at signed or annotated tags - git tag -a/-s) and
	# LOCALVERSION= is not specified
	if test "${LOCALVERSION+set}" != "set"; then
		scm=$(scm_version --short)
		res="$res${scm:++}"
	fi
fi

now=$(date -d today +%Y%m%d)
res="$res-$now"
echo "$res"
