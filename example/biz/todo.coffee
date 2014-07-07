_entity = require '../entity/todo'

exports.patch = (client, cb)->
  cb null, 'path'

#创建
exports.post = (client, cb)->
  cb null, 'save'

#删除
exports.delete = (client, cb)->


#查找
exports.get = (client, cb)->
  id = client.params.id
  if id
    _entity.findById id, cb
  else
    options =
      pagination: _entity.pagination client.query.pageIndex, 10

    _entity.find {}, options, cb

#保存（统一处理post/patch/put）
exports.save = (client, cb)->

exports.toString = -> 'todo'
