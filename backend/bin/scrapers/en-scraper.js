var inherits = require('util').inherits;
var Scraper = require('../scraper');

function EnScraper() {
  Scraper.call(this);
  this.lang = 'en';
  this.baseUrl = 'https://en.wikipedia.org';
  this.featuredArticlesTitle = 'Featured_articles';
  this.goodArticlesTitle = 'Good_articles';
  this.featuredArticlesUrl = this.baseUrl + '/wiki/Category:' +
    this.featuredArticlesTitle;
  this.goodArticlesUrl = this.baseUrl + '/wiki/Category:' +
    this.goodArticlesTitle;
  this.nextPageTitle = 'next page';
}

inherits(EnScraper, Scraper);
module.exports = EnScraper;
