## Nim module for improved URI handling.
## Based on the "uri" module in the Nim standard library and the
## "purl" Python module at https://github.com/codeinthehole/purl.

## Written by Adam Chesak.
## Released under the MIT open source license.
## Modified, add some features by Amru Rosyada <amru.rosyada@gmail.com>

## example
##
## let uri = parseUri3("https://user:password@domain.com/profile/1234?id=xyz#/home/?page=10")
##
## echo uri.getQuery("id")
## echo uri.getQueries()
## echo uri.getUsername()
## echo uri.getPassword()
## echo uri.getAnchor()
## echo uri.getAnchorQuery("page")
## echo uri.getAnchorQueries()
## echo uri.getDomain()
## echo uri.getPort()
## echo uri.getScheme()
##

import std/uri
import std/strutils
import std/strformat


type
  Uri3* = ref object of RootObj
    ## This is Uri3 object contains uri parts of uri component
    scheme : string
    ## hold scheme from uri protocol
    username : string
    ## hold username from uri auth
    password : string
    ## hold password from uri auth
    hostname : string
    ## hold hostname from uri
    port : string
    ## hold port from uri
    path : string
    ## hold path from uri, segment part part after valid domain name
    anchor : string
    ## hold anchor from uri
    queries : seq[(string, string)]
    ## contains all queries pair exclude anchor section
    anchorQueries : seq[(string, string)]
    ## contains all queries pair in anchor section only


proc parseUri3*(url : string) : Uri3 =
  ##
  ##  Parse string url into Uri3 Object
  ##
  
  proc collectQueries(q : string) : seq[(string, string)] =
    ## collect all queries from uri exclude anchor part
    let queries : seq[string] = q.split("&")
    for i in 0..high(queries) :
      let tmp = queries[i].split("=")
      if tmp.len == 2 :
        result.add((tmp[0], tmp[1]))

  let u : URI = parseUri(url)
  ## parse uri as std URI

  var anchorUri = u.anchor.strip()
  var anchorUriQueries: seq[(string, string)] = @[]
  if anchorUri != "" :
    ## check if anchor uri part exists or not
    ## then extract segment section with anchor query
    let qString = anchorUri.split("?")
    anchorUri = qString[0]
    if qString.len > 1 :
      anchorUriQueries = collectQueries(qString[1])

  result = Uri3(
      scheme : u.scheme,
      username : u.username,
      password : u.password,
      hostname : u.hostname,
      port : u.port,
      path : u.path,
      anchor : u.anchor,
      queries : collectQueries(u.query),
      anchorQueries : anchorUriQueries
    )
  ## create new Uri3 then set as return result


proc encodeURI*(url : string, usePlus : bool = true) : string =
  ## encode  non uri characters

  result = encodeUrl(url, usePlus)


proc decodeURI*(url : string, decodePlus : bool = true) : string =
  ## encode non uri characters

  result = decodeUrl(url, decodePlus)


proc encodeToQuery*(
    query : openArray[(string, string)],
    usePlus : bool = true,
    omitEq: bool = true
  ) : string =
  ## encode given query pairs into uri query string
  
  result = encodeQuery(query, usePlus, omitEq)


proc appendPathSegment*(self : Uri3, path : string) =
  ## append path into last uri path segment

  var newPath : string = self.path
  var path2 : string = path

  if newPath.endsWith("/") :
    newPath = newPath[0..high(newPath) - 1]

  if path2.startsWith("/") :
    path2 = path2[1..high(path2)]

  newPath = newPath & "/" & path2
  self.path = newPath


proc appendAnchorSegment*(self : Uri3, path : string) =
  ## append path into last anchor uri path segment

  var newPath : string = self.anchor
  var path2 : string = path

  if newPath.endsWith("/") :
    newPath = newPath[0..high(newPath) - 1]

  if path2.startsWith("/") :
    path2 = path2[1..high(path2)]

  newPath = newPath & "/" & path2
  self.anchor = newPath


proc prependPathSegment*(self : Uri3, path : string) =
  ## prepend path before first uri segment
  
  var newPath : string = self.path
  var path2 : string = path

  if newPath.startsWith("/") :
    newPath = newPath[1..high(newPath)]

  if path2.endsWith("/") :
    path2 = path2[0..high(path2) - 1]

  if not path2.startsWith("/") :
    path2 = "/" & path2

  newPath = path2 & "/" & newPath
  self.path = newPath


