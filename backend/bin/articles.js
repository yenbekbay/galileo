var async = require('async');
var colors = require('colors');
var hooks = require('./hooks');
var logger = require('./logger');
var server = require('../server/server');
var vow = require('vow');

var EnScraper = require('./scrapers/en-scraper');
var RuScraper = require('./scrapers/ru-scraper');

var dataSource = server.dataSources.db;
var Article = server.models.Article;

var enScraper = new EnScraper();
var ruScraper = new RuScraper();
var langs = ['en', 'ru'];

async.eachSeries(langs, function(lang, langCallback) {
  var scraper;
  switch(lang) {
    case 'en':
      scraper = enScraper;
      break;
    case 'ru':
      scraper = ruScraper;
      break;
  }
  logger.startSpinner('Loading articles for ' + hooks.stringForLang(lang));
  scraper.getArticles().then(function(articles) {
    saveArticles(articles, lang).then(function() {
      langCallback();
    }, function(err) {
      langCallback(err);
    });
  }, function(err) {
    langCallback(err);
  });
}, function(err) {
  if (err) {
    logger.error(err.message);
  } else {
    console.log('Done');
    process.exit();
  }
});

function saveArticles(articles, lang) {
  var deferred = vow.defer();
  logger.endSpinner('Loaded ' + articles.length + ' articles for ' +
    hooks.stringForLang(lang));
  logger.startSpinner('Processing articles for ' + hooks.stringForLang(lang));
  dataSource.autoupdate('Article', function(err) {
    if (err) {
      deferred.reject(err);
    } else if (hooks.isEmpty(articles)) {
      logger.warning('No articles found for ' + hooks.stringForLang(lang));
      deferred.resolve();
    } else {
      var created = 0, fetched = 0, processed = 0;
      async.each(articles, function(article, callback) {
        Article.findOne({where: {url: article.url}},
          function(err, existingArticle) {
          processed++;
          if (processed < articles.length) {
            if (processed % 200 === 0) {
              logger.updateSpinner('Processing article ' + processed +
                ' out of ' + articles.length + ' for ' +
                hooks.stringForLang(lang));
            }
          } else {
            logger.updateSpinner('Saving articles for ' +
              hooks.stringForLang(lang));
          }
          if (err) {
            deferred.reject(err);
          } else if (hooks.isEmpty(existingArticle)) {
            Article.create(article, function(err, article) {
              created++;
              callback(err);
            });
          } else {
            fetched++;
            callback();
          }
        });
      }, function(err) {
        if (err) {
          deferred.reject(err);
        } else {
          logger.clearSpinner();
          console.log(colors.green('Created %s articles for %s'), created,
            hooks.stringForLang(lang));
          console.log('Fetched ' + fetched + ' articles for ' +
            hooks.stringForLang(lang));
          deferred.resolve();
        }
      });
    }
  });
  return deferred.promise();
}
