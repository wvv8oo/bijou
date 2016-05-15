// Generated by CoffeeScript 1.9.3
(function() {
  var _BaseEntity, _path, _router, _store;

  _BaseEntity = require('./BaseEntity');

  _store = require('./store');

  _router = require('./router');

  _path = require('path');

  exports.initalize = function(app, options) {
    _router(app, options);
    return _store.initalize(options.database);
  };

  exports.BaseEntity = _BaseEntity;

  exports.createTable = _store.createTable;

  exports.scanSchema = _store.scanSchema;

  exports.http = require('./http');

}).call(this);