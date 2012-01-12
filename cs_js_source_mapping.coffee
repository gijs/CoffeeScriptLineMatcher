# This module attempts to find source line mappings between CS code
# and JS code.

get_line_matcher = (line) ->
  # return a function that returns true iff a JS
  # line is likely generated from a CS line
  line = line.split('# ')[0].trim()
  return null if line == ''

  # requires
  if line.indexOf(" = require") > 0
    matches = line.match /["'].*?["']/g
    if matches
      s = matches[0]
      return (line) ->
        line.indexOf("= require(#{s})") > 0

  # classes
  matches = line.match /^class ([@A-Za-z0-9_\.\[\]]+)/g
  if matches
    s = matches[0]
    s = s.replace "class ", ""
    return (line) ->
      ~line.indexOf(s + " =")

  # assignments
  matches = line.match /^([\$@A-Za-z0-9_\.\[\]]+)\s+(=|\+=)/g
  if matches
    [lhs, op] = matches[0].split /\s+/
    if lhs.length > 2
      lhs = lhs.replace '@', '.'
      return (line) ->
        ~line.indexOf(lhs + " " + op)
  
  # objects
  matches = line.match /^@?([A-Za-z0-9_]+\s*: )/g
  if matches and matches.indexOf('{') == -1
    lhs = matches[0].replace '@', ''
    lhs = lhs.trim()
    lhs = lhs[0...lhs.length-1].trim()
    return null if lhs in ['constructor', 'class']
    return (line) ->
      line.trim().indexOf(lhs+':') == 0 or line.trim().indexOf(lhs+' =') > 0
  
  # multiple simple args
  matches = line.match /\(\S+, .*?\) ->/g
  if matches
    s = matches[0]
    s = s.replace "->", "{"
    return (line) -> line.indexOf(s) > 0
  
  # strings
  matches = line.match /"[^"]+?"|'[^']+?'/g
  if matches
    for str in matches
      if str.length >= 5
        return (line) -> line.indexOf(str) >= 0
    
  # fallthru
  get_tokens= (line) ->
    line = line.replace /\(\)/, ' '
    line = line.replace /\s+/, ' '
    line.split ' '
  
  parts = get_tokens line
  (line) ->
    js_code = get_tokens(line).join ' '
    for i in [0..parts.length - 3]
      needle = parts[i] + " " + parts[i+1] + parts[i+2]
      if js_code.indexOf(needle) >= 0
        return true
    false


is_comment_line = (line) ->
  line = line.trim()
  return line == '' or line[0] == '#'

exports.source_line_mappings = (coffee_lines, js_lines) ->
  # Return an array of source line mappings, where each mapping
  # is an array with these elements:
  #    CS line number (zero-based)
  #    JS line number (zero-based)
  #
  # Not every CS line gets a mapping, but ideally enough lines get
  # mapped to help out downstream tools.
  curr_cs_line = 0
  curr_js_line = 0
  matches = []

  find_js_match = (line_matcher) ->
    for k in [curr_js_line...js_lines.length]
      return k if line_matcher js_lines[k]
    null

  for line, cs_line in coffee_lines
    line_matcher = get_line_matcher line
    if line_matcher
      js_line = find_js_match(line_matcher)
      if js_line? and curr_js_line < js_line
        first_comment_line = cs_line
        while curr_cs_line <= first_comment_line-1 and is_comment_line coffee_lines[first_comment_line-1]
          first_comment_line -= 1
        if first_comment_line < cs_line
          matches.push [first_comment_line, js_line]
        matches.push [cs_line, js_line]
        curr_cs_line = cs_line
        curr_js_line = js_line
  matches.push [coffee_lines.length, js_lines.length]
  matches

