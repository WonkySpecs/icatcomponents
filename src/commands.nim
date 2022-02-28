import std / [os, osproc, options, strformat, sequtils, sugar, times, streams]
import zip / zipfiles
import repo, files, types, glassfish

proc isValidComponent(componentName: string): bool = componentName in getComponentList()
proc isAvailable(component: Component): bool =
  result = getComponentList().contains(component.name) and
    getAvailableVersions(component.name).contains(component.version)
proc resolveComponent(componentName: string, versionArg: Option[string]): Option[Component] =
  if not isValidComponent(componentName):
    return none[Component]()
  # Latest available version if none specified
  let
    resolvedVersion = versionArg.map(initVersion)
      .get(getLatestAvailableVersion(componentName))
    c = Component(name: componentName, version: resolvedVersion)
  if not isAvailable(c):
    return none[Component]()

  return some(c)

proc listCommand*(installedOnly: bool, componentName: Option[string]) =
  if componentName.isSome:
    if not isValidComponent(componentName.get):
      echo &"{componentName.get} is not a component, use 'list' to see available components"
      return

    let installedVersions = getInstalledVersions(componentName.get)
    echo "Installed versions:"
    echo installedVersions
    if not installedOnly:
      let
        allVersions = getAvailableVersions(componentName.get)
        notInstalled = allVersions.filter(v => not installedVersions.contains(v))
      echo "Available versions:"
      echo notInstalled
  else:
    let installed = getInstalledComponents()
    echo "Installed components:"
    echo installed
    if not installedOnly:
      let
        all = getComponentList()
        notInstalled = all.filter(c => not installed.contains(c))
      echo "Available components:"
      echo notInstalled

proc downloadDistro(component: Component): string =
  let path = joinPath(distros, &"{$component}.zip")
  if not path.fileExists():
    let dl = getDistro(component)
    writeFile(path, dl)
  path

proc install(component: Component) =
  let zipPath = downloadDistro(component)
  var z: ZipArchive
  if not z.open(zipPath):
    echo "Something went wrong opening distro"
    return

  let
    installDir = joinPath(installs, component.name)
    mostRecent = getMostRecentInstalledVersion(component.name)
    unzippedPath = joinPath(installDir, component.name)
    finalPath = joinPath(installDir, $(component.version))

  z.extractAll(installDir)
  try:
    moveDir(unzippedPath, finalPath)
  except:
    echo "Failed to move, deleting"
    removeDir(unzippedPath)
    return

  if not mostRecent.isSome:
    echo "No previous version to copy configs from, make sure to create them"
    return

  let
    v = mostRecent.get
    vCfgs = getConfigFiles(component.name, v)
  if vCfgs.len == 0:
    echo &"Most recent version {v} had no configuration to copy, make sure to create them"
  else:
    echo &"Copying configuration from most recent version, {v}"
    for cf in vCfgs:
      copyfile(cf, joinPath(finalPath, cf.extractFilename))

proc installCommand*(componentName: string, versionArg: Option[string]) =
  let target = resolveComponent(componentName, versionArg)
  if target.isNone:
    echo "Component is not available, use 'list' to see all available components"
    return
  let component = target.get

  install(component)

proc update(componentName: string, version: Option[string]) =
  let
    target = resolveComponent(componentName, version)
    curVersion = getMostRecentInstalledVersion(componentName)
    latest = getLatestAvailableVersion(componentName)

  if target.isNone:
    echo "Component is not available, use 'list' to see all available components"
    return
  let component = target.get

  if curVersion.isNone:
    echo &"{componentName} is not currently installed. Use the 'install' command instead"
    return
  if curVersion.get < component.version:
    echo &"A newer version, {curVersion.get}, is already installed"
    return
  if curVersion.get == latest:
    echo &"The latest version, {latest}, is already installed"
    return
  install(component)

proc updateCommand*(componentName, version: Option[string]) =
  if componentName.isSome:
      update(componentName.get, version)
  else:
    for c in getInstalledComponents():
      echo &"Updating {c}"
      update(c, none[string]())

proc deployCommand*(componentName: string, version: Option[string], installIfMissing: bool) =
  let target = resolveComponent(componentName, version)
  if target.isNone:
    echo "Component is not available, use 'list' to see all available components"
    return
  let component = target.get

  if not component.isInstalled:
    if installIfMissing:
      install(component)
    else:
      echo &"Must install {$component} before it can be deployed."
      return

  let
    process = startProcess(
      "/usr/bin/python3",
      args = ["setup", "install"],
      workingDir=installDirectory(component))
    o = process.outputStream
    e = process.errorStream
    start = getTime()
  while (getTime() - start).inSeconds < 10 and process.running:
    let
      errs = e.readAll
      output = o.readAll
    if errs.len > 0:
      echo errs
    if output.len > 0:
      echo output
  echo &"Setup script exited with {process.peekExitCode}"
  process.close()