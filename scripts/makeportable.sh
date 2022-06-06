#!/usr/bin/env bash
# usage: ./makeportable.sh

set -e # quit on error
MAKEPORTABLE=$(basename "$(readlink -f "${0}")")

log() {
    echo "[${MAKEPORTABLE}] $@"
}
err() {
    log >&2 "$@"
    exit 1
}

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ROOT_DIR="${ROOT_DIR:-$script_dir}"
temp_dir="${ROOT_DIR}/build/temp"
bundle_dir="${temp_dir}/streamlink"
python_dir="${bundle_dir}/python"
packages_dir="${bundle_dir}/packages"
dist_dir="${ROOT_DIR}/dist"
cache_dir="${ROOT_DIR}/build/cache"

mkdir -p "${bundle_dir}" "${dist_dir}" "${cache_dir}"

STREAMLINK_PYTHON_ARCH=${STREAMLINK_PYTHON_ARCH:-win32}
STREAMLINK_PYTHON_VERSION=${STREAMLINK_PYTHON_VERSION:-3.9.7}
STREAMLINK_CHECKOUT_DIR="${ROOT_DIR}/streamlink"
STREAMLINK_WINDOWS_INSTALLER_CHECKOUT_DIR="${ROOT_DIR}/windows-installer"
STREAMLINK_ASSETS_FILE="${STREAMLINK_WINDOWS_INSTALLER_CHECKOUT_DIR}/config.json"
PYTHON_PLATFORM=${STREAMLINK_PYTHON_ARCH}

if [[ "${STREAMLINK_PYTHON_ARCH}" == "amd64" ]]; then
    PYTHON_PLATFORM="win_amd64"
fi

python_url="https://www.python.org/ftp/python/${STREAMLINK_PYTHON_VERSION}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

log "Downloading Python ${STREAMLINK_PYTHON_VERSION} ${STREAMLINK_PYTHON_ARCH}..."
wget -q "${python_url}" -c -O "${temp_dir}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

pushd "${STREAMLINK_CHECKOUT_DIR}" > /dev/null

log "Downloading Python dependencies..."
pip download --only-binary ":all:" --platform "${PYTHON_PLATFORM}" --python-version "${STREAMLINK_PYTHON_VERSION}" --implementation "cp" -d "${temp_dir}" "pycryptodome>=3.4.3,<4.0" "lxml>=4.6.4,<5.0" > /dev/null
pip install "versioningit" > /dev/null
pip install --upgrade -t "${packages_dir}" "pycountry" "setuptools" "requests>=2.26.0,<3.0" "websocket-client>=0.58.0" "PySocks!=1.5.7,>=1.5.6" "isodate" > /dev/null

# create an sdist package to be "installed"
log "Building streamlink sdist"
env NO_DEPS=1 python3 "setup.py" sdist -d "${temp_dir}" > /dev/null

# Work out the streamlink version
STREAMLINK_VERSION=$(python3 setup.py --version)

popd > /dev/null

log "Unpacking python"
unzip -o "${temp_dir}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip" -d "${python_dir}" > /dev/null
# include the Windows 10 Universal Runtime
log "Unpacking Windows 10 Universal Runtime"
unzip -o "${ROOT_DIR}/resources/msvcrt_${PYTHON_PLATFORM}.zip" -d "${python_dir}" > /dev/null

log "Unpacking wheels"
unzip -o "${temp_dir}/*.whl" -d "${packages_dir}" > /dev/null

tar xf "${temp_dir}/streamlink-${STREAMLINK_VERSION}.tar.gz" --strip-components 2 -C "${bundle_dir}/packages/" "streamlink-${STREAMLINK_VERSION}/src/streamlink" "streamlink-${STREAMLINK_VERSION}/src/streamlink_cli"
cp "${ROOT_DIR}/resources/streamlink-script.py" "${bundle_dir}/streamlink-script.py"
cp "${ROOT_DIR}/resources/streamlink.bat" "${bundle_dir}/streamlink.bat"
cp "${ROOT_DIR}/NOTICE" "${bundle_dir}/NOTICE.txt"

cp -r "${STREAMLINK_WINDOWS_INSTALLER_CHECKOUT_DIR}/files/config" "${bundle_dir}/config.template"

ASSETS_DATA=$(cat "${STREAMLINK_ASSETS_FILE}")

assets_prepare() {
    log "Preparing assets"
    if [[ "${STREAMLINK_PYTHON_ARCH}" == "amd64" ]]; then
        while read -r filename sha256 url; do
            if ! [[ -f "${cache_dir}/${filename}" ]]; then
                log "Downloading asset: ${filename}"
                curl -L -o "${cache_dir}/${filename}" "${url}"
            fi
            echo "${sha256} ${cache_dir}/${filename}" | sha256sum --check -
        done < <(jq -r '.assets."ffmpeg-x86_64" | "\(.filename) \(.sha256) \(.url)"' <<< "${ASSETS_DATA}")
    else
        while read -r filename sha256 url; do
            if ! [[ -f "${cache_dir}/${filename}" ]]; then
                log "Downloading asset: ${filename}"
                curl -L -o "${cache_dir}/${filename}" "${url}"
            fi
            echo "${sha256} ${cache_dir}/${filename}" | sha256sum --check -
        done < <(jq -r '.assets."ffmpeg-x86" | "\(.filename) \(.sha256) \(.url)"' <<< "${ASSETS_DATA}")
    fi
}

assets_assemble() {
    log "Assembling files directory"
    local tmp=$(mktemp -d) && trap "rm -rf '${tmp}'" RETURN || exit 255
    read -r type filename sourcedir targetdir \
        < <(jq -r ".assets.\"$1\" | \"\(.type) \(.filename) \(.sourcedir) \(.targetdir)\"" <<< "${ASSETS_DATA}")
    case "${type}" in
        zip)
            mkdir -p "${tmp}/${i}"
            unzip "${cache_dir}/${filename}" -d "${tmp}/${i}"
            sourcedir="${tmp}/${i}/${sourcedir}"
            ;;
        *)
            sourcedir="${cache_dir}"
            ;;
    esac
    while read -r from to; do
        install -v -D -T "${sourcedir}/${from}" "${bundle_dir}/${targetdir}/${to}"
    done < <(jq -r ".assets.\"$1\".files[] | \"\(.from) \(.to)\"" <<< "${ASSETS_DATA}")
}

assets_prepare
if [[ "${STREAMLINK_PYTHON_ARCH}" == "amd64" ]]; then
    assets_assemble "ffmpeg-x86_64"
else
    assets_assemble "ffmpeg-x86"
fi

# remove the rtmpdump and ffmpeg template lines
sed -i "/^rtmpdump=.*/d" "${bundle_dir}/config.template"
sed -i "/^ffmpeg-ffmpeg=.*/d" "${bundle_dir}/config.template"

pushd "${temp_dir}" > /dev/null
mkdir -p "${dist_dir}"
zip -r "${dist_dir}/streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip" "streamlink"  > /dev/null
popd > /dev/null


log "Complete: streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip"
