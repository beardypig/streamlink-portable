#!/usr/bin/env bash
# This script takes one argument, the windows arch for which to build it (win32 or amd64) and it defaults to win32
set -e # quit on error

STREAMLINK_PYTHON_ARCH=${1:-win32}
STREAMLINK_PYTHON_VERSION=${STREAMLINK_PYTHON_VERSION:-3.5.2}
STREAMLINK_VERSION=$(python -c 'import streamlink; print(streamlink.__version__)')
PYTHON_PLATFORM=${STREAMLINK_PYTHON_ARCH}

if [[ $STREAMLINK_PYTHON_ARCH == "amd64" ]]; then
    PYTHON_PLATFORM="win_amd64"
fi

# For travis nightly builds generate a version number with commit hash
if [ -n "${TRAVIS_BRANCH}" ] && [ -z "${TRAVIS_TAG}" ]; then
    STREAMLINK_VERSION="${STREAMLINK_VERSION}-${TRAVIS_BUILD_NUMBER}-${TRAVIS_COMMIT:0:7}"
fi

python_url="https://www.python.org/ftp/python/${STREAMLINK_PYTHON_VERSION}/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

root_dir="$(pwd)"
temp_dir="${root_dir}/build/temp"
bundle_dir="${temp_dir}/streamlink"
python_dir="${bundle_dir}/python"
streamlink_clone_dir="${temp_dir}/streamlink-clone"
dist_dir="${root_dir}/dist"

mkdir -p "${bundle_dir}"
mkdir -p "${dist_dir}"

wget "${python_url}" -O "build/temp/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip"

pip download --only-binary ":all:" --platform "${PYTHON_PLATFORM}" --python-version "35" -d "${temp_dir}" "pycryptodome" "requests"

# remove any old streamlink clone
rm -rf "${streamlink_clone_dir}"
git clone https://github.com/streamlink/streamlink.git ${streamlink_clone_dir}

pushd "${streamlink_clone_dir}"
# apply patches to streamlink
git apply "${root_dir}/rtmpdump_relative_path.patch"
popd

env NO_DEPS=1 pip wheel streamlink -w "${temp_dir}"

unzip -o "build/temp/python-${STREAMLINK_PYTHON_VERSION}-embed-${STREAMLINK_PYTHON_ARCH}.zip" -d "${python_dir}"
unzip -o "build/temp/streamlink*.whl" -d "${python_dir}"
unzip -o "build/temp/pycryptodome*.whl" -d "${python_dir}"
unzip -o "build/temp/requests*.whl" -d "${python_dir}"

cat > "${bundle_dir}/streamlink-script.py" << EOF
import os.path
import shutil
from streamlink_cli.main import main
# install the streamlinkrc file, if one is not installed
if not os.path.exists("streamlinkrc"):
  shutil.copyfile("streamlinkrc.tmp", "streamlinkrc")
main()
EOF

cat > "${bundle_dir}/streamlink.bat" << EOF
@echo off
pushd %~dp0
"python\python.exe" "streamlink-script.py" %* --config "streamlinkrc"
EOF

mkdir -p "${bundle_dir}/rtmpdump"
cp -r "${streamlink_clone_dir}/win32/rtmpdump/"* "${bundle_dir}/rtmpdump"
cp -r "${streamlink_clone_dir}/win32/streamlinkrc" "${bundle_dir}/streamlinkrc.default"

gsed -i "s/^#rtmpdump.*/rtmpdump=rtmpdump\\\\rtmpdump.exe/g" "${bundle_dir}/streamlinkrc.default"

pushd "${temp_dir}"
zip -r "${dist_dir}/streamlink-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip" "streamlink"
cp "${dist_dir}/streamlink-${STREAMLINK_VERSION}-py${STREAMLINK_PYTHON_VERSION}-${STREAMLINK_PYTHON_ARCH}.zip" "${dist_dir}/streamlink-latest.zip"
popd
