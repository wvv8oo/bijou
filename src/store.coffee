_knex = require 'knex'
_database = null
_fs = require 'fs'
_path = require 'path'
_async = require 'async'

#创建字段
createField = (table, schema)->
  #自动添加一个名为id的主键
  table.increments('id').primary()
  for key, property of schema.fields
    property = property || "string"
    if typeof property is 'string'
      table[property] key
    else
      #处理对象字面量
      field = table[property.type || 'string'] key
      field.index() if property.index
      field.defaultTo(property.default) if property.default isnt undefined


exports.database = ()->
  throw new Error('数据库还没有初始化') if not _database
  _database

exports.initalize = (options)->
  _database = _knex options

#创建一个表
exports.createTable = (schema, cb)->
  db = exports.database()
  db.schema.hasTable(schema.name).then (exists)->
    #如果表已经存在，则退出
    return cb null if exists
    db.schema.createTable(schema.name, (table)->
      createField table, schema
    ).then ()-> cb null

#扫描文件夹，根据schema文件初始化数据库
exports.scanSchema = (dir, cb)->
  #允许的扩展名
  allowExt = ['.coffee', '.json', '.jss']

  files = _fs.readdirSync dir
  _async.eachSeries(files, ((filename, done)->
      #只处理指定扩展名的文件
      return done null if not(_path.extname(filename) in allowExt)
      #获取schema
      schema = require("#{dir}/#{filename}").schema

      return console.log "#{filename}不是一个合法的schema文件" if not (schema and schema.name and schema.fields)

      #console.log "创建表：#{schema.name}"
      #建表
      exports.createTable schema, done
    ), cb
  )

