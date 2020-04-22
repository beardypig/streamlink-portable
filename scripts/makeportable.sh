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
STREAMLINK_PYTHON_VERSION=${STREAMLINK_PYTHON_VERSION:-3.6.5}
STREAMLINK_CHECKOUT_DIR="${ROOT_DIR}/streamlink"
STREAMLINK_ASSETS_REPO="${STREAMLINK_ASSETS_REPO:-streamlink/streamlink-assets}"
STREAMLINK_ASSETS_RELEASE="${STREAMLINK_ASSETS_RELEASE:-latest}"
PYTHON_PLATFORM=${STREAMLINK_PYTHON_ARCH}

if [[ "${STREAMLINK_PYTHON_ARCH}" == "amd64" ]]; then
    PYTHON_PLATFORM="win_amd64"
fi

python_url="https://www.python.org/ftp/python/${STREAMLINK_PYTHON_VERSION}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

log "Downloading Python ${STREAMLINK_PYTHON_VERSION} ${STREAMLINK_PYTHON_ARCH}..."
wget -q "${python_url}" -c -O "${temp_dir}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

pushd "${STREAMLINK_CHECKOUT_DIR}" > /dev/null

log "Downloading Python dependencies..."
pip download --only-binary ":all:" --platform "${PYTHON_PLATFORM}" --python-version "36" --abi "cp36m" -d "${temp_dir}" "pycryptodome==3.4.3" > /dev/null
pip install --upgrade -t "${packages_dir}" "iso-639" "iso3166" "setuptools" "requests>=1.0,>=2.18.0,<3.0" "websocket-client" "PySocks!=1.5.7,>=1.5.6" "isodate" > /dev/null

# create an sdist package to be "installed"
log "Building streamlink sdist"
env NO_DEPS=1 python "setup.py" sdist -d "${temp_dir}" > /dev/null

# Work out the streamlink version
STREAMLINK_VERSION=$(python setup.py --version)

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

cp -r "${STREAMLINK_CHECKOUT_DIR}/win32/streamlinkrc" "${bundle_dir}/streamlinkrc.template"
cp -r "${STREAMLINK_CHECKOUT_DIR}/win32/THIRD-PARTY.txt" "${bundle_dir}/THIRD-PARTY.txt"

# download binary assets like ffmpeg and rtmpdump from the streamlink assets repo
# parse the data.json manifest, validate archives and copy specific files to their destination
log "Fetching assets data from \"${STREAMLINK_ASSETS_REPO}\" (${STREAMLINK_ASSETS_RELEASE})"
assets_release_data=$(curl -s --fail \
    -H 'Accept: application/vnd.github.v3+json' \
    -H "User-Agent: ${GITHUB_REPOSITORY:-"streamlink/streamlink"}" \
    "https://api.github.com/repos/${STREAMLINK_ASSETS_REPO}/releases/${STREAMLINK_ASSETS_RELEASE}" \
    || err "Could not fetch release data"
)
assets_release_tag=$(echo "${assets_release_data}" | jq -r ".tag_name")
assets_data=$(curl -s --fail \
    -H "User-Agent: ${GITHUB_REPOSITORY:-"streamlink/streamlink"}" \
    "https://raw.githubusercontent.com/${STREAMLINK_ASSETS_REPO}/${assets_release_tag}/data.json" \
    || err "Could not fetch manifest data"
)

log "Retrieving assets"
while read -r filename size url; do
    if ! [[ -f "${cache_dir}/${filename}" ]]; then
        log "Downloading asset: ${filename} (${size} Bytes)"
        curl -s -L --output "${cache_dir}/${filename}" "${url}"
    fi
    checksum=$(jq -r "[.[] | select(.filename == \"${filename}\")] | first | .checksum" <<< "${assets_data}")
    echo "${checksum} ${cache_dir}/${filename}" | sha256sum --check -
done < <(jq -r '.assets[] | "\(.name) \(.size) \(.browser_download_url)"' <<< "${assets_release_data}")

log "Assembling files directory"
TEMP=$(mktemp -d) && trap "rm -rf ${TEMP}" EXIT || exit 255
for ((i=$(jq length <<< "${assets_data}") - 1; i >= 0; --i)); do
    read -r filename sourcedir targetdir \
        < <(jq -r ".[$i] | \"\(.filename) \(.sourcedir) \(.targetdir)\"" <<< "${assets_data}")
    sourcedir="${TEMP}/${sourcedir}"
    case "${filename}" in
        *.zip)
            unzip "${cache_dir}/${filename}" -d "${TEMP}"
            ;;
        *)
            sourcedir="${cache_dir}"
            ;;
    esac
    while read -r from to; do
        install -v -D -T "${sourcedir}/${from}" "${bundle_dir}/${targetdir}/${to}"
    done < <(jq -r ".[$i].files[] | \"\(.from) \(.to)\"" <<< "${assets_data}")
done

# remove the rtmpdump and ffmpeg template lines
sed -i "/^rtmpdump=.*/d" "${bundle_dir}/streamlinkrc.template"
sed -i "/^ffmpeg-ffmpeg=.*/d" "${bundle_dir}/streamlinkrc.template"

pushd "${temp_dir}" > /dev/null
mkdir -p "${dist_dir}"
zip -r "${dist_dir}/streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip" "streamlink"  > /dev/null
popd > /dev/null


log "Complete: streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip"
