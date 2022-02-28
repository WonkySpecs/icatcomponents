import std / [strutils, strformat, re]

type
  Version* = object
    major, minor, patch: uint

  Component* = object
    name*: string
    version*: Version

const versionPattern = r"\d+\.\d+.\d+"
func isVersionString*(s: string): bool = s.match(re(&"^{versionPattern}$"))
func initVersion*(versionString: string): Version =
  let parts = versionString.split(".")
  Version(
    major: parseUInt(parts[0]),
    minor: parseUInt(parts[1]),
    patch: parseUInt(parts[2]))

func `$`*(v: Version): string = &"{v.major}.{v.minor}.{v.patch}"

func cmpVersions*(v1, v2: Version): int =
  let
    majorCmp = cmp(v1.major, v2.major)
    minorCmp = cmp(v1.minor, v2.minor)
    patchCmp = cmp(v1.patch, v2.patch)

  if majorCmp != 0:
    result = majorCmp
  elif minorCmp != 0:
    result = minorCmp
  elif patchCmp != 0:
    result = patchCmp
  else:
    result = 0

func `>`*(v1, v2: Version): bool = cmpVersions(v1, v2) > 0
func `<`*(v1, v2: Version): bool = cmpVersions(v1, v2) < 0
func `==`*(v1, v2: Version): bool = cmpVersions(v1, v2) == 0

func isComponentString*(s: string): bool = s.match(re(&"^[^-]+-{versionPattern}$"))
func initComponent*(componentString: string): Component =
  let parts = componentString.split('-')
  Component(name: parts[0], version: initVersion(parts[0]))
func `$`*(component: Component): string = &"{component.name}-{$component.version}"