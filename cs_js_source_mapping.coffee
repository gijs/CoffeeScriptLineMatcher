# This module attempts to find source line mappings between CS code
# and JS code.

get_line_matcher = (line) ->
  # return a function that returns true iff a JS
  # line is likely generated from a CS line
  line = line.split('#')[0].trim()
  matches = line.match /^([A-Za-z0-9_.\[\]]+)\s+=/g
  if matches
    lhs = matches[0]
    lhs = lhs[0...lhs.length-1].trim()
    return (line) ->
      ~line.indexOf(lhs + " =")
  matches = line.match /^([A-Za-z0-9_]+\s*: )/g
  if matches and matches.indexOf('{') == -1
    lhs = matches[0]
    lhs = lhs.trim()
    lhs = lhs[0...lhs.length-1].trim()
    return null if lhs == 'constructor'
    return (line) ->
      line.trim().indexOf(lhs+':') == 0 or line.trim().indexOf(lhs+' =') > 0
  null

exports.source_line_mappings = (coffee_lines, js_lines) ->
  # Return an array of source line mappings, where each mapping
  # is an array with these elements:
  #    CS line number (zero-based)
  #    JS line number (zero-based)
  #
  # Not every CS line gets a mapping, but ideally enough lines get
  # mapped to help out downstream tools.
  curr_js_line = 0
  matches = []

  find_js_match = (line_matcher) ->
    for k in [curr_js_line...js_lines.length]
      return k if line_matcher js_lines[k]
    null

  for line, i in coffee_lines
    line_matcher = get_line_matcher line
    if line_matcher
      ln = find_js_match(line_matcher)
      if ln? and curr_js_line < ln
        matches.push [i, ln]
        curr_js_line = ln
  matches.push [coffee_lines.length, js_lines.length]
  matches

