const puppeteer = require('puppeteer');

async function scrapeCardLadderCollection() {
  const username = 'A8cECSDrQHWrwz8HlzmzPHuTZrm2'; 
  const password = 'Fuckingbitch@1988'; 

  const browser = await puppeteer.launch({ headless: false });   const page = await browser.newPage();

  
  await page.goto('https://app.cardladder.com/login', { waitUntil: 'networkidle2' });

  await page.type('retrocollector077@gmail.com', username); 
  await page.type('Lun@hernz0326', password); 
  await Promise.all([
    page.click('https://app.cardladder.com/login'), 
    page.waitForNavigation({ waitUntil: 'networkidle2' }),
  ]);

    await page.goto('https://app.cardladder.com/collection', { waitUntil: 'networkidle2' });

  
  const cards = await page.evaluate(() => {
    const results = [];
    // Replace selectors below with actual selectors from the webpage
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

// Run the function
scrapeCardLadderCollection()
  .then(cards => {
    console.log('Extracted cards:', cards);
  })
  .catch(console.error);