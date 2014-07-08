###
  路由
###
_ = require 'underscore'
_httpStatus = require './httpStatus'
_async = require 'async'
_path = require 'path'

_app = null
_options = null
require 'colors'
ACTIONS = ["post", "get", "put", "delete", "patch"]

#anonymity
#获取crud的默认paths
getPaths = (router)->
  paths = {}
  pathSuffix =
    post: ""
    get: "/:id(\\d+)?"
    put: "/:id(\\d+)"
    delete: "/:id(\\d+)"
    patch: '/:id(\\d+)'

  ACTIONS.forEach (method)->
    #如果有指定paths，优先取指定method的path，如果没有取到，则取paths.all
    #假如在paths中没有取到，则拼装path
    suffix = if router.suffix is false then '' else pathSuffix[method]

    path = (router.paths && (router.paths[method] || router.paths.all))
    path = path || (->
      return router.path if typeof router.path is 'object'
      "#{_options.root}#{router.path}#{suffix}"
    )()

    #替换掉路径中的变量
    path = path.replace('#{rootAPI}', _options.root) if typeof(path) isnt 'object'

    paths[method] = path    #"/api/#{path}"
  paths

#正常完所操作后响应数据
responseJSON = (result, res, action)->
  result = result || null
  res.json result
  res.end()

#处理某个具体的路由
executeRoute = (special, action, biz, method, path, router)->
  _app[action] path, (req, res, next)->
    client =
      params: req.params
      body: req.body
      query: req.query

    queue = []
    #处理前
    queue.push(
      (done)->
        #不需要处理
        return done null if not _options.onBeforeHandler
        _options.onBeforeHandler client, req, (newClient)->
          client = newClient
          done null
    )

    #检查权限
    queue.push(
      (done)->
        #不需要权限许可，直接跳过
        return done null if not _options.requestPermission
        _options.requestPermission client, router, action, (err, allow)->
          #未经授权的错误
          return done new _httpStatus.HTTPStatusError(401) if not allow
          done err
    )

    _async.waterfall queue, (err)->
      #特殊方法进行处理
      return biz[method].call biz, req, res, next, client if special

      #标准的处理方法
      biz[method].call biz, client, (err, result)->
        return _httpStatus.responseError err, res if err
        responseJSON result, res, action

#处理API的路由
apiRouter = (router)->
  file = _path.resolve _path.dirname(require.main.filename), _options.biz
  file = _path.join file, router.biz
  biz = require file
  paths = getPaths(router)

  ACTIONS.forEach (action)->
    path = paths[action]
    #将要执行的方法
    method = (router.methods || {})[action]
    #只有在method被显式指定为false或者0的情况下，才忽略
    return if method in [false, 0]

    method = method || action
    #如果方法不存在，则检查是否可以匹配save
    method = 'save' if not biz[method] and method in ['post', 'put', 'patch']

    #使用了特定的方法
    method = RegExp.$1 if special = /^\{(.+)\}$/i.test(method)

    #业务处理找不到对应的方法
    errMsg = "Handler not found: [#{biz} #{path} -> #{action}]".red
    return console.log errMsg if not biz[method]

    #业务逻辑直接接管路由
    executeRoute special, action, biz, method, path, router

#express中间除
module.exports = (app, options)->
  _app = app
  _options = options
  apiRouter(router) for router in options.routers
