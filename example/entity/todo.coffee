_BaseEntity = require('../../src').BaseEntity

class Todo extends _BaseEntity
  constructor: ->
    super require('../schema/todo').schema

module.exports = new Todo