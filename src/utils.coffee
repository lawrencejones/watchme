# Array prototype utils
Array::includes = (e) ->
  for a in this
    return true if a == e
  return false

Array::splitOn = (e) ->
  hit = false; this.reduce ((a,b) ->
    hit ||= (b == e); a[+hit].push b; a), [[],[]]
