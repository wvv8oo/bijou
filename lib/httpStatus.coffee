#封装http状态错误
class HTTPStatusError
  constructor: (@status, @message, @code)->
  toJSON: ()-> message: @message, code: @code

class NotAcceptableError extends HTTPStatusError
  constructor: (@message = 'Not Acceptable', @code)-> super 406, @message, @code

class NotFoundError extends HTTPStatusError
  constructor: (@message = 'Not Found', @code)-> super 404, @message, @code

class ForbiddenError extends HTTPStatusError
  constructor: (@message = 'Forbidden', @code)-> super 403, @message, @code

class UnauthorizedError extends HTTPStatusError
  constructor: (@message = 'Unauthorized', @code)-> super 401, @message, @code

exports.HTTPStatusError = HTTPStatusError
exports.NotAcceptableError = NotAcceptableError
exports.NotFoundError = NotFoundError
exports.ForbiddenError = ForbiddenError
exports.UnauthorizedError = UnauthorizedError

#响应错误
exports.responseError = (err, res)->
  status = 500  #默认为500错误
  message = err
  if err instanceof HTTPStatusError
    switch err.status
      when 406 then return this.responseAcceptable err.toJSON(), res
      else
        status = err.status
        message = err.message

  res.statusCode = status
  if(typeof message is 'object')
    res.json message
  else
    res.end message || ''

#正常完所操作后响应数据
exports.responseJSON = (err, result, res, action)->
  return @responseError err, res if err
  result = result || null
  res.json result

exports.responseNotFound = (res)->
  @responseError new NotFoundError(), res
#响应数据格式不对
exports.responseAcceptable = (data, res)->
  res.statusCode = 406

  if(typeof data is 'object')
    res.json data
  else
    res.end data || ''