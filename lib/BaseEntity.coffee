_store = require './store'
_async = require 'async'
_ = require 'lodash'

_log = (log)->
  console.log log if process.env.DEBUG

class BaseEntity
  constructor: (@schema)->
    @fields = _.keys(@schema.fields)
    @fields.push 'id'

  #执行一条sql语句
  execute: (sql, cb)-> @entity().knex.raw(sql).exec (err, result)-> cb err, result && result[0]

  #计算分页
  pagination: (pageIndex, pageSize)->
    pageIndex = parseInt(pageIndex)
    pageIndex = 1 if isNaN(pageIndex)
    pageSize = parseInt(pageSize)
    pageSize = 10 if isNaN(pageSize)

    return{
      pageSize: pageSize
      offset: pageIndex * pageSize - pageSize
      limit: pageSize
      pageIndex: pageIndex
    }

  #返回字段列表
  getFields: (without)->
    params = [@fields].concat(without)
    _.without.apply _, params

  #根据条件，检查数据是否存在
  exists: (cond, cb)->
    @count cond, (err, count)-> cb err, not err and count > 0

  #根据条件汇总
  count: (cond, cb)->
    query = @entity().where cond
    query.select query.knex.raw('COUNT(*)')
    @scalar query.toString(), cb

  #获取第一行第一列的数据
  scalar: (sql, cb)->
    _log sql
    @execute sql, (err, result)->
      cell = null
      return cb err, cell if err or not result or result.length is 0

      #取第一行第一列
      for key, value of result[0]
        cell = value
        break

      cb null, cell

  #获取当前的实体
  entity: (withAlias)->
    name = "#{@schema.name}#{if withAlias then ' AS A' else ''}"
    return _store.database()(name)

  #根据id查找一条数据
  findById: (id, fields, cb)->
    if not cb
      cb = fields
      fields = '*'
    cond = id: id


    entity = @entity().where(cond).select(fields)
    _log entity.toString()
    entity.exec (err, result)->
      cb err, result && result[0]

  #只取一条数据
  findOne: (cond, options, cb)->
    if typeof options is 'function'
      cb = options
      options = {}

    @find cond, options, (err, data)->
      cb err, data && data[0]

  #简单的搜索
  find: (cond, options, cb)->
    if typeof options is 'function'
      cb = options
      options = {}

    cond = cond || {}

    #移除掉undefined的查询条件
    for key, value of cond
      delete cond[key] if value is undefined

    queue = []
    self = @
    #查询总记录数
    queue.push(
      (done)->
        return done null, 0 if not options.pagination

        exec = self.entity(true).where cond
        options.beforeQuery?(exec, true)
        exec.select exec.knex.raw('count(*)')

        #汇总统计
        self.scalar exec.toString(), (err, count)-> done null, count
    )

    queue.push(
      (count, done)->
        entity = self.entity(true).where cond
        #如果存在
        options.beforeQuery?(entity)
        if typeof options.fields is 'function'
          options.fields entity
        else
          entity.select(options.fields || '*')

        #加入排序
        entity.orderBy key, value for key, value of options.orderBy || {}

        #如果有使用分页
        page = options.pagination
        if page
          #整理数据，防止提交的数据不对
          page.limit = page.limit || 10
          page.offset = page.offset || 0
          page.recordCount = count
          page.pageSize = page.pageSize || 10
          page.pageIndex = page.pageIndex || 1
          page.pageCount = Math.ceil(count / page.pageSize)

          entity.limit page.limit
          entity.offset page.offset

        #sql = exec.toString()
        _log entity.toString()

        entity.exec (err, items)->
          return done err if err
          return done err, items if not options.pagination

          result =
            items: items
            pagination: page || {}
          done err, result
    )

    _async.waterfall queue, cb

  #根据id更新数据
  updateById: (id, data, cb)->
    data.id = id
    @save data, cb

  #简单的存储
  save: (data = {}, cb)->
    #过滤掉不可靠的数据
    data = @parse data
    entity = @entity()
    isUpdate = Boolean(data.id)
    #如果包含id，则插入
    if isUpdate
      entity.where('id', '=', data.id).update(data)
    else
      entity.insert(data)

    entity.exec (err, result)->
      cb err, result && result.length > 0 && result[0]

  #根据Id删除数据
  removeById: (id, cb)-> @remove id: id, cb

  #简单的删除功能
  remove: (cond, cb)-> @entity().where(cond).del().exec cb

  #根据规则校验
  validate: (value, rule)->
    rule = {type: rule} if typeof rule is 'string'
    switch rule.type
      when 'integer'
        value = parseInt(value)
        value = rule.def || 0 if isNaN(value)
      when 'dateTime'
        value = new Date(value)
      when '', 'string'
      #string的类型是varchar(255)
        value = value and value.substr 0, 255
      when 'text'
        value = value and value.substr(0, rule.maxLength) if rule.maxLength

    value

  #根据schema转换数据为合适的格式
  parse: (data)->
    #复制当前schema
    fields = _.clone @schema.fields
    fields.id = 'integer'
    #只选择有用的数据
    data = _.pick data, _.keys(fields)

    #根据规则校验数据
    result = {}
    result[key] = @validate(value, fields[key]) for key, value of data
    result

module.exports =  BaseEntity