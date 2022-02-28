# Package

version       = "0.1.0"
author        = "Will Taylor"
description   = "Manage ICAT component installs and configuration"
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["icatcomponents"]


# Dependencies

requires "nim >= 1.4.8"
requires "zip"
requires "argparse"
