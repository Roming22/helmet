#!/usr/bin/env bash
# 
# Release script for helmet framework. Verifies the tag exists and populates the
# release changelog. It assumes the tag was already created by GitHub and the
# script acts upon updating the release notes.
#
# Usage:
#   $ GITHUB_REF_NAME=v0.0.0 ./hack/release.sh [--dry-run]
#

set -eu -o pipefail

# GitHub Actions variable, shows the release tag name.
readonly GITHUB_REF_NAME=${GITHUB_REF_NAME:-}

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
	DRY_RUN=true
fi

# Verifies the informed tag is not empty.
verify_tag() {
	if [[ -z "${GITHUB_REF_NAME}" ]]; then
		echo "[ERROR] GITHUB_REF_NAME is required."
		exit 1
	fi
	echo "Tag '${GITHUB_REF_NAME}' verified."
}

# Updates the release notes for the informed tag (pre-release). Preserves any
# existing notes authored via the GitHub UI, appending the auto-generated
# changelog below them.
update_release_notes() {
	echo "Generating release notes for ${GITHUB_REF_NAME}..."

	local existing generated notes_file
	existing="$(gh release view "${GITHUB_REF_NAME}" --json body -q '.body // ""')"
	generated="$(gh api "repos/{owner}/{repo}/releases/generate-notes" \
		-f tag_name="${GITHUB_REF_NAME}" \
		-q '.body // ""')"

	# Marker used to delimit hand-written notes from auto-generated changelog.
	# On reruns the previous generated section is stripped so the result is
	# idempotent.
	local marker="<!-- GENERATED-RELEASE-NOTES -->"

	# Strip any prior generated section from existing notes.
	if [[ -n "${existing}" ]]; then
		existing="$(echo "${existing}" \
			| sed "/${marker}/,\$d" \
			| awk '{if(NF){if(b)printf "%s",b; b=""; print} else b=b $0 ORS}')"
	fi

	notes_file="$(mktemp)"
	trap "rm -f '${notes_file}'" EXIT

	if [[ -n "${existing}" ]]; then
		printf '%s\n\n%s\n%s\n' "${existing}" "${marker}" "${generated}" >"${notes_file}"
	else
		printf '%s\n%s\n' "${marker}" "${generated}" >"${notes_file}"
	fi

	if [[ "${DRY_RUN}" == true ]]; then
		echo "[DRY-RUN] Would update release ${GITHUB_REF_NAME} with:"
		cat "${notes_file}"
		return
	fi

	gh release edit "${GITHUB_REF_NAME}" --notes-file "${notes_file}"
	echo "Release ${GITHUB_REF_NAME} updated successfully."
}

main() {
	verify_tag
	update_release_notes
}

main
