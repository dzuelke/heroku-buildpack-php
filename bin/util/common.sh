error() {
  echo
  echo " !     ERROR: $*" | indent no_first_line_indent
  echo
  exit 1
}

warning() {
  echo
  echo " !     WARNING: $*" | indent no_first_line_indent
  echo
}

warning_inline() {
  echo " !     WARNING: $*" | indent no_first_line_indent
}

status() {
  echo "-----> $*"
}

notice() {
  echo
  echo "NOTICE: $*" | indent
  echo
}

notice_inline() {
  echo "NOTICE: $*" | indent
}

# sed -l basically makes sed replace and buffer through stdin to stdout
# so you get updates while the command runs and dont wait for the end
# e.g. npm install | indent
indent() {
  # if an arg is given it's a flag indicating we shouldn't indent the first line, so use :+ to tell SED accordingly if that parameter is set, otherwise null string for no range selector prefix (it selects from line 2 onwards and then every 1st line, meaning all lines)
  c="${1:+"2,999"} s/^/       /"
  case $(uname) in
    Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
    *)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_dir" ]; then
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}

merge_bucket() {
    ret=$(curl --fail --silent --location "$1") || error "Failed to fetch list of items for the following S3 bucket:
$1" 1>&2
    # fixme: handle malformed data without messages, broken pipe error etc
    # fixme: check "Truncated" field to see if we need to fetch more
    # fixme: use two arguments (URL, then stack name) instead, and fetch matching stack items manually from list, assembling final URLs with the given URL to allow buckets that just look like, but are not actually on, S3?
    ret="$(echo "$ret" | python -c 'import xml.etree.ElementTree as ET, sys, re
s3 = ET.parse(sys.stdin)
bucket = s3.getroot().findtext("{http://s3.amazonaws.com/doc/2006-03-01/}Name")
prefix = s3.getroot().findtext("{http://s3.amazonaws.com/doc/2006-03-01/}Prefix")
items = s3.findall("./{http://s3.amazonaws.com/doc/2006-03-01/}Contents")
ret = [
    re.match("^"+re.escape(prefix)+"((?:[a-z0-9-]+/)*[a-z-0-9-]+?)-?(((?<=-)\d[\.\d]*)[._-]?(?:(stable|beta|b|RC|alpha|a|patch|pl|p)(?:[.-]?(\d+))?)?([.-]?dev)?)?\.tar\.gz$", item.findtext("{http://s3.amazonaws.com/doc/2006-03-01/}Key").strip()).groups("0.0.0")[0:2]
    +
    (
        item.findtext("{http://s3.amazonaws.com/doc/2006-03-01/}Size").strip(),
        "https://"+bucket+".s3.amazonaws.com/"+item.findtext("{http://s3.amazonaws.com/doc/2006-03-01/}Key").strip()
    )
    for item in items if item.findtext("{http://s3.amazonaws.com/doc/2006-03-01/}Key").strip()[-1] != "/"
]
print "\n".join(["\t".join(item) for item in ret])')
${2:-''}" 2>/dev/null || error "Failed to parse list of items for the following S3 bucket:
${1}" 1>&2
    # first, stable sort (to preserve order of "overriding" items occuring first) by field 1 (component name), then field 2 (version; version sort does not matter), and use unique mode so the first occurrence remains
    # then, nuke all entries where field 3 (size) is 0, as that's the method of removing a previously available entry
    echo "$ret" | sort --stable --unique -k1,2 | awk '$3 > 0'
}
