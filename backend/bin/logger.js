var colors = require('colors');
var rollbar = require('rollbar');
var Spinner = require('cli-spinner').Spinner;
Spinner.setDefaultSpinnerString('|/-\\');

var spinner, startTime, endTime, spinnerMessage;

rollbar.init('f2d8a00757014aa4be0d3778821fc467', {
  environment: 'production',
  verbose: false
});

function startSpinner(message, keepTimer) {
  spinnerMessage = message;
  if (!keepTimer) {
    startTime = new Date().getTime();
  }
  spinner = new Spinner(message + ' %s');
  spinner.start();
}

function updateSpinner(message) {
  clearSpinner();
  startSpinner(message, true);
}

function clearSpinner() {
  if (spinner) {
    spinner.stop(true);
    spinner = undefined;
  }
}

function endSpinner(message) {
  clearSpinner();
  endTime = new Date().getTime();
  console.log(message + ' in ' + (endTime - startTime)/1000 + 's');
}

function log(message, type) {
  if (spinner) {
    spinner.stop(true);
  }
  switch (type) {
    case 'error':
      console.error(colors.red('! Error: %s'), message);
      break;
    case 'warning':
      console.error(colors.yellow('! Warning: %s'), message);
      break;
    case 'info':
      console.error(colors.cyan('! Notice: %s'), message);
      break;
  }
  rollbar.reportMessage(message, type);
  if (spinner && spinnerMessage) {
    spinner = new Spinner(spinnerMessage + ' %s');
    spinner.start();
  }
}

module.exports.startSpinner = startSpinner;
module.exports.updateSpinner = updateSpinner;
module.exports.clearSpinner = clearSpinner;
module.exports.endSpinner = endSpinner;
module.exports.log = log;

module.exports.error = function(message) {
  log(message, 'error');
};

module.exports.warning = function(message) {
  log(message, 'warning');
};

module.exports.info = function(message) {
  log(message, 'info');
};
