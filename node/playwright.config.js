'use strict';
// Playwright specs are the second entrypoint into the FE tier (the first is the
// Cucumber steps). Both read the same pages; both grade through the core.
const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: './fe/ui/specs',
  timeout: 60_000,
  use: { headless: true, viewport: { width: 1440, height: 900 }, actionTimeout: 15_000 },
  reporter: [['list']],
});
