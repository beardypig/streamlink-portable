import os.path
import shutil
from streamlink_cli.main import main
# install the streamlinkrc file, if one is not installed
if not os.path.exists("streamlinkrc"):
  shutil.copyfile("streamlinkrc.default", "streamlinkrc")
main()
