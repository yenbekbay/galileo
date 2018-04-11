var cheerio = require('cheerio');
var hooks = require('./hooks');
var logger = require('./logger');
var vow = require('vow');

function Scraper() {
  this.requestInterval = 2000;
  this.maxPages = Infinity;
}

Scraper.prototype.getArticles = function() {
  var deferred = vow.defer();
  var self = this;
  self.getArticlesForUrl(self.featuredArticlesUrl).then(function(articles) {
    self.getArticlesForUrl(self.goodArticlesUrl, articles)
      .then(function(articles) {
      self.getArticlesForUrl(self.decentArticlesUrl, articles)
        .then(function(articles) {
        deferred.resolve(articles);
      }, function(err) {
        deferred.reject(err);
      });
    }, function(err) {
      deferred.reject(err);
    });
  }, function(err) {
    deferred.reject(err);
  });
  return deferred.promise();
};

Scraper.prototype.getArticlesForUrl = function(url, articles) {
  if (!articles) articles = [];
  var deferred = vow.defer();
  var self = this;
  if (!hooks.isEmpty(url)) {
    if (articles.length > 0) {
      setTimeout(function() {
        self.processUrl(url, articles).then(function(articles) {
          deferred.resolve(articles);
        }, function(err) {
          deferred.reject(err);
        });
      }, self.requestInterval);
    } else {
      self.processUrl(url, articles).then(function(articles) {
        deferred.resolve(articles);
      }, function(err) {
        deferred.reject(err);
      });
    }
  } else {
    deferred.resolve(articles);
  }
  return deferred.promise();
};

Scraper.prototype.processUrl = function(url, articles, page, deferred) {
  if (!articles) articles = [];
  if (!page) page = 0;
  if (!deferred) deferred = vow.defer();
  var self = this;
  var type;
  var level;
  if (url.indexOf(encodeURIComponent(self.featuredArticlesTitle)) > -1) {
    type = 'featured';
    level = 1;
  } else if (url.indexOf(encodeURIComponent(self.goodArticlesTitle)) > -1) {
    type = 'good';
    level = 2;
  } else {
    type = 'decent';
    level = 3;
  }
  logger.updateSpinner('Loading page ' + (page + 1) + ' of ' + type +
    ' articles for ' + hooks.stringForLang(self.lang));
  hooks.loadUrl(url).then(function(body) {
    var $ = cheerio.load(body);
    var anchors = $('.mw-category-group ul li > a');
    anchors.each(function(i, item) {
      articles.push({
        title: $(this).attr('title'),
        url: self.baseUrl + $(this).attr('href'),
        lang: self.lang,
        level: level
      });
    });
    var nextPageAnchor = $('a:contains("' + self.nextPageTitle + '")');
    page++;
    if (!hooks.isEmpty(nextPageAnchor) && page < self.maxPages) {
      if (!hooks.isEmpty(nextPageAnchor.attr('href'))) {
        url = self.baseUrl + nextPageAnchor.attr('href');
        setTimeout(function() {
          self.processUrl(url, articles, page, deferred);
        }, self.requestInterval);
      } else {
        deferred.resolve(articles);
      }
    } else {
      deferred.resolve(articles);
    }
  }, function(err) {
    deferred.reject(err);
  });
  return deferred.promise();
};

module.exports = Scraper;
