#!/bin/bash -i
set -e
set -x


get_arch() {
  case "$(uname -m)" in
    x86_64)
      ARCH="amd64"
      ;;
    aarch64|arm64)
      ARCH="arm64"
      ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >/dev/stderr
      exit 1
      ;;
  esac
  echo "$ARCH"
}

check_version() {
  local VERSION="${1:-latest}"
  case "${VERSION}" in
    latest)
      # TODO: we should resolve it instead of harcoding it
      echo "v0.18.0"
      ;;
    *)
      if [[ "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$ ]]; then
        echo "$VERSION"
      else
        echo "Invalid semver format: $VERSION" >/dev/stderr
        exit 1
      fi
  esac
}

check_packages() {
  if ! dpkg -s "$@" >/dev/null 2>&1; then
		if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
			echo "Running apt-get update..."
			apt-get update -y
		fi
		apt-get -y install --no-install-recommends "$@"
	fi
}

check_alpine_packages() {
    apk add -v --no-cache "$@"
}

install_asdf() {
	local GIVEN_VERSION="${1:-latest}"
  local ARCH="$(get_arch)"
  local VERSION="$(check_version "${GIVEN_VERSION}")"

  echo "+ installing asdf version=$VERSION arch=$ARCH"

	# install git and curl if does not exists
	if cat /etc/os-release | grep "ID_LIKE=.*alpine.*\|ID=.*alpine.*" ; then
    check_alpine_packages git bash curl ca-certificates bash-completion
	elif cat /etc/os-release | grep  "ID_LIKE=.*debian.*\|ID=.*debian.*"; then
		check_packages git bash curl ca-certificates bash-completion
	fi

	# asdf may be installed somewhere on the machine, but we need it to be accessible to the remote user
	# the code bellow will return 2 only when asdf is available, and 1 otherwise
	set +e
	su - "$_REMOTE_USER" <<EOF
		if type asdf >/dev/null 2>&1; then
			exit 2
		fi
		exit 1
EOF
	exit_code=$?
	set -e

	if [ "${exit_code}" -eq 2 ]; then
		echo "asdf already available to remote user, skip this step"
	else
		# asdf is not available install it
    echo "+ installing asdf binary"
    cd /tmp && \
      curl -fL -o asdf-${VERSION}-linux-${ARCH}.tar.gz https://github.com/asdf-vm/asdf/releases/download/${VERSION}/asdf-${VERSION}-linux-${ARCH}.tar.gz && \
      tar -zxvf asdf-${VERSION}-linux-${ARCH}.tar.gz && \
      rm -rf asdf-${VERSION}-linux-${ARCH}.tar.gz && \
      mv asdf /usr/local/bin/

    # update shell configs
    updaterc '\n# asdf setup (do not edit)'
    # shellcheck disable=SC2016
    updaterc 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"'
    updaterc '. <(asdf completion bash)'
	fi
}

updaterc() {
	if cat /etc/os-release | grep "ID_LIKE=.*alpine.*\|ID=.*alpine.*" ; then
		echo "Updating /etc/profile"
		echo -e "$1" >>/etc/profile
	fi
	if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
		echo "Updating /etc/bash.bashrc"
		echo -e "$1" >>/etc/bash.bashrc
	fi
	if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
		echo "Updating /etc/zsh/zshrc"
		echo -e "$1" >>/etc/zsh/zshrc
	fi
}

# main
echo "+ installing asdf"
install_asdf $ASDF_VERSION
