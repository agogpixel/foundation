#!/bin/sh

# Derived from https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-alpine.sh.
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.

# shellcheck disable=SC3000-SC4000

set -o errexit
set -o noclobber

if [ "${FOUNDATION_INSTALL_USING_BASH}" != true ]; then
    # Switch to bash.
    /bin/bash --version >/dev/null 2>&1 || apk add --no-cache --update bash >/dev/null 2>&1
    export FOUNDATION_INSTALL_USING_BASH=true
    exec /bin/bash "${0}" "${@}"
    exit $?
fi

# Ensure that login shells get the correct path if the user updated the PATH
# using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo ${PATH}')/\$\{PATH\}}" >/etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

set -o pipefail
set -o nounset
#set -o xtrace

readonly FOUNDATION_INSTALL_ALPINE_VERSION="${1}"
readonly FOUNDATION_INSTALL_USERNAME="${2:-"non-root"}"
readonly FOUNDATION_INSTALL_UID="${3:-"1000"}"
readonly FOUNDATION_INSTALL_GID="${4:-"1000"}"

readonly FOUNDATION_INSTALL_PACKAGES='ca-certificates logrotate procps runit rsyslog sudo tini'
readonly FOUNDATION_INSTALL_RUNIT_PATH=/etc/runit
readonly FOUNDATION_INSTALL_RUNIT_INITD_PATH="${FOUNDATION_INSTALL_RUNIT_PATH}"/init.d
readonly FOUNDATION_INSTALL_RUNIT_TERMD_PATH="${FOUNDATION_INSTALL_RUNIT_PATH}"/term.d
readonly FOUNDATION_INSTALL_ENTRYPOINT_PATH=/usr/local/bin/entrypoint.sh
readonly FOUNDATION_INSTALL_ENTRYPOINTD_PATH=/usr/local/share/entrypoint.d
readonly FOUNDATION_INSTALL_RUN_CONTAINER_PATH=/usr/local/bin/run-container.sh

foundation_install_main() {
    foundation_install_install_packages
    foundation_install_create_user
    foundation_install_add_user_to_sudoers
    foundation_install_setup_bashrc
    foundation_install_setup_entrypoint
    foundation_install_setup_runit
    foundation_install_setup_cron
    foundation_install_setup_rsyslog
    foundation_install_setup_logrotate
}

foundation_install_print_header() {
    cat <<EOF
################################################################################
# alpine:${FOUNDATION_INSTALL_ALPINE_VERSION} Foundation Installer
################################################################################
EOF
}

foundation_install_install_packages() {
    printf '\nInstalling packages...\n'
    apk add --no-cache --update ${FOUNDATION_INSTALL_PACKAGES}
}

foundation_install_create_user() {
    local username="${FOUNDATION_INSTALL_USERNAME}"
    local uid="${FOUNDATION_INSTALL_UID}"
    local gid="${FOUNDATION_INSTALL_GID}"

    printf "\nCreating user '%s' with uid %s & gid %s...\n" "${username}" "${uid}" "${gid}"

    addgroup "${username}" --gid "${gid}"
    adduser "${username}" --shell /bin/bash --uid "${uid}" --ingroup "${username}" --disabled-password
}

foundation_install_add_user_to_sudoers() {
    local username="${FOUNDATION_INSTALL_USERNAME}"

    printf "\nAdding user '%s' to sudoers...\n" "${username}"

    local sudoer_path=/etc/sudoers.d/"${username}"

    echo "${username}" ALL=\(root\) NOPASSWD:ALL >"${sudoer_path}"
    chmod 0440 "${sudoer_path}"
}

