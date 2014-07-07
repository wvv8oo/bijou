express = require("express")
http = require("http")
app = express()
_shim = require './shim'
path = require("path")

# all environments
app.set "port", process.env.PORT or 3000
app.set "views", path.join(__dirname, "views")
app.set "view engine", "jade"
app.use express.favicon()
app.use express.logger("dev")
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")
_shim(app)

http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")
return
