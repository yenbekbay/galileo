var inherits = require('util').inherits;
var Scraper = require('../scraper');

function RuScraper() {
  Scraper.call(this);
  this.lang = 'ru';
  this.baseUrl = 'https://ru.wikipedia.org';
  this.featuredArticlesTitle = 'Избранные_статьи';
  this.goodArticlesTitle = 'Хорошие_статьи';
  this.decentArticlesTitle = 'Добротные_статьи';
  this.featuredArticlesUrl = this.baseUrl +
    '/wiki/' + encodeURIComponent('Категория:Википедия:' +
    this.featuredArticlesTitle + '_по_алфавиту');
  this.goodArticlesUrl = this.baseUrl +
    '/wiki/' + encodeURIComponent('Категория:Википедия:' +
    this.goodArticlesTitle + '_по_алфавиту');
  this.decentArticlesUrl = this.baseUrl +
    '/wiki/' + encodeURIComponent('Категория:Википедия:' +
    this.decentArticlesTitle + '_по_алфавиту');
  this.nextPageTitle = 'Следующая страница';
}

inherits(RuScraper, Scraper);
module.exports = RuScraper;
