// verificationEngine.js
class VerificationEngine {
  constructor(platforms) {
    this.platforms = platforms; // Array of platform configs
    this.results = {
      success: [],
      failures: [],
      validationErrors: [],
    };
  }

  async authenticate(platformConfig) {
    // Add platform-specific auth if needed
    const { name, credentials } = platformConfig;
    if (!credentials || !credentials.apiKey) {
      throw new Error(`Missing API key for ${name}`);
    }
    // For example, verify token validity if API supports
    return true;
  }

  validateCard(card, platformName) {
    const requiredFields = ['cardName', 'set', 'year', 'grade', 'purchasePrice'];
    for (const field of requiredFields) {
      if (card[field] == null || card[field] === '') {
        throw new Error(`Missing or invalid '${field}' in card data for ${platformName}: ${card.cardName}`);
      }
    }
    // Add custom validation rules here
    if (card.grade < 8) {
      throw new Error(`Card ${card.cardName} has a grade below 8`);
    }
  }

  async processPlatform(platformConfig) {
    const { name, fetchData } } = platformConfig;
    try {
      await this.authenticate(platformConfig);
      const data = await fetchData();
      data.forEach(card => this.validateCard(card, name));
      return { name, data };
    } catch (err) {
      throw { name, error: err.message };
    }
  }

  verifyCrossPlatform(dataMap) {
    const cardMap = new Map();
    for (const [platform, cards] of Object.entries(dataMap)) {
      for (const card of cards) {
        const key = `${card.cardName}|${card.set}|${card.year}`;
        if (!cardMap.has(key)) {
          cardMap.set(key, []);
        }
        cardMap.get(key).push(platform);
      }
    }
    const duplicates = [];
    for (const [cardKey, platforms] of cardMap.entries()) {
      if (platforms.length > 1) {
        duplicates.push({ cardKey, platforms });
      }
    }
    return duplicates;
  }

  async run() {
    const dataMap = {};
    for (const platform of this.platforms) {
      try {
        const result = await this.processPlatform(platform);
        dataMap[result.name] = result.data;
        this.results.success.push(result.name);
      } catch (err) {
        this.results.failures.push(err);
        console.error(`Error in ${err.name}: ${err.error}`);
      }
    }
    const duplicates = this.verifyCrossPlatform(dataMap);
    if (duplicates.length > 0) {
      console.log('Detected duplicates across platforms:');
      duplicates.forEach(dup => {
        console.log(`Card: ${dup.cardKey} in platforms: ${dup.platforms.join(', ')}`);
      });
    } else {
      console.log('No duplicates found across platforms.');
    }
    return this.results;
  }
}

module.exports = VerificationEngine;