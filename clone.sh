#!/usr/bin/env bash

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required but not installed"
  exit 1
fi

script_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspaces_folder="$(cd "${script_folder}/.." && pwd)"

clone-repo() {
  local repo="${1}"

  target_dir="${repo#*/}"
  target_dir="${target_dir#radius-}"

  cd "${workspaces_folder}" || return

  if repo_info=$(gh repo view "${repo}" --json isFork,parent,url 2>/dev/null); then
    is_fork=$(echo "${repo_info}" | jq -r '.isFork')
    parent=$(echo "${repo_info}" | jq -r '.parent')

    if [[ "${is_fork}" == "true" && "${parent}" != "null" ]]; then
      parent_url=$(echo "${repo_info}" | jq -r '"https://github.com/" + .parent.owner.login + "/" + .parent.name')
      fork_url=$(echo "${repo_info}" | jq -r '.url')
      target_dir=$(echo "${repo_info}" | jq -r '.parent.name')

      if [[ -d "${target_dir}" ]]; then
        echo "Already cloned ${repo}"
        gh repo sync "${repo}"

        return
      fi

      if [[ ! -d "${target_dir}" ]]; then
        echo "Fork detected. Cloning source repo: ${parent_url}"
        git clone "${parent_url}" "${target_dir}"
      fi

      if [[ -d "${target_dir}" ]]; then
        cd "${target_dir}" || return
        echo "Adding fork remote: ${fork_url}"
        git remote add fork "${fork_url}"
        cd "${workspaces_folder}" || return
      fi

      return
    fi
  fi

  if [[ -d "${target_dir}" && "${parent}" == "null" ]]; then
    echo "Already cloned ${repo}"
    gh repo sync "${repo}"
    return
  fi

  git clone "https://github.com/${repo}" "${target_dir}"
}

devcontainer_path="${script_folder}/.devcontainer/devcontainer.json"

if [[ -f "${devcontainer_path}" ]]; then
  repositories=$(jq -r '.customizations.codespaces.repositories | keys[]' "${devcontainer_path}") || {
    echo "Error: Failed to parse devcontainer.json"
    exit 1
  }
  while read -r repository; do
    clone-repo "${repository}"
  done <<<"${repositories}"
fi
