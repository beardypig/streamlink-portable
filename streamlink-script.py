#!python
import shutil
import sys
import os.path

pkgdir = os.path.abspath(os.path.join(os.path.dirname(__file__), 'packages'))
sys.path.insert(0, pkgdir)
os.environ['PYTHONPATH'] = os.pathsep.join([pkgdir, os.environ.get('PYTHONPATH', '')])

if __name__ == '__main__':
    from streamlink_cli.main import main

    # install the streamlinkrc file, if one is not installed
    if not os.path.exists("streamlinkrc"):
        shutil.copyfile("streamlinkrc.default", "streamlinkrc")
    main()
