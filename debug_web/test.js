const puppeteer = require('puppeteer');

(async () => {
  try {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    page.on('console', msg => console.log('PAGE LOG:', msg.text()));
    page.on('pageerror', error => console.log('PAGE ERROR:', error.message));
    page.on('requestfailed', request => {
      console.log('REQUEST FAILED:', request.url(), request.failure()?.errorText || 'Unknown Error');
    });
    page.on('response', response => {
      if (response.status() === 404) {
        console.log('404 NOT FOUND:', response.url());
      }
    });

    console.log('Navigating to http://127.0.0.1:8080...');
    await page.goto('http://127.0.0.1:8080', { waitUntil: 'networkidle2', timeout: 10000 });
    
    console.log('Page loaded. Waiting 5 seconds...');
    await new Promise(r => setTimeout(r, 5000));
    
    await browser.close();
    console.log('Done.');
  } catch (e) {
    console.error('PUPPETEER ERROR:', e);
  }
})();
