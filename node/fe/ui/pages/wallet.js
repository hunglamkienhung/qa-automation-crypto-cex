'use strict';

/**
 * Page object for the mini-cex HTML pages. The server renders small, labelled
 * pages (a class per figure), so the page object reads by label and the
 * assertions are about the exchange, not about the markup.
 *
 * The base URL is the running service; a page that never loads (service down)
 * surfaces as ScreenNotReady, which the steps turn into Blocked.
 */

const BASE = (process.env.MINI_CEX_URL || 'http://127.0.0.1:8110').replace(/\/+$/, '');

class ScreenNotReady extends Error {}

class WalletPage {
  constructor(page) { this.page = page; this.base = BASE; }

  async open(path = '/') {
    try { await this.page.goto(this.base + path, { waitUntil: 'domcontentloaded', timeout: 15_000 }); }
    catch (err) { throw new ScreenNotReady('mini-cex page ' + path + ' did not load: ' + err.message); }
  }

  /** Home: one row per asset, with symbol, USD price text, and listed/delisted label. */
  async assets() {
    await this.page.waitForSelector('ul.assets li.asset', { timeout: 15_000 }).catch(() => { throw new ScreenNotReady('asset list never rendered'); });
    return this.page.$$eval('ul.assets li.asset', (els) => els.map((el) => ({
      symbol: el.getAttribute('data-symbol'),
      symbolText: el.querySelector('.symbol') ? el.querySelector('.symbol').textContent.trim() : '',
      usdText: el.querySelector('.usd') ? el.querySelector('.usd').textContent.trim() : '',
      activeText: el.querySelector('.active') ? el.querySelector('.active').textContent.trim() : '',
    })));
  }

  /** Wallet: one row per balance, with asset and amount text (whole coins). */
  async balances() {
    await this.page.waitForSelector('h1.handle', { timeout: 15_000 }).catch(() => { throw new ScreenNotReady('wallet page never rendered'); });
    return this.page.$$eval('ul.balances li.balance', (els) => els.map((el) => ({
      asset: el.getAttribute('data-asset'),
      amountText: el.querySelector('.amount') ? el.querySelector('.amount').textContent.trim() : '',
    })));
  }

  async op() {
    await this.page.waitForSelector('h1.op-id', { timeout: 15_000 }).catch(() => { throw new ScreenNotReady('op page never rendered'); });
    const read = async (sel) => (await this.page.$(sel)) ? (await this.page.$eval(sel, (e) => e.textContent.trim())) : null;
    return { idText: await read('h1.op-id'), directionText: await read('.direction'), statusText: await read('.status'), amountText: await read('.amount') };
  }
}

module.exports = { WalletPage, ScreenNotReady, BASE };
