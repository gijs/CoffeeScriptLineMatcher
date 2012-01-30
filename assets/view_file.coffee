$ ->
  do ->
    $win = $ window
    setPre = ->
      $('td').css width: 50
      $('.code').css width: ($win.width()-185) * 0.50
    $win.resize setPre
    setPre()
  
  window.onfocus = ->
    f = ->
      $.getJSON "timestamps?FILE=#{CS_FN}", (data) ->
        if data.cs == FINGERPRINT.cs and data.js == FINGERPRINT.js
          # do nothing if files didn't change
        else
          # reload the page
          location.reload true

    # In some editors, like TextMate, files get saved when you remove
    # focus from the editor, so we give a couple seconds for the save
    # to happen and for coffee -wc to wake up.
    setTimeout f, 2000
   
  set_up_key_mappings = ->
    digits = ''

    go_to_js_line = (digits) ->
      id = "js_#{digits}"
      elem = $ "a##{id}"
      if elem.length == 1
        elem.focus()
        true
      else
        alert "JS line number #{digits} does not exist"
        false

    document.onkeypress = (e) ->
      keyunicode = e.charCode or e.keyCode
      c = String.fromCharCode(keyunicode)
      if '0' <= c <= '9'
        digits += c
        found = go_to_js_line digits
        if not found then digits = ''
        true
      else if c is ' '
        digits = ''
        false
      else
        false
  
  set_up_key_mappings()