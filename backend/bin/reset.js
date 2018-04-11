var server = require('../server/server');
var dataSource = server.dataSources.db;

dataSource.automigrate('Article');
setTimeout(function() {
  console.log('Done');
  process.exit();
}, 3000);
