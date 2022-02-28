## Module to handle interactions with the repository of ICAT releases.

import std / [httpclient, httpcore, htmlparser, xmltree,
              strformat, options, algorithm, strutils, tables]
import types

const repoRoot = "https://repo.icatproject.org/repo/org/icatproject"
var client = newHttpClient()

var componentList: seq[string]
var componentVersions: Table[string, seq[Version]]

proc getComponentList*(): seq[string] =
  ## Get all the components available in the repo. Caches the result.
  if componentList.len == 0:
    let
      repoListPage = client.getContent(repoRoot)
      html = parseHtml(repoListPage)
      table = html.findAll("table")[0]
      rows = table.findAll("tr")
      # Skip top three rows and bottom row, which aren't links to repos
      repoRows = rows[3..^2]
    for row in repoRows:
      let links = row.findAll("a")
      if links.len == 0: continue
      componentList.add links[0].innerText.strip(chars={'/'})
  componentList

proc getDistro*(component: Component): string =
  client.getContent(&"{repoRoot}/{component.name}/{$(component.version)}" &
    &"/{$component}-distro.zip")

proc getAvailableVersions*(repo: string): seq[Version] =
  if not componentVersions.hasKey(repo):
    var versions = newSeq[Version]()
    let
      repoUrl = &"{repoRoot}/{repo}/"
      repoPage = client.getContent(repoUrl)
      html = parseHtml(repoPage)
      table = html.findAll("table")[0]
      rows = table.findAll("tr")
      # Skip top three rows, which aren't links to repos
      repoRows = rows[3..^1]
    for row in repoRows:
      let links = row.findAll("a")
      if links.len == 0: continue
      let linkText = links[0].innerText.strip(chars={'/'})
      if linkText.isVersionString: versions.add(initVersion(linkText))
    componentVersions[repo] = versions
  componentVersions[repo]

proc getLatestAvailableVersion*(repo: string): Version =
  let versions = getAvailableVersions(repo)
  versions.sorted(cmpVersions, Descending)[0]
