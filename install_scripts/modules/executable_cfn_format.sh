#!/usr/bin/env bash

set -euo pipefail

version="${CFN_FORMAT_VERSION:-v1.24.4}"
installDir="${CFN_FORMAT_INSTALL_DIR:-${HOME}/.local/bin}"
package="github.com/aws-cloudformation/rain/cmd/cfn-format@${version}"

mkdir -p "${installDir}"

if command -v mise >/dev/null 2>&1; then
    GOBIN="${installDir}" mise x go@latest -- go install "${package}"
elif command -v go >/dev/null 2>&1; then
    GOBIN="${installDir}" go install "${package}"
else
    echo "Cannot install cfn-format: mise or Go is required." >&2
    exit 1
fi

if [[ ! -x "${installDir}/cfn-format" ]]; then
    echo "cfn-format was not installed at ${installDir}/cfn-format." >&2
    exit 1
fi

"${installDir}/cfn-format" --version
