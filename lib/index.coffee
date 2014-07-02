_BaseEntity = require './BaseEntity.'
_store = require './store'

exports.initalize = (options)-> _store.initalize options
exports.BaseEntity = _BaseEntity
exports.createTable = _store.createTable
exports.scanSchema = _store.scanSchema