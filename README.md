# Streamlink Portable
A script to build a portable version of Streamlink for Windows.

The portable zip files are build from the master branch of [streamlink/streamlink](https://github.com/streamlink/streamlink) and come bundled with Python 3.5.2. There is a 32 bit and a 64 bit version available for 32 bit Windows and 64 bit Windows (if in doubt use the 32 bit version).

The latest versions of the portable zips can be downloaded here:
- [streamlink-portable-latest-win32.zip](https://dl.bintray.com/beardypig/streamlink-portable/streamlink-portable-latest-win32.zip)
- [streamlink-portable-latest-amd64.zip](https://dl.bintray.com/beardypig/streamlink-portable/streamlink-portable-latest-amd64.zip)

A stable version is also available, based on the `0.5.0` tag of streamlink:
- [streamlink-portable-0.5.0-py3.5.2-win32.zip](https://github.com/beardypig/streamlink-portable/releases/download/0.5.0/streamlink-portable-0.5.0-py3.5.2-win32.zip)
- [streamlink-portable-0.5.0-py3.5.2-amd64.zip](https://github.com/beardypig/streamlink-portable/releases/download/0.5.0/streamlink-portable-0.5.0-py3.5.2-amd64.zip)

To install simply unzip the zip file.

A `streamlink.bat` is included in the zip file so that you can easily execute `streamlink`. 

The `streamlinkrc` file is read from the same directory as the `streamlink.bat` and is created when you first execute `streamlink.bat`, however it will not overwrite any existing config file so it an be editted and the changes not lost when updating.  

## Building the zip files under Linux/macOS

NB. `sed` must be `gnu-sed`

- Clone this repo and execute the `scripts/makeportable.sh` script. 


## Changelog

### 2017-03-29

 * Release stable `0.5.0`, lagged behind the official release.

### 2017-02-12

 * Release stable `0.3.2`

### 2017-02-03

 * Added build trigger script that is running every 5 minutes to trigger a travis build
 * Added stable build based on tags.
 * Released stable `0.3.1`

### 2017-01-27

 * Fixed bug with ffmpeg/rtmpdump paths being set on the command line
 * The batch script doesn't change directory any more
 * Added iso3166 and iso-639 packages 

### 2017-01-11

 * Updated to include ffmpeg
