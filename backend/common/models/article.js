module.exports = function(Article) {
  Article.random = function(number, lang, callback) {
    Article.dataSource.connector.query('SELECT * FROM article WHERE lang = \'' +
      lang + '\' ORDER BY ' + 'RANDOM() LIMIT ' + number,
      function(err, articles) {
      callback(err, articles);
    });
  };

  Article.remoteMethod('random', {
    description: 'Return given number of random Articles.',
    accepts: [
      { arg: 'number', type: 'number' },
      { arg: 'lang', type: 'string' },
    ],
    returns: { arg: 'data', type: ['Article'], root: true },
    http: { verb: 'get', path: '/random' }
  });
};
