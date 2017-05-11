#!/usr/bin/env bash
#
# Script to generate bintray config for portable builds
#
STREAMLINK_PYTHON_VERSION=3.5.3

root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
build_dir="${root_dir}/build/"
mkdir -p ${build_dir}

echo "Building nightly/dev version..."
cat > "${build_dir}/bintray-nightly.json" <<EOF
{
"package": {
"subject": "beardypig",
"repo": "streamlink-portable",
"name": "streamlink-portable"
},

"version": {
"name": "latest",
"released": "$(date +'%Y-%m-%d')"
},

"files": [
{
  "includePattern": "${dist_dir}/(streamlink-portable-latest-.*\\.zip)",
  "uploadPattern": "\$1",
  "matrixParams": {
    "override": 1,
    "publish": 1
  }
}
],

"publish": true
}
EOF

echo "Wrote Bintray config to: ${build_dir}/bintray-nightly.json"