foundation_install_setup_bashrc() {
    printf "\nSetting up .bashrc...\n"

    local username="${FOUNDATION_INSTALL_USERNAME}"

    local rc
    rc="$(
        cat <<EOF
export USER=\$(whoami)
export PATH=\$PATH:\$HOME/bin

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1='\\[\\033[32m\\]'           # change to green
PS1="\$PS1"'\\u@\\h '           # user@host<space>
PS1="\$PS1"'\\[\\033[35m\\]'    # change to purple
PS1="\$PS1"'\\s-\\v '           # shell-version<space>
PS1="\$PS1"'\\[\\033[33m\\]'    # change to brownish yellow
PS1="\$PS1"'\\w '               # cwd<space>
PS1="\$PS1"'\\[\\033[36m\\]'    # change to cyan
PS1="\$PS1\$(parse_git_branch)" # current git branch
PS1="\$PS1"'\\[\\033[0m\\]'     # change color
PS1="\$PS1"'\\n'                # new line
PS1="\$PS1"'\\$ '               # prompt<space>

unset parse_git_branch
EOF
    )"

    echo "${rc}" >/root/.bashrc
    mkdir -p /root/bin

    local user_home=/home/"${username}"
    local user_bin="${user_home}"/bin
    local user_rc="${user_home}"/.bashrc

    echo "${rc}" >"${user_rc}"
    chown -R "${username}" "${user_rc}"
    mkdir -p "${user_bin}"
    chown -R "${username}" "${user_bin}"
}

foundation_install_setup_entrypoint() {
    printf "\nSetting up entrypoint...\n"

    mkdir -p "${FOUNDATION_INSTALL_ENTRYPOINTD_PATH}"

    foundation_install_get_entrypoint >"${FOUNDATION_INSTALL_ENTRYPOINT_PATH}"
    chmod 755 "${FOUNDATION_INSTALL_ENTRYPOINT_PATH}"
    ln -s "${FOUNDATION_INSTALL_ENTRYPOINT_PATH}" /entrypoint.sh

    foundation_install_get_run_container >"${FOUNDATION_INSTALL_RUN_CONTAINER_PATH}"
    chmod 755 "${FOUNDATION_INSTALL_RUN_CONTAINER_PATH}"
}

foundation_install_setup_runit() {
    printf "\nSetting up runit...\n"

    mkdir -p "${FOUNDATION_INSTALL_RUNIT_INITD_PATH}"
    mkdir -p "${FOUNDATION_INSTALL_RUNIT_TERMD_PATH}"

    local runit_1="${FOUNDATION_INSTALL_RUNIT_PATH}"/1
    foundation_install_get_runit_1 >"${runit_1}"
    chmod +x "${runit_1}"

    local runit_2="${FOUNDATION_INSTALL_RUNIT_PATH}"/2
    foundation_install_get_runit_2 >"${runit_2}"
    chmod +x "${runit_2}"

    local runit_3="${FOUNDATION_INSTALL_RUNIT_PATH}"/3
    foundation_install_get_runit_3 >"${runit_3}"
    chmod +x "${runit_3}"

    local runit_ctrlaltdel="${FOUNDATION_INSTALL_RUNIT_PATH}"/ctrlaltdel
    foundation_install_get_runit_ctrlaltdel >"${runit_ctrlaltdel}"
    chmod +x "${runit_ctrlaltdel}"
}

foundation_install_setup_cron() {
    printf "\nSetting up cron...\n"

    local sv_path=/etc/sv/crond
    local sv_run_path="${sv_path}"/run

    mkdir -p "${sv_path}"

    cat >"${sv_run_path}" <<-EOF
#!/bin/sh
exec 2>&1
exec /usr/sbin/crond -f
EOF

    chmod +x "${sv_run_path}"
    ln -s "${sv_path}" /etc/service/crond
}

foundation_install_setup_rsyslog() {
    printf "\nSetting up rsyslog...\n"

    local sv_path=/etc/sv/rsyslogd
    local sv_run_path="${sv_path}"/run

    mkdir -p "${sv_path}"

    cat >"${sv_run_path}" <<-EOF
#!/bin/sh
exec 2>&1
exec /usr/sbin/rsyslogd -n
EOF

    chmod +x "${sv_run_path}"
    ln -s "${sv_path}" /etc/service/rsyslogd

    sed -i 's/module(load="imklog")/#module(load="imklog")/' /etc/rsyslog.conf

    sed -i "s?/etc/init.d/rsyslog --ifstarted reload >/dev/null?kill -HUP $(cat /var/run/rsyslogd.pid) \&> /dev/null?" /etc/logrotate.d/rsyslog
}

foundation_install_setup_logrotate() {
    printf "\nSetting up logrotate...\n"
}

foundation_install_get_entrypoint() {
    cat <<EOF
#!/bin/bash

# Derived from https://github.com/docker-suite/Install-Scripts/tree/master/alpine-runit
# Copyright (c) 2019 Docker-Suite
# Licensed under the MIT License. See https://github.com/docker-suite/Install-Scripts/blob/master/License.md for license information.

set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
#set -o xtrace

export FOUNDATION_RUNNING_AS_DAEMON=true

if [ \${#} -ne 0 ]; then
    FOUNDATION_RUNNING_AS_DAEMON=false
fi

for file in \$(find ${FOUNDATION_INSTALL_ENTRYPOINTD_PATH}/ -name '*.sh' -type f | sort -u ); do
    source "\${file}"
done

unset file

if [ "\${FOUNDATION_RUNNING_AS_DAEMON}" = false ]; then
    exec tini -- "\${@}"
fi

exec tini -- ${FOUNDATION_INSTALL_RUN_CONTAINER_PATH}
EOF
}

foundation_install_get_run_container() {
    cat <<EOF
#!/bin/bash

# Derived from https://github.com/docker-suite/Install-Scripts/tree/master/alpine-runit
# Copyright (c) 2019 Docker-Suite
# Licensed under the MIT License. See https://github.com/docker-suite/Install-Scripts/blob/master/License.md for license information.

set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
#set -o xtrace

RUNSVDIR=

# Wrapper function to only use sudo if not already root.
sudo_if() {
    if [ "\$(id -u)" -ne 0 ]; then
        sudo "\${@}"
    else
        "\${@}"
    fi
}

shutdown_container() {
    sudo_if ${FOUNDATION_INSTALL_RUNIT_PATH}/3

    if ps -p \${RUNSVDIR} &> /dev/null; then
        kill -HUP \${RUNSVDIR}
        wait \${RUNSVDIR}
    fi

    sleep 1

    for _pid in \$(ps -eo pid | grep -v PID  | tr -d ' ' | grep -v '^1\$' | head -n -6); do
        timeout 5 /bin/sh -c "kill \${_pid} && wait \${_pid} || kill -9 \${_pid}"
    done

    exit 0
}

sudo_if ${FOUNDATION_INSTALL_RUNIT_PATH}/1

sudo_if ${FOUNDATION_INSTALL_RUNIT_PATH}/2 &

RUNSVDIR=\${!}

trap shutdown_container SIGTERM SIGINT SIGHUP

wait \${RUNSVDIR}
shutdown_container
}
EOF
}

foundation_install_get_runit_1() {
    cat <<EOF
#!/bin/bash

# Derived from https://github.com/docker-suite/Install-Scripts/tree/master/alpine-runit
# Copyright (c) 2019 Docker-Suite
# Licensed under the MIT License. See https://github.com/docker-suite/Install-Scripts/blob/master/License.md for license information.

set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
#set -o xtrace

# Wrapper function to only use sudo if not already root.
sudo_if() {
    if [ "\$(id -u)" -ne 0 ]; then
        sudo "\${@}"
    else
        "\${@}"
    fi
}

if [ -n "\$(ls -A ${FOUNDATION_INSTALL_RUNIT_INITD_PATH})" ]; then
    for init_script in ${FOUNDATION_INSTALL_RUNIT_INITD_PATH}/*; do
        if [ -x "\${init_script}" ] && [ ! -e ${FOUNDATION_INSTALL_RUNIT_PATH}/stopall ]; then
            sudo_if \${init_script}

            \$rtn=\${?}

            if [ \${rtn} != 0 ]; then
                sudo_if touch ${FOUNDATION_INSTALL_RUNIT_PATH}/stopall
                exit 100
            fi
        else
            :
        fi
    done
fi

sudo_if touch ${FOUNDATION_INSTALL_RUNIT_PATH}/runit
sudo_if touch ${FOUNDATION_INSTALL_RUNIT_PATH}/stopit
sudo_if chmod 0 ${FOUNDATION_INSTALL_RUNIT_PATH}/stopit

unset init_script
EOF
}

foundation_install_get_runit_2() {
    cat <<EOF
#!/bin/bash

# Derived from https://github.com/docker-suite/Install-Scripts/tree/master/alpine-runit
# Copyright (c) 2019 Docker-Suite
# Licensed under the MIT License. See https://github.com/docker-suite/Install-Scripts/blob/master/License.md for license information.

set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
#set -o xtrace

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

exec env - PATH=\${PATH} /sbin/runsvdir -P /etc/service
EOF
}

foundation_install_get_runit_3() {
    cat <<EOF
#!/bin/bash

# Derived from https://github.com/docker-suite/Install-Scripts/tree/master/alpine-runit
# Copyright (c) 2019 Docker-Suite
# Licensed under the MIT License. See https://github.com/docker-suite/Install-Scripts/blob/master/License.md for license information.

set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
#set -o xtrace

# Wrapper function to only use sudo if not already root.
sudo_if() {
    if [ "\$(id -u)" -ne 0 ]; then
        sudo "\${@}"
    else
        "\${@}"
    fi
}

# Runlevels 0: Halt
LAST=0
# Runlevels 6: Reboot
test -x ${FOUNDATION_INSTALL_RUNIT_PATH}/reboot && LAST=6

# Stop every services : http://smarden.org/runit/sv.8.html
if [ -n "\$(ls -A /etc/service)" ]; then
    # First try to stop services by the reverse order.
    for srv in \$(ls -r1 /etc/service); do
        sudo_if sv -w196 force-stop "\${srv}" 2>/dev/null
    done

    # Then force stop all service if any remains.
    sudo_if sv -w196 force-stop /etc/service/* 2>/dev/null
fi

# Run every scripts in ${FOUNDATION_INSTALL_RUNIT_TERMD_PATH}
# before shutting down runit.
if [ -n "\$(ls -A ${FOUNDATION_INSTALL_RUNIT_TERMD_PATH})" ]; then
    # Iterate throwall script in ${FOUNDATION_INSTALL_RUNIT_TERMD_PATH}/
    # and run them if the scripts are executable.
    for term_script in ${FOUNDATION_INSTALL_RUNIT_TERMD_PATH}/*; do
        if [ -x "\${term_script}" ]; then
            sudo_if \${term_script}
        else
            :
        fi
    done
fi

# Just to make sure that runit will start
# at next start up
sudo_if rm -f ${FOUNDATION_INSTALL_RUNIT_PATH}/stopall

# Change the runlevel
[ -x /etc/init.d/rc ] && sudo_if /etc/init.d/rc \${LAST}

unset term_script srv
EOF
}

foundation_install_get_runit_ctrlaltdel() {
    cat <<EOF
#!/bin/bash

# Derived from https://github.com/docker-suite/Install-Scripts/tree/master/alpine-runit
# Copyright (c) 2019 Docker-Suite
# Licensed under the MIT License. See https://github.com/docker-suite/Install-Scripts/blob/master/License.md for license information.

set -o errexit
set -o pipefail
set -o noclobber
set -o nounset
#set -o xtrace

PATH=/bin:/usr/bin
msg="System is going down in 8 seconds..."

# Tell runit to shutdown the system: http://smarden.org/runit/runit.8.html#sect7
sudo_if touch ${FOUNDATION_INSTALL_RUNIT_PATH}/stopit
sudo_if chmod 100 ${FOUNDATION_INSTALL_RUNIT_PATH}/stopit && printf '%s' "\$msg" | wall

# Wait before shuting down
/bin/sleep 8

unset msg
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    foundation_install_main "${@}"
fi