proc prependAnchorSegment*(self : Uri3, path : string) =
  ## prepend path before first anchor uri segment

  var newPath : string = self.anchor
  var path2 : string = path

  if newPath.startsWith("/") :
    newPath = newPath[1..high(newPath)]

  if path2.endsWith("/") :
    path2 = path2[0..high(path2) - 1]

  if not path2.startsWith("/") :
    path2 = "/" & path2

  newPath = path2 & "/" & newPath
  self.anchor = newPath


proc getDomain*(self : Uri3) : string =
  ## return domain part from uri

  result = self.hostname


proc getScheme*(self : Uri3) : string =
  ## return scheme/protocol part from uri

  result = self.scheme


proc getUsername*(self : Uri3) : string =
  ## return username part from uri

  result = self.username


proc getPassword*(self : Uri3) : string =
  ## return password part from uri

  result = self.password


proc getPort*(self : Uri3) : string =
  ## return port part from uri

  result = self.port


proc getPath*(self : Uri3) : string =
  ## return path from uri (part after valid domain name)

  result = self.path


proc getPathSegments*(self : Uri3) : seq[string] =
  ## return path segment as array

  var paths: seq[string] = self.path.split("/")
  result = paths[1..high(paths)]


proc getAnchorSegments*(self : Uri3) : seq[string] =
  ## return anchor path segment as array

  var paths: seq[string] = self.anchor.split("/")
  result = paths[1..high(paths)]


proc getPathSegment*(self : Uri3, index : int) : string =
  ## return specific path from array uri segment

  return self.getPathSegments()[index]


proc getAnchorSegment*(self : Uri3, index : int) : string =
  ## return specific path from array anchor uri segment

  return self.getAnchorSegments()[index]


proc getAnchor*(self : Uri3) : string =
  ## return anchor from uri

  result = self.anchor


proc getQueries*(self : Uri3) : seq[(string, string)] =
  ## return all query pair from uri exclude anchor

  result = self.queries


proc getAnchorQueries*(self : Uri3) : seq[(string, string)] =
  ## return all anchor query pair as array

  result = self.anchorQueries


proc getQuery*(self: Uri3, query: string, default: string = ""): string =
  ## return specific query string from uri, exclude anchor

  var queryResult: string = default
  for i in self.queries :
    if i[0] == query :
      queryResult = i[1]
      break

  result = queryResult


proc getAnchorQuery*(self : Uri3, query : string, default : string = "") : string =
  ## return specific anchor query string from uri

  var queryResult : string = default
  for i in self.anchorQueries :
    if i[0] == query:
      queryResult = i[1]
      break

  result = queryResult


proc getQuery*(self : Uri3) : string =
  ## return query string as string

  var query : string = ""
  for i in 0..high(self.queries) :
    let k = self.queries[i][0].strip()
    let v = self.queries[i][1].strip()
    query &= k & "=" & v

    if i != high(self.queries):
      query &= "&"

  if query.strip() != "" :
    result = "?" & query


proc getAnchorQuery*(self : Uri3) : string =
  ## return anchor query string as string

  var query: string = ""
  for i in 0..high(self.anchorQueries) :
    let k = self.anchorQueries[i][0].strip()
    let v = self.anchorQueries[i][1].strip()
    query &= k & "=" & v

    if i != high(self.queries) :
      query &= "&"

  if query.strip() != "" :
    result = "?" & query


proc setDomain*(self : Uri3, domain : string) =
  ## set domain on uri

  self.hostname = domain


proc setScheme*(self : Uri3, scheme : string) =
  ## set scheme on uri

  self.scheme = scheme


proc setUsername*(self : Uri3, username : string) =
  ## set username on uri

  self.username = username


proc setPassword*(self : Uri3, password : string) =
  ## set password on uri

  self.password = password


proc setPort*(self : Uri3, port : string) =
  ## set port on uri

  self.port = port


proc setPath*(self : Uri3, path : string) =
  ## set path on uri

  self.path = path


proc setPathSegments*(self : Uri3, paths : seq[string]) =
  ## set path segment (array segment) on uri

  var newpath: string = ""
  for i in 0..high(paths) :
    newpath &= "/" & paths[i]

  self.path = newpath


proc setAnchorPathSegments*(self : Uri3, paths : seq[string]) =
  ## set path segment (array segment) on anchor uri

  var newpath: string = ""
  for i in 0..high(paths) :
    newpath &= "/" & paths[i]

  self.anchor = newpath


