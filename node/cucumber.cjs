// Feature files live at the domain root, shared with ../python. Only the step
// definitions are specific to this stack. be/** steps never require Playwright,
// so `cucumber-js --tags @be` runs on a machine with no browser installed.
module.exports = {
  default: {
    paths: ['../features/**/*.feature'],
    require: ['support/**/*.js', 'be/**/steps/**/*.js', 'fe/**/steps/**/*.js'],
    format: ['progress', 'summary'],
    formatOptions: { snippetInterface: 'async-await' },
    retry: 0,
    parallel: 0,
  },
};
