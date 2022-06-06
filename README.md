# Streamlink Portable
A script to build a portable version of Streamlink for Windows.

The portable zip files are build from the master branch of [streamlink/streamlink](https://github.com/streamlink/streamlink) and comes bundled with Python 3. There is a 32 bit and a 64 bit version available for 32 bit Windows and 64 bit Windows (if in doubt use the 32 bit version). Multiple bundles with different versions of Python 3 are available, the latest version of Python bundled is currently 3.9. Older versions of Python 3 are provided to maintain compatibility with older versions of Windows. Going forward the bundled versions of Python will be all versions supported by Streamlink. 

The portable zip of the most recent stable streamlink version can be found in the [latest release](https://github.com/beardypig/streamlink-portable/releases/latest). 

The latest [Nightly build](https://github.com/beardypig/streamlink-portable/releases/tag/latest) is available too.

To install simply unzip the zip file.

A `streamlink.bat` is included in the zip file so that you can easily execute `streamlink`.

The `config` file is read from the same directory as the `streamlink.bat` and is created when you first execute `streamlink.bat`, however it will not overwrite any existing config file so it can be edited, and the changes not lost when updating.

## Building the zip files under Linux/macOS

NB. `sed` must be `gnu-sed`

- `jq` is required for the build. 
- Clone this repo and execute the `scripts/makeportable.sh` script.

## Building the zip files under Windows

1. Install [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10). These instructions were done using WSL2 Ubuntu 20.04 LTS with `wsl --install -d Ubuntu-20.04`. A fresh install is assumed, and commands are executed as sudo to avoid additional configuration.

2. Update and fetch pre-requisite dependencies:
```
sudo apt update --yes \
    && sudo apt upgrade --yes \
    && sudo apt install --yes python3-pip zip unzip jq python3-testresources
```

3. Setup a working dir on a Windows mount. The example provided assumes a D: drive:
```
mkdir -p /mnt/d/scratch \
    && cd /mnt/d/scratch
```

4. Clone this repo, [streamlink/streamlink](https://github.com/streamlink/streamlink), and the [streamlink/windows-installer](https://github.com/streamlink/windows-installer) into a subdir called `streamlink` (assigned by default from repo name):
```
sudo git clone https://github.com/beardypig/streamlink-portable \
    && cd streamlink-portable \
    && sudo git clone https://github.com/streamlink/streamlink \
    && sudo git clone https://github.com/streamlink/windows-installer
```

5. Execute script directly as bash:
```
sudo bash ./scripts/makeportable.sh
```

6. Find result inside `dist` subfolder.

7. Delete the working dir if it's no longer needed:
```
rm -rf /mnt/d/scratch
```

## Changelog

### 2022-06-05

* Update Windows build instructions
* Remove outdated Python versions from workflows (streamlink 4.0+ only supports Python 3.9+)
* Move from internal win32 config file to new [streamlink/windows-installer](https://github.com/streamlink/windows-installer) repo

### 2021-10-26

* Updated the asset management method to be inline with streamlink.
* Fix streamlinkrc -> config rename.
* Call `python3` command directly.
* Add Windows build instructions.
* Update to Python 3.9.7.
* Including extra dependencies. 

### 2021-01-03

* Update to Python 3.7.9.
* Update dependencies to match latest version of Streamlink.

### 2021-01-02 

* Remove deprecated `--no-version-check` from the launcher script.

### 2020-04-21

* Updated `makeportable.sh` script to download the ffmpeg/rtmpdump assets from the new streamlink-asset repo.

### 2020-02-18

* Release stable version `1.3.1`.

### 2019-11-22

* Release stable version `1.3.0`.

### 2019-04-15

* Release stable version `1.1.1` - a bit late.

### 2018-08-01

* Re-release stable `0.14.2` as `0.14.2+1`, with fixed `--version`.

### 2018-07-12

* Release stable `0.14.2`.

### 2018-06-06

* Release stable `0.13.0`.
* Update Python to 3.6.5.

### 2018-06-04

* Add `isodate` module.

### 2018-05-09

* Release stable `0.12.1`.

### 2018-03-01

* Release stable `0.10.0`.

### 2017-09-14

* Release stable `0.8.1`.
* Resolved issue with missing `websocket` and `PySocks` modules.
* Update to Python 3.5.4.

### 2017-07-05

 * Release stable `0.7.0`.
 * Resolved issue with missing `urllib3` module.

### 2017-05-11

 * Release stable `0.6.0`.
 * Moved the nightly builds to Bintray.

### 2017-03-29

 * Release stable `0.5.0`, lagged behind the official release.

### 2017-02-12

 * Release stable `0.3.2`.

### 2017-02-03

 * Added build trigger script that is running every 5 minutes to trigger a travis build.
 * Added stable build based on tags.
 * Released stable `0.3.1`.

### 2017-01-27

 * Fixed bug with ffmpeg/rtmpdump paths being set on the command line.
 * The batch script doesn't change directory any more
 * Added iso3166 and iso-639 packages

### 2017-01-11

 * Updated to include ffmpeg.
