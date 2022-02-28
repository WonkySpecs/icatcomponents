import std / [os]
import types

const domainRoot = "/opt/payara5/glassfish/domains/domain1"
const appsRoot = joinPath(domainRoot, "applications")

proc getDeployedComponents*(): seq[Component] =
  for kind, path in walkDir(appsRoot):
    case kind:
    of pcDir:
      let (_, d, _) = path.splitFile()
      if isComponentString(d): result.add initComponent(d)
    else: discard