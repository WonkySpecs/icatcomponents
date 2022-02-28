import std / [os, options, algorithm]
import types

const componentsRoot* = if existsEnv("ICAT_COMPONENT_INSTALL_ROOT"):
    getEnv("ICAT_COMPONENT_INSTALL_ROOT")
  else:
    expandTilde("~/icat_components")
const distros* = joinPath(componentsRoot, "distros")
const installs* = joinPath(componentsRoot, "installs")

func installDirectory(component: string, v: Version): string =
  joinPath(installs, component, $v)
func installDirectory*(component: Component): string =
  installDirectory(component.name, component.version)

proc getInstalledComponents*(): seq[string] =
  for kind, path in walkDir(installs):
    case kind:
    of pcDir: result.add path.splitPath[1]
    else: discard

proc getInstalledVersions*(componentName: string): seq[Version] =
  for kind, path in walkDir(joinPath(installs, componentName)):
    case kind:
    of pcDir:
      let d = path.splitPath[1]
      if d.isVersionString: result.add initVersion(d)
    else: discard

proc isInstalled*(component: Component): bool =
  getInstalledVersions(component.name).contains(component.version)

proc getMostRecentInstalledVersion*(component: string): Option[Version] =
  let versions = getInstalledVersions(component)
  if versions.len == 0: none[Version]()
  else: some(versions.sorted(cmpVersions, Descending)[0])

proc getConfigFiles*(component: string, version: Version): seq[string] =
  for kind, path in walkDir(installDirectory(component, version)):
    case kind:
    of pcFile:
      let (_, _, ext) = path.splitFile()
      if ext == ".properties" or ext == ".xml":
        result.add path
    else: discard