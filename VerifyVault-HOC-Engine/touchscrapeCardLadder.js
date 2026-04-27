const puppeteer = require('puppeteer');

async function scrapeCardLadderCollection() {
  const browser = await puppeteer.launch({ headless: true }); // Set to false for debugging
  const page = await browser.newPage();

  // Navigate to login page if needed
  await page.goto('https://app.cardladder.com/login', { waitUntil: 'networkidle2' });

  // Perform login
  await page.type('#username', 'A8cECSDrQHWrwz8HlzmzPHuTZrm2'); 
  await page.type('#password', 'Fuckingbitch@1988');
  await Promise.all([
    page.click('#login-button'), // Replace with actual login button selector
    page.waitForNavigation({ waitUntil: 'networkidle2' }),
  ]);

  // Navigate to collection page
  await page.goto('https://app.cardladder.com/collection', { waitUntil: 'networkidle2' });

  // Extract data
  const cards = await page.evaluate(() => {
    const results = [];
    // Replace '.card-item' and child selectors with actual selectors from the page
    document.querySelectorAll('.card-item').forEach(cardEl => {
      results.push({
        cardName: cardEl.querySelector('.card-name')?.innerText.trim(),
        set: cardEl.querySelector('.card-set')?.innerText.trim(),
        year: parseInt(cardEl.querySelector('.card-year')?.innerText.trim(), 10),
        grade: parseFloat(cardEl.querySelector('.card-grade')?.innerText.trim()),
        purchasePrice: parseFloat(cardEl.querySelector('.card-price')?.innerText.replace('$', '').trim()),
      });
    });
    return results;
  });

  await browser.close();
  return cards;
}

// Usage
scrapeCardLadderCollection()
  .then(cards => {
    console.log('Extracted cards:', cards);
  })
  .catch(console.error);