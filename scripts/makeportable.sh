#!/usr/bin/env bash
# usage: ./makeportable.sh

set -e # quit on error

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ROOT_DIR="${ROOT_DIR:-$script_dir}"
temp_dir="${ROOT_DIR}/build/temp"
bundle_dir="${temp_dir}/streamlink"
python_dir="${bundle_dir}/python"
packages_dir="${bundle_dir}/packages"
dist_dir="${ROOT_DIR}/dist"

mkdir -p "${bundle_dir}" "${dist_dir}"

STREAMLINK_PYTHON_ARCH=${STREAMLINK_PYTHON_ARCH:-win32}
STREAMLINK_PYTHON_VERSION=${STREAMLINK_PYTHON_VERSION:-3.6.5}
STREAMLINK_CHECKOUT_DIR="${ROOT_DIR}/streamlink"
PYTHON_PLATFORM=${STREAMLINK_PYTHON_ARCH}

if [[ "${STREAMLINK_PYTHON_ARCH}" == "amd64" ]]; then
    PYTHON_PLATFORM="win_amd64"
fi

python_url="https://www.python.org/ftp/python/${STREAMLINK_PYTHON_VERSION}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

echo "Downloading Python ${STREAMLINK_PYTHON_VERSION} ${STREAMLINK_PYTHON_ARCH}..."
wget -q "${python_url}" -c -O "build/temp/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

pushd "${STREAMLINK_CHECKOUT_DIR}" > /dev/null

echo "Downloading Python dependencies..."
pip download --only-binary ":all:" --platform "${PYTHON_PLATFORM}" --python-version "36" --abi "cp36m" -d "${temp_dir}" "pycryptodome==3.4.3" > /dev/null
pip install --upgrade -t "${packages_dir}" "iso-639" "iso3166" "setuptools" "requests>=1.0,>=2.18.0,<3.0" "websocket-client" "PySocks!=1.5.7,>=1.5.6" "isodate" > /dev/null

# create an sdist package to be "installed"
echo "Building streamlink sdist"
env NO_DEPS=1 python "setup.py" sdist -d "${temp_dir}" > /dev/null

# Work out the streamlink version
STREAMLINK_VERSION=$(python setup.py --version)

popd > /dev/null

echo "Building zip file..."
unzip -o "${temp_dir}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip" -d "${python_dir}" > /dev/null
# include the Windows 10 Universal Runtime
unzip -o "${ROOT_DIR}/resources/msvcrt_${PYTHON_PLATFORM}.zip" -d "${python_dir}" > /dev/null

unzip -o "${temp_dir}/*.whl" -d "${packages_dir}" > /dev/null


tar xf "${temp_dir}/streamlink-${STREAMLINK_VERSION}.tar.gz" --strip-components 2 -C "${bundle_dir}/packages/" "streamlink-${STREAMLINK_VERSION}/src/streamlink" "streamlink-${STREAMLINK_VERSION}/src/streamlink_cli"
cp "${ROOT_DIR}/resources/streamlink-script.py" "${bundle_dir}/streamlink-script.py"
cp "${ROOT_DIR}/resources/streamlink.bat" "${bundle_dir}/streamlink.bat"
cp "${ROOT_DIR}/NOTICE" "${bundle_dir}/NOTICE.txt"

mkdir -p "$bundle_dir/rtmpdump" "$bundle_dir/ffmpeg"
cp -r "${STREAMLINK_CHECKOUT_DIR}/win32/rtmpdump/"* "${bundle_dir}/rtmpdump"
cp -r "${STREAMLINK_CHECKOUT_DIR}/win32/ffmpeg/"* "${bundle_dir}/ffmpeg"
cp -r "${STREAMLINK_CHECKOUT_DIR}/win32/streamlinkrc" "${bundle_dir}/streamlinkrc.template"
cp -r "${STREAMLINK_CHECKOUT_DIR}/win32/LICENSE.txt" "${bundle_dir}/LICENSE.txt"

# remove the rtmpdump and ffmpeg template lines
sed -i "/^rtmpdump=.*/d" "${bundle_dir}/streamlinkrc.template"
sed -i "/^ffmpeg-ffmpeg=.*/d" "${bundle_dir}/streamlinkrc.template"

pushd "${temp_dir}" > /dev/null
mkdir -p "${dist_dir}"
zip -r "${dist_dir}/streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip" "streamlink"  > /dev/null
popd > /dev/null


echo "Complete: streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip"
