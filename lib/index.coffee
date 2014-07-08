_BaseEntity = require './BaseEntity'
_store = require './store'
_router = require './router'
_path = require 'path'

exports.initalize = (app, options)->
  _router app, options
  _store.initalize options.database

exports.BaseEntity = _BaseEntity
exports.createTable = _store.createTable
exports.scanSchema = _store.scanSchema
exports.httpStatus = require './httpStatus'