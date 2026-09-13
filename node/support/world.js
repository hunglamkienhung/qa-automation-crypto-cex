'use strict';

// Wire the shared Cucumber harness to this domain. The World is the core
// Recorder plus the slots this domain's steps fill: the mini-cex DB, an HTTP
// response, and the screen.
require('@portfolio/core/harness/cucumber').install({
  browserTag: '@fe',
  viewport: { width: 1440, height: 900 },
  extendWorld(world) {
    world.store = null;   // rows read from the mini-cex SQLite
    world.api = null;     // an HTTP response (mini-cex or the live exchange)
    world.screen = {};    // values read off a page
  },
});
