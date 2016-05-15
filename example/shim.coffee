_path = require("path")
_bijou = require("../src")
_config = require './config'

#获取用户的基本信息
getMember = (req, cb)->
  member =
    member_id: 0
  cb member

#初始化数据库
initDatabase = ()->
  schema = _path.join __dirname, './schema'
  _bijou.scanSchema schema, ->

module.exports = (app)->
  options =
    root: '/api/'
    #指定数据库链接
    database: _config.database
    #指定业务逻辑的文件夹
    biz: './biz'
    #指定路由的配置文件
    routers: _config.routers
    #处理之前
    onBeforeHandler: (client, req, cb)->
      getMember req, (member)->
        client.member = member
        cb client
    #请求访问许可
    requestPermission: (client, router, action, cb)->
      cb null, true

  _bijou.initalize(app, options)
  initDatabase()