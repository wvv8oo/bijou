module.exports =
  routers: [
    {
      #路由
      path: 'todo'
      #业务逻辑
      biz: 'todo'
      #将会处理的方法
      methods: put: 0
    }
  ],
  database:
    client: 'mysql',
    connection:
      host     : '127.0.0.1',
      user     : 'root',
      password : '123456',
      database : 'test'