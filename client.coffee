$ = require 'jquery-browserify'

# TODO: remove dependency on jquery

get_bridge = ->
  # the server lets us know if we need to build a bridge
  # by storing a global object on window
  # this happens when the HTML container page is generated
  if ( config = window?.__expressito_bridge )?
    try # this fails on internet explorer
      delete window.__expressito_bridge
    build_bridge config
  else
    {}

build_bridge = ( config ) ->
  cli = ajax_cli config.url
  process = (v, path) ->
    switch typeof v
      when 'string'
        if v is '__FUNCTION__'
          ->
            args = Array::slice.apply arguments
            cb = args.pop()
            cli (path: path, args: args), cb
            undefined
        else
          v
      when 'object'
        if v instanceof Array
          copy = []
          copy.push process x, path.concat [i] for x, i of v
          copy
        else
          copy = {}
          copy[k] = process x, path.concat [k] for own k, x of v
          copy
      else
        v
  process config.bridge, []

ajax_cli = ( url ) -> ( params, cb ) -> ajax url, params, cb

ajax = ( url, params, cb ) ->
  $.ajax
    type:     'POST'
    data:     JSON.stringify params
    url:      url
    dataType: 'json'
    contentType: 'application/json'
    error:    ( xhr, status, err ) -> cb status or err
    success:  ( data, status, xhr ) -> if data.res? then cb null, data.res else cb data.err
  undefined


exports.bridge = get_bridge()