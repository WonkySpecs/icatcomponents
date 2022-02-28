import std / [strformat, os]
import argparse
import commands, files

var argParser = newParser:
  command("list"):
    help("List available/installed components")
    flag("-i", "--installed", help="Only display information for installed components")
    option("--component", help="List the versions for a specific component")
    run:
      listCommand(opts.installed, opts.componentOpt)
  command("install"):
    help("Install a component")
    arg("component")
    option("-v", "--version", help="A specific version to install. If not "&
      "specified, the latest available version will be used")
    run:
      installCommand(opts.component, opts.versionOpt)
  command("update"):
    help("Install newer version(s) of component(s)")
    option("--component", help="The component to update. If not specified," &
      " searches for updates for all installed components")
    option("-v", "--version", help="A specific version to update. If not "&
      "specified, the latest available version will be used")
    run:
      updateCommand(opts.componentOpt, opts.versionOpt)
  command("deploy"):
    arg("component")
    option("-v", "--version", help="A specific version to update. If not "&
      "specified, the latest available version will be used")
    flag("-i", "--install-if-missing",
      help="Install the component before deploying if it is not installed")
    run:
      deployCommand(opts.component, opts.versionOpt, opts.installIfMissing)

when isMainModule:
  for d in ["distros", "installs"]:
    let subD = joinPath(componentsRoot, d)
    if not subD.dirExists:
      echo &"Creating {subD}"
      createDir(subD)

  try:
    argParser.run()
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)
