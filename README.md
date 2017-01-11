# Streamlink Portable
A script to build a portable version of Streamlink for Windows.

The portable zip files are build from the master branch of [streamlink/streamlink](https://github.com/streamlink/streamlink) and come bundled with Python 3.5.2. There is a 32 bit and a 64 bit version available for 32 bit Windows and 64 bit Windows (if in doubt use the 32 bit version).

The latest versions of the portable zips can be downloaded here:
- [streamlink-portable-latest-win32.zip](https://s3.amazonaws.com/streamlink-portable/nightly/streamlink-portable-latest-win32.zip)
- [streamlink-portable-latest-amd64.zip](https://s3.amazonaws.com/streamlink-portable/nightly/streamlink-portable-latest-amd64.zip)

To install simply unzip the zip file.

A `streamlink.bat` is included in the zip file so that you can easily execute `streamlink`. 

The `streamlinkrc` file is read from the same directory as the `streamlink.bat` and is created when you first execute `streamlink.bat`, however it will not overwrite any existing config file so it an be editted and the changes not lost when updating.  

## Building the zip files under Linux/macOS

- Clone this repo and execute the `makeportable.sh` script. 


## Changelog

### 2017-01-11

 * Updated to include ffmpeg
