#!/usr/bin/env bash
# This script takes one argument, the windows arch for which to build it (win32 or amd64) and it defaults to win32
set -e # quit on error

STREAMLINK_PYTHON_ARCH=${1:-win32}
STREAMLINK_PYTHON_VERSION=3.5.2
PYTHON_PLATFORM=${STREAMLINK_PYTHON_ARCH}

if [[ "${STREAMLINK_PYTHON_ARCH}" == "amd64" ]]; then
    PYTHON_PLATFORM="win_amd64"
fi

python_url="https://www.python.org/ftp/python/${STREAMLINK_PYTHON_VERSION}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

root_dir="$(pwd)"
temp_dir="${root_dir}/build/temp"
bundle_dir="${temp_dir}/streamlink"
python_dir="${bundle_dir}/python"
packages_dir="${bundle_dir}/packages"
streamlink_clone_dir="${temp_dir}/streamlink-clone"
dist_dir="${root_dir}/dist"

mkdir -p "${bundle_dir}"
mkdir -p "${dist_dir}"

wget "${python_url}" -c -O "build/temp/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

# remove any old streamlink clone
rm -rf "${streamlink_clone_dir}"
git clone https://github.com/streamlink/streamlink.git ${streamlink_clone_dir}

pushd "${streamlink_clone_dir}"
commit=$(git rev-parse --short HEAD)

pip download --only-binary ":all:" --platform "${PYTHON_PLATFORM}" --python-version "35" --abi "cp35m" -d "${temp_dir}" "pycryptodome==3.4.3" "requests>=1.0,!=2.12.0,!=2.12.1,<3.0"
pip install -t "${packages_dir}" "iso-639" "iso3166" "setuptools"

# Work out the streamlink version
# For travis nightly builds generate a version number with commit hash
STREAMLINK_VERSION=$(python setup.py --version)
sdate=$(date "+%Y%m%d" -d @$(git show -s --format="%ct" ${commit}))
STREAMLINK_VERSION="${STREAMLINK_VERSION}-${sdate}-${commit}"

env NO_DEPS=1 python "setup.py" sdist -d "${temp_dir}"

popd


unzip -o "build/temp/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip" -d "${python_dir}"
# include the Windows 10 Universal Runtime
unzip -o "msvcrt_${PYTHON_PLATFORM}.zip" -d "${python_dir}"

unzip -o "build/temp/pycryptodome*.whl" -d "${packages_dir}"
unzip -o "build/temp/requests*.whl" -d "${packages_dir}"

cp -r "${streamlink_clone_dir}/src/"* "${bundle_dir}/packages"
cp "${root_dir}/streamlink-script.py" "${bundle_dir}/streamlink-script.py"
cp "${root_dir}/streamlink.bat" "${bundle_dir}/streamlink.bat"
cp "${root_dir}/NOTICE" "${bundle_dir}/NOTICE.txt"

mkdir -p "$bundle_dir/rtmpdump" "$bundle_dir/ffmpeg"
cp -r "${streamlink_clone_dir}/win32/rtmpdump/"* "${bundle_dir}/rtmpdump"
cp -r "${streamlink_clone_dir}/win32/ffmpeg/"* "${bundle_dir}/ffmpeg"
cp -r "${streamlink_clone_dir}/win32/streamlinkrc" "${bundle_dir}/streamlinkrc.default"
cp -r "${streamlink_clone_dir}/win32/LICENSE.txt" "${bundle_dir}/LICENSE.txt"

sed -i "s/^rtmpdump=.*/#rtmpdump=/g" "${bundle_dir}/streamlinkrc.default"
sed -i "s/^ffmpeg-ffmpeg=.*/#ffmpeg-ffmpeg=/g" "${bundle_dir}/streamlinkrc.default"

pushd "${temp_dir}"
zip -r "${dist_dir}/streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip" "streamlink"
cp "${dist_dir}/streamlink-portable-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip" "${dist_dir}/streamlink-portable-latest-${STREAMLINK_PYTHON_ARCH}.zip"
popd
