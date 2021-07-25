#!/bin/bash

# Tests for agogpixel/foundation.

set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
#set -o xtrace

FOUNDATION_TEST_IMAGE=

foundation_test_main() {
    if [ "${#}" -lt 1 ]; then
        printf 'No image provided.\n'
        exit 1
    fi

    FOUNDATION_TEST_IMAGE="${1}"

    printf 'Test %s...\n\n' "${FOUNDATION_TEST_IMAGE}"

    foundation_test_root_no_daemon
    printf '\n'

    foundation_test_non_root_no_daemon
    printf '\n'

    foundation_test_root_as_daemon
    printf '\n'

    foundation_test_non_root_as_daemon
    printf '\n'

    printf 'Test %s ok.\n\n' "${FOUNDATION_TEST_IMAGE}"
}

foundation_test_root_no_daemon() {
    local cmds=('ps aux')

    printf 'Root user, no daemon...\n'

    for cmd in "${cmds[@]}"; do
        printf "Testing '%s'...\n" "${cmd}"
        docker run --rm "${FOUNDATION_TEST_IMAGE}" ${cmd}
        printf '%s ok.\n' "${cmd}"
    done

    printf 'Root user, no daemon ok.\n'
}

foundation_test_non_root_no_daemon() {
    local cmds=('ps aux')

    printf 'Non-root user, no daemon...\n'

    for cmd in "${cmds[@]}"; do
        printf "Testing '%s'...\n" "${cmd}"
        docker run --rm --user non-root "${FOUNDATION_TEST_IMAGE}" ${cmd}
        printf '%s ok.\n' "${cmd}"
    done

    printf 'Non-root user, no daemon ok.\n'
}

foundation_test_root_as_daemon() {
    local cmds=('ps aux')
    local sleep_time=3
    local container_name=test_root_as_daemon

    printf 'Root user, as daemon...\n'

    docker run -d --name "${container_name}" "${FOUNDATION_TEST_IMAGE}"
    sleep "${sleep_time}"

    for cmd in "${cmds[@]}"; do
        printf "Testing '%s'...\n" "${cmd}"
        docker exec "${container_name}" ${cmd}
        printf '%s ok.\n' "${cmd}"
    done

    docker rm -f "${container_name}"

    printf 'Root user, as daemon ok.\n'
}

foundation_test_non_root_as_daemon() {
    local cmds=('ps aux')
    local sleep_time=3
    local container_name=test_non_root_as_daemon

    printf 'Non-root user, as daemon...\n'

    docker run -d --user non-root --name "${container_name}" "${FOUNDATION_TEST_IMAGE}"
    sleep "${sleep_time}"

    for cmd in "${cmds[@]}"; do
        printf "Testing '%s'...\n" "${cmd}"
        docker exec "${container_name}" ${cmd}
        printf '%s ok.\n' "${cmd}"
    done

    docker rm -f "${container_name}"

    printf 'Non-root user, as daemon ok.\n'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    foundation_test_main "${@}"
fi