proc setPathSegment*(self : Uri3, path : string, index : int) =
  ## set path segment on uri, for specific index

  var segments: seq[string] = self.getPathSegments()
  if high(segments) < index:
    return
  
  segments[index] = path
  self.setPathSegments(segments)


proc setAnchorPathSegment*(self : Uri3, path : string, index: int) =
  ## set anchor path segment on uri, for specific index

  var segments : seq[string] = self.getAnchorSegments()
  if high(segments) < index :
    return

  segments[index] = path
  self.setAnchorPathSegments(segments)


proc setAnchor*(self : Uri3, anchor : string) =
  ## set anchor from uri

  self.anchor = anchor


proc setQueries*(self : Uri3, queries : seq[(string, string)]) =
  ## set all query string (array pair query string) from uri

  self.queries = queries


proc setAnchorQueries*(self : Uri3, queries : seq[(string, string)]) =
  ## set all anchor query string (array pair query string) from uri

  self.anchorQueries = queries


proc setQuery*(
    self : Uri3,
    query : string,
    value : string,
    overwrite : bool = true
  ) =
  ## set query string value for specific query string name

  if not overwrite and self.getQuery(query) != "" :
    return
  var exists: bool = false
  var index: int = -1
  for i in 0..high(self.queries):
    if self.queries[i][0] == query:
      exists = true
      index = i
      break
  if exists:
    self.queries[index][1] = value
  else:
    self.queries.add(@[(query, value)])


proc setAnchorQuery*(
    self: Uri3,
    query: string,
    value: string,
    overwrite: bool = true
  ) =
  ## set anchor query string value for specific query string name

  if not overwrite and self.getAnchorQuery(query) != "" :
    return
  var exists: bool = false
  var index: int = -1
  for i in 0..high(self.anchorQueries):
    if self.anchorQueries[i][0] == query:
      exists = true
      index = i
      break
  if exists:
    self.anchorQueries[index][1] = value
  else:
    self.anchorQueries.add(@[(query, value)])


proc setQuery*(
    self : Uri3,
    queryList : openarray[(string, string)],
    overwrite : bool = true
  ) =
  ## set query for specific pair in array query string, default overwrite

  for i in queryList :
    self.setQuery(i[0], i[1], overwrite)


proc setAnchorQuery*(
    self : Uri3,
    queryList : openarray[(string, string)],
    overwrite : bool = true
  ) =
  ## set query for specific pair in array query string, default overwrite

  for i in queryList :
    self.setAnchorQuery(i[0], i[1], overwrite)


proc `/`*(self : Uri3, path : string) =
  ## append path segment to uri

  self.appendPathSegment(path)


proc `/a`*(self : Uri3, path : string) =
  ## append path segment to anchor uri

  self.appendAnchorSegment(path)


proc `/`*(path : string, self : Uri3) =
  ## prepend path to uri segment

  self.prependPathSegment(path)


proc `/a`*(path : string, self : Uri3) =
  ## prepend path to anchor uri segment

  self.prependAnchorSegment(path)


proc `?`*(self : Uri3, query : openArray[(string, string)]) =
  ## add query string pair into uri

  for q in query :
    self.setQuery(q[0], q[1], true)


proc `?h`*(self : Uri3, query : openArray[(string, string)]) =
  ## add query string pair into anchor uri

  for q in query :
    self.setAnchorQuery(q[0], q[1], true)


proc getBaseUri*(self : Uri3) : string =
  ## return base uri from uri (with scheme)

  if self.port == "" or self.port == "80" :
    result = &"{self.getScheme}://{self.getDomain}"
  else :
    result = &"{self.getScheme}://{self.getDomain}:{self.getPort}"


proc `$`*(self : Uri3) : string =
  ## convert uri to string

  proc buildQuery(q : seq[(string, string)]) : string =
    var query: string = ""
    for i in 0..high(q) :
      let k = q[i][0].strip()
      let v = q[i][1].strip()
      if k == "" and v == "" : continue
      query &= k & "=" & v
      if i != high(q) :
        query &= "&"

    result = query

  # Let's be lazy about this. :P
  var u : URI = URI(
      scheme : self.scheme,
      username : self.username,
      password : self.password,
      hostname : self.hostname,
      port : self.port,
      path : self.path,
      query : buildQuery(self.queries),
      anchor : self.anchor
    )

  var url = $u
  if self.anchor != "" :
    url &= "/" & self.anchor & buildQuery(self.anchorQueries)

  result = $url
