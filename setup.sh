#!/usr/bin/env bash

set -euo pipefail

script_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspaces_folder="$(cd "${script_folder}/.." && pwd)"

cp -r "${script_folder}/.vscode" "${workspaces_folder}/"
cp "${script_folder}/.editorconfig" "${workspaces_folder}"
cp "${script_folder}/.gitattributes" "${workspaces_folder}"
