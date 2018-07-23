error() {
	# if arguments are given, redirect them to stdin
	# this allows the funtion to be invoked with a string argument, or with stdin, e.g. via <<-EOF
	(( $# )) && exec <<< "$@"
	echo -e "\033[1;31m" # bold; red
	echo -n " !     ERROR: "
	# this will be fed from stdin
	indent no_first_line_indent " !     "
	echo -e "\033[0m" # reset style
	exit 1
}

warning() {
	# if arguments are given, redirect them to stdin
	# this allows the funtion to be invoked with a string argument, or with stdin, e.g. via <<-EOF
	(( $# )) && exec <<< "$@"
	echo -e "\033[1;33m" # bold; yellow
	echo -n " !     WARNING: "
	# this will be fed from stdin
	indent no_first_line_indent " !     "
	echo -e "\033[0m" # reset style
}

warning_inline() {
	# if arguments are given, redirect them to stdin
	# this allows the funtion to be invoked with a string argument, or with stdin, e.g. via <<-EOF
	(( $# )) && exec <<< "$@"
	echo -n -e "\033[1;33m" # bold; yellow
	echo -n " !     WARNING: "
	# this will be fed from stdin
	indent no_first_line_indent " !     "
	echo -n -e "\033[0m" # reset style
}

status() {
	# if arguments are given, redirect them to stdin
	# this allows the funtion to be invoked with a string argument, or with stdin, e.g. via <<-EOF
	(( $# )) && exec <<< "$@"
	echo -n "-----> "
	# this will be fed from stdin
	cat
}

notice() {
	# if arguments are given, redirect them to stdin
	# this allows the funtion to be invoked with a string argument, or with stdin, e.g. via <<-EOF
	(( $# )) && exec <<< "$@"
	echo
	echo -n -e "\033[1;33m" # bold; yellow
	echo -n "       NOTICE: "
	echo -n -e "\033[0m" # reset style
	# this will be fed from stdin
	indent no_first_line_indent
	echo
}

notice_inline() {
	# if arguments are given, redirect them to stdin
	# this allows the funtion to be invoked with a string argument, or with stdin, e.g. via <<-EOF
	(( $# )) && exec <<< "$@"
	echo -n -e "\033[1;33m" # bold; yellow
	echo -n "       NOTICE: "
	echo -n -e "\033[0m" # reset style
	# this will be fed from stdin
	indent no_first_line_indent
}

# sed -l basically makes sed replace and buffer through stdin to stdout
# so you get updates while the command runs and dont wait for the end
# e.g. npm install | indent
indent() {
	# if any value (e.g. a non-empty string, or true, or false) is given for the first argument, this will act as a flag indicating we shouldn't indent the first line; we use :+ to tell SED accordingly if that parameter is set, otherwise null string for no range selector prefix (it selects from line 2 onwards and then every 1st line, meaning all lines)
	# if the first argument is an empty string, it's the same as no argument (useful if a second argument is passed)
	# the second argument is the prefix to use for indenting; defaults to seven space characters, but can be set to e.g. " !     " to decorate each line of an error message
	local c="${1:+"2,999"} s/^/${2-"       "}/"
	case $(uname) in
		Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
		*)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
	esac
}

export_env_dir() {
	local env_dir=$1
	local whitelist_regex=${2:-''}
	local blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH|IFS)$'}
	if [ -d "$env_dir" ]; then
		for e in $(ls $env_dir); do
			echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
			export "$e=$(cat $env_dir/$e)"
			:
		done
	fi
}

curl_retry_on_18() {
	local ec=18;
	local attempts=0;
	while (( ec == 18 && attempts++ < 3 )); do
		curl "$@" # -C - would return code 33 if unsupported by server
		ec=$?
	done
	return $ec
}
