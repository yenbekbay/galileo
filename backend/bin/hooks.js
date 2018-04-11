var request = require('request');
var vow = require('vow');

module.exports.isEmpty = function(str) {
    return (!str || 0 === str.length);
};

module.exports.loadUrl = function(url) {
  var deferred = vow.defer();
  var options = {
    url: url,
    gzip: true,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1)' +
        'AppleWebKit/600.2.5 (KHTML, like Gecko) Version/8.0.2 Safari/600.2.5'
    },
    encoding: null
  };
  request.get(options, function(err, response, body) {
    if (!err && response.statusCode === 200) {
      deferred.resolve(body);
    } else if (err) {
      deferred.reject(new Error('Couldn\'t load the page ' + options.url +
        ': ' + err.message));
    } else {
      deferred.reject(new Error('Couldn\'t load the page ' + options.url +
        ': Status code ' + response.statusCode));
    }
  });
  return deferred.promise();
};

module.exports.stringForLang = function(lang) {
  switch(lang) {
    case 'en':
      return 'English';
    case 'ru':
      return 'Russian';
  }
};
