// main.js
require('dotenv').config();
const axios = require('axios');
const cron = require('node-cron');
const VerificationEngine = require('./verificationEngine');

// Securely load API token
const CARDLADDER_API_TOKEN = process.env.CARDLADDER_API_TOKEN;

// Data fetch function for Card Ladder
async function fetchCardLadderCollection() {
  const url = 'https://api.cardladder.com/v1/collection'; // Replace with actual API endpoint
  const headers = {
    'Authorization': `Bearer ${CARDLADDER_API_TOKEN}`,
  };
  try {
    const response = await axios.get(url, { headers });
    // Adjust based on actual API response
    return response.data.cards; 
  } catch (err) {
    console.error('Failed to fetch Card Ladder data:', err.message);
    throw err;
  }
}

// Define platforms
const platforms = [
  {
    name: 'CardLadder',
    fetchData: fetchCardLadderCollection,
    credentials: { apiKey: process.env.CARDLADDER_API_TOKEN },
  },
  // Add other platforms similarly with their fetchData functions
];

// Instantiate verification engine
const engine = new VerificationEngine(platforms);

// Run verification immediately
(async () => {
  console.log(`Starting verification at ${new Date().toISOString()}`);
  await engine.run();
})();

// Schedule to run daily at midnight
cron.schedule('0 0 * * *', async () => {
  console.log(`Scheduled verification started at ${new Date().toISOString()}`);
  await engine.run();
});