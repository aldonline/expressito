browserify      = require 'browserify'
uglify          = require 'uglify-js'

# https://github.com/substack/node-browserify/issues/75
uglify_filter = (str) -> uglify.minify( str, {fromString: true }).code

module.exports = ( opts ) -> new App opts

class App

  constructor: ( @opts ) ->
  
  listen: ( port ) ->
    # creates a standalone express server
    # and listens on the given port
    # an easy way to bootstrap a project
    # but you loose some of the functionality
    throw new Error 'App.listen not implemented'

  
  attach: ( express_app ) ->
    main_script       = @opts.base + @opts.entry
    main_script_rel   = @opts.entry
    script_url        = @opts.mount + '/expressito_express_bundle.js'
    # attaches to an already existing express.js app
    express_app.use browserify 
      require:  main_script
      mount:    script_url
      watch:    @opts.production isnt true
      filter:   if @opts.production is true then uglify_filter else String

    scripts = @opts.js or []
    scripts.push script_url
    scripts = ( """<script src="#{s}"></script>""" for s in scripts ).join ' '
      
    css = @opts.css or []
    css = ( """<link rel="stylesheet" href="#{s}"/>""" for s in css ).join ' '

    favicon = if @opts.favicon?
        """<link rel="shortcut icon" href="#{@opts.favicon}" type="image/png">"""
      else
        ""

    bridge_config = if (bridge = @opts.bridge)?
      c = JSON.stringify url: @opts.mount, bridge: process bridge
      "window.__expressito_bridge = #{c};"
    else
      ''

    html_str = """
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8" />
          #{css}
          #{favicon}
          <script>
            #{bridge_config}
          </script>
          #{scripts}
          <script>
            require('#{main_script_rel}')
          </script>
        </head>
        <body>
        </body>
      </html>
    """

    express_app.get @opts.mount, ( req, res, next ) ->
      res.setHeader 'Content-Type', 'text/html'
      res.end html_str


    # setup simple HTTP based RPC
    if ( bridge = @opts.bridge )?
      # DEPENDS ON:
      # express_app.use express.bodyParser()
      express_app.post @opts.mount, ( req, res, next ) ->
        {path, args} = req.body
        steps = [bridge]
        steps.push steps[i][k] for k, i in path
        args.push (e, r) ->
          res.setHeader 'Content-Type', 'application/json'
          res.send JSON.stringify {err: e, res: r}
        x = steps.length - 1
        steps[x].apply steps[x - 1], args



process = (v) ->
  switch typeof v
    when 'function'
      '__FUNCTION__'
    when 'object'
      if v instanceof Array
        ( process x for x in v )
      else
        c = {}
        c[k] = process x for own k, x of v
        c
    else
      v





