#!/bin/bash

help()
{
    echo ""
    echo "Script to install KiCad EDA with custom libraires."
    echo ""
    echo "Options:"
    echo "    -d|--directory <dir>    : Install directory"
    echo "    -e|--env-install        : Setup kicad environement links and variables"
    echo "    -f|--full-install       : Install kicad, libraries and env"
    echo "    -h|--help               : Print this help"
    echo "    -k|--kicad-install      : Install kicad EDA"
    echo "    -l|--libraries-install  : Install kicad libraries"
    echo "    -p|--projets-install    : Install kicad projects"
}

kicad-install()
{
    if lsb_release -i | grep -v Ubuntu; then
        echo "Only Ubuntu installation supported."
        exit 1
    fi

    if command -v kicad; then
        echo "Kicad is already installed. Abort!"
        exit 1
    fi
    
    sudo add-apt-repository --yes ppa:kicad/kicad-8.0-releases &&
    sudo apt update &&
    sudo apt install --no-install-recommends kicad
    if [ "$?" != "0" ]; then
        echo "Fail to install kicad. Abort!"
        exit 1
    fi
        
}

libraries-install()
{
    if ! command -v git; then
        echo "Need to install 'git':"
        echo "    sudo apt install git"
        exit 1
    fi
    
    git clone https://github.com/sebmalissard/kicad-symbols    -b staging_v8 "${INSTALL_DIR}/kicad-symbols"
    git clone https://github.com/sebmalissard/kicad-footprints -b staging_v8 "${INSTALL_DIR}/kicad-footprints"
    git clone https://github.com/sebmalissard/kicad-packages3D -b staging_v8 "${INSTALL_DIR}/kicad-packages3D"
}

env-install()
{
    if [ -e "${HOME}/.config/kicad/8.0/fp-lib-table" ]; then
        echo "Kicad was already installed. Need to delete this file: '${HOME}/.config/kicad/8.0/fp-lib-table'. Abort!"
        exit 1
    fi

    if [ -e "${HOME}/.config/kicad/8.0/sym-lib-table" ]; then
        echo "Kicad was already installed. Need to delete this file: '${HOME}/.config/kicad/8.0/sym-lib-table'. Abort!"
        exit 1
    fi
    
    if ! grep -q "kicad_env.sh" "${HOME}/.bashrc"; then
        echo "" >> "${HOME}/.bashrc"
        echo ". ~/.config/kicad/kicad_env.sh" >> "${HOME}/.bashrc"
    fi

    if [ -e "${HOME}/.config/kicad/kicad_env.sh" ]; then
        rm "${HOME}/.config/kicad/kicad_env.sh"
    fi

    mkdir -p "${HOME}/.config/kicad/8.0"

    echo "#!/bin/sh"                                                             > "${HOME}/.config/kicad/kicad_env.sh"
    echo ""                                                                     >> "${HOME}/.config/kicad/kicad_env.sh"
    echo "export KICAD8_FOOTPRINT_DIR=\"${INSTALL_DIR_ABS}/kicad-footprints\""  >> "${HOME}/.config/kicad/kicad_env.sh"
    echo "export KICAD8_3DMODEL_DIR=\"${INSTALL_DIR_ABS}/kicad-packages3D\""    >> "${HOME}/.config/kicad/kicad_env.sh"
    echo "export KICAD8_SYMBOL_DIR=\"${INSTALL_DIR_ABS}/kicad-symbols\""        >> "${HOME}/.config/kicad/kicad_env.sh"
    
    ln -s "${INSTALL_DIR_ABS}/kicad-footprints/fp-lib-table" "${HOME}/.config/kicad/8.0/fp-lib-table"
    ln -s "${INSTALL_DIR_ABS}/kicad-symbols/sym-lib-table" "${HOME}/.config/kicad/8.0/sym-lib-table"

    echo "Before launch KiCad source new environment  variables"
    echo ". ~/.bashrc"
    echo ""
}

projects-install()
{
    if ! command -v git; then
        echo "Need to install 'git':"
        echo "    sudo apt install git"
        exit 1
    fi
    
    git clone https://github.com/sebmalissard/kicad-projects    "${INSTALL_DIR}/kicad-projects"
}

INSTALL_DIR=
KICAD_INSTALL=
LIBRARIES_INSTALL=
ENV_INSTALL=
PROJECTS_INSTALL=
            
while [[ $# -gt 0 ]]; do
    val="${1}"
    shift
    
    case ${val} in
        -d|--directory)
            INSTALL_DIR="${1}"
            shift
            ;;
        
        -e|--env-install)
            ENV_INSTALL=1
            ;;
        
        -f|--full-install)
            KICAD_INSTALL=1
            LIBRARIES_INSTALL=1
            ENV_INSTALL=1
            PROJECTS_INSTALL=1
            ;;
        
        -h|--help)
            help
            exit 1
            ;;
        
        -k|--kicad-install)
            KICAD_INSTALL=1
            ;;
        
        -l|--libraries-install)
            LIBRARIES_INSTALL=1
            ;;
        
        -p|--projets-install)
            PROJECTS_INSTALL=1
            ;;
        
        *)
            echo "Error invalid argument: '${val}'"
            help
            exit 1
            ;;
    esac
done

if [ -z "$INSTALL_DIR" ]; then
    echo "Error install directory required."
    help
    exit 1
fi

if [ ! -d "${INSTALL_DIR}" ]; then
    echo "The following directoty doesn't exist: '${INSTALL_DIR}', do you want create it [Y]?"
    read -r val
    if [ "$val" != "y" ] && [ "$val" != "Y" ] && [ "$val" != "" ]; then
        exit 0
    fi
    mkdir -p "${INSTALL_DIR}" || exit 1
fi

INSTALL_DIR_ABS="$(realpath "${INSTALL_DIR}")"

[ "${KICAD_INSTALL}" == "1" ]       && kicad-install
[ "${LIBRARIES_INSTALL}" == "1" ]   && libraries-install
[ "${ENV_INSTALL}" == "1" ]         && env-install
[ "${PROJECTS_INSTALL}" == "1" ]    && projects-install
