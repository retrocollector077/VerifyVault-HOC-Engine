# VerifyVault HOC Engine - Dashboard Setup & Deployment Guide

## Quick Start (5 Minutes)

### Option 1: Instant Launch
1. Open `verifyvault-dashboard.html` or `verifyvault-advanced-dashboard.html` directly in your browser
2. No installation, no dependencies - it just works!

### Option 2: Local Server (Recommended for Testing)
```bash
# Using Python 3
python -m http.server 8000

# Using Python 2
python -m SimpleHTTPServer 8000

# Using Node.js (if installed)
npx http-server
```
Then open `http://localhost:8000` in your browser

---

## Files Overview

### Core Dashboard Files

#### 1. **verifyvault-dashboard.html** (Production)
**Best for:** Portfolio tracking, professional presentations, client demos
- Clean, focused interface
- Real-time portfolio analytics
- Smart contract integration display
- Responsive design
- ~180 cards with live data

**Features:**
- ⚡ Live portfolio metrics
- 📊 Interactive charts (Chart.js)
- 🏆 Sport-specific filtering
- 💎 Featured holdings showcase
- 📈 Historical growth tracking
- 🔗 Blockchain verification display

#### 2. **verifyvault-advanced-dashboard.html** (Advanced)
**Best for:** Active traders, advanced analytics, live market simulation
- Full trading panel with simulation
- Real-time market ticker
- Price movement analysis
- Trade history logging
- Advanced settlement options
- Alert management system

**Features:**
- 💹 24-hour price movement
- 🔔 Smart alerts & notifications
- 💼 Trading simulator
- 📋 Trade history
- 🔐 Multi-crypto settlement
- 📊 Advanced metrics dashboard

#### 3. **DASHBOARD_DOCUMENTATION.md**
Complete feature documentation and customization guide

#### 4. **This file - SETUP_GUIDE.md**
Installation, deployment, and customization instructions

---

## System Requirements

### Browser Support
✅ Chrome 90+
✅ Firefox 88+
✅ Safari 14+
✅ Edge 90+
✅ Mobile browsers (iOS Safari, Chrome Mobile)

### Hardware
- **Minimum**: 2GB RAM, any modern CPU
- **Recommended**: 4GB+ RAM, modern multi-core CPU
- **Internet**: 1Mbps+ for Chart.js CDN loading

### Software
- No installation required
- No backend server needed
- Works completely client-side
- Chart.js loaded from CDN (cdnjs.cloudflare.com)

---

## Deployment Options

### 1. Direct File Access
```bash
# Simply open in browser
open verifyvault-dashboard.html          # macOS
start verifyvault-dashboard.html         # Windows
xdg-open verifyvault-dashboard.html      # Linux
```

### 2. Web Server Hosting

#### GitHub Pages (Free)
```bash
# 1. Create GitHub repo
# 2. Add HTML files to repo
# 3. Enable GitHub Pages in Settings
# 4. Access at: https://yourusername.github.io/verifyvault
```

#### Netlify (Free/Paid)
```bash
# 1. Drag and drop HTML files to Netlify
# 2. Or connect GitHub repo
# 3. Automatic HTTPS and CDN
# 4. Custom domain support
```

#### Vercel (Free/Paid)
```bash
# 1. Import project
# 2. Auto-deploys on push
# 3. Zero-config deployment
```

#### Traditional Web Server
```bash
# Copy files to web server
scp verifyvault-*.html user@server:/var/www/html/

# Configure nginx/Apache
# Access at: https://yourdomain.com/verifyvault
```

### 3. Docker Deployment
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY verifyvault-*.html ./
RUN npm install -g http-server
EXPOSE 8080
CMD ["http-server", "-p", "8080"]
```

```bash
# Build and run
docker build -t verifyvault .
docker run -p 8080:8080 verifyvault
```

---

## Customization Guide

### Adding Your Card Data

#### Method 1: Edit JavaScript Array
Locate in HTML file:
```javascript
const cardsData = [
    {
        player: "Player Name",
        set: "Set Name",
        variation: "Variation",
        card: "#123",
        category: "Football",    // Football, Basketball, Baseball, Soccer
        condition: "PSA 10",
        value: 1234.56,          // Current market value
        investment: 100,          // Original investment
        profit: 1134.56,          // Current profit
        symbol: "UNIQUE_SYMBOL"   // Token symbol
    },
    // Add more cards...
];
```

#### Method 2: JSON Import (Advanced)
```javascript
// Load from external JSON file
fetch('cards.json')
    .then(r => r.json())
    .then(data => {
        cardsData = data;
        renderCards(cardsData);
    });
```

### Styling Customization

#### Color Scheme
Primary colors located at top of CSS:
```css
/* Primary accent colors */
--primary: #6366f1;        /* Indigo */
--secondary: #3b82f6;      /* Blue */
--success: #10b981;        /* Green */
--warning: #f59e0b;        /* Amber */
--danger: #ef4444;         /* Red */
```

Change these to match your brand:
```css
/* Example: Change to purple theme */
background: linear-gradient(135deg, #9333ea 0%, #7c3aed 100%);
```

#### Layout Modifications
```css
/* Adjust card grid columns */
.cards-grid {
    grid-template-columns: repeat(4, 1fr);  /* 4 cards per row */
}

/* Change header height */
header {
    padding: 2rem 4rem;  /* More padding */
}
```

### Feature Customization

#### Change Portfolio Metrics
```javascript
// Modify stat card values
const stats = {
    portfolioValue: "$124.8K",
    totalInvested: "$2.4K",
    roi: "5,097%",
    cardsCount: 180
};
```

#### Update Chart Data
```javascript
// Modify chart datasets
new Chart(document.getElementById('sportChart'), {
    data: {
        labels: ['Football', 'Basketball', 'Baseball', 'Soccer'],
        datasets: [{
            data: [42, 28, 18, 12]  // Your numbers
        }]
    }
});
```

---

## Integration with Smart Contracts

### Blockchain Connection Setup

#### Step 1: Add Web3 Library
```html
<script src="https://cdn.jsdelivr.net/npm/web3@1.10.0/dist/web3.min.js"></script>
```

#### Step 2: Initialize Web3
```javascript
const web3 = new Web3(window.ethereum);

// Connect wallet
async function connectWallet() {
    try {
        const accounts = await ethereum.request({
            method: 'eth_requestAccounts'
        });
        const account = accounts[0];
        console.log('Connected:', account);
    } catch (error) {
        console.error('Connection failed:', error);
    }
}
```

#### Step 3: Contract Interaction
```javascript
const CONTRACT_ADDRESS = '0x...';
const CONTRACT_ABI = []; // Your contract ABI

const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);

// Call contract methods
async function getCardValue(symbol) {
    return await contract.methods.getCardValue(symbol).call();
}
```

### Example: Real-time Price Updates
```javascript
// Fetch data from blockchain every 30 seconds
setInterval(async () => {
    for (const card of cardsData) {
        const blockchainValue = await getCardValue(card.symbol);
        card.value = blockchainValue;
    }
    renderCards(cardsData);
}, 30000);
```

---

## API Integration

### Connecting to External Data Sources

#### CoinGecko API (Crypto Prices)
```javascript
async function getCryptoPrices() {
    const response = await fetch(
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum,bitcoin&vs_currencies=usd'
    );
    return response.json();
}
```

#### Sports Card Market APIs
```javascript
async function getMarketData() {
    // PSA, SGC, or other grading service APIs
    const response = await fetch('https://api.psacard.com/...');
    return response.json();
}
```

#### Your Custom Backend
```javascript
// Fetch from your own server
async function getPortfolioData() {
    const response = await fetch('/api/portfolio');
    const data = response.json();
    updateDashboard(data);
}

// Auto-refresh every 60 seconds
setInterval(getPortfolioData, 60000);
```

---

## Performance Optimization

### Image Optimization
```javascript
// Lazy load card images
const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            loadImage(entry.target);
        }
    });
});
```

### Chart Optimization
```javascript
// Reduce chart update frequency
const chartUpdateInterval = setInterval(() => {
    updateCharts();
}, 5000); // Update every 5 seconds instead of 1
```

### Local Storage
```javascript
// Cache data locally
const savedData = JSON.stringify(cardsData);
localStorage.setItem('verifyvault-portfolio', savedData);

// Load cached data
const cachedData = localStorage.getItem('verifyvault-portfolio');
if (cachedData) {
    cardsData = JSON.parse(cachedData);
}
```

---

## Troubleshooting

### Charts Not Loading
```javascript
// Check if Chart.js is loaded
if (typeof Chart === 'undefined') {
    console.error('Chart.js not loaded');
    // Fallback: display data in table format
}
```

### CORS Issues (External API)
```javascript
// Use CORS proxy for external APIs
const corsProxy = 'https://cors-anywhere.herokuapp.com/';
fetch(corsProxy + externalApiUrl)
```

### Mobile Responsiveness Issues
```css
@media (max-width: 768px) {
    .dashboard-grid {
        grid-template-columns: 1fr;  /* Single column on mobile */
    }
}
```

### Performance Issues
1. Reduce number of cards displayed initially
2. Implement pagination
3. Lazy-load images
4. Minimize JavaScript execution

---

## Security Best Practices

### 1. Never Expose Private Keys
```javascript
// ❌ WRONG - Never do this
const privateKey = "0x...";

// ✅ CORRECT - Use environment variables
const privateKey = process.env.PRIVATE_KEY;
```

### 2. Validate User Input
```javascript
// Sanitize input before using
function sanitizeInput(input) {
    return input.replace(/[<>]/g, '');
}
```

### 3. Use HTTPS Only
```javascript
// Check for secure connection
if (window.location.protocol !== 'https:') {
    console.warn('Not using HTTPS - upgrade for security');
}
```

### 4. Content Security Policy
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; script-src 'self' cdnjs.cloudflare.com">
```

---

## Advanced Features

### Real-Time WebSocket Updates
```javascript
const socket = new WebSocket('wss://your-server.com/live');

socket.onmessage = (event) => {
    const data = JSON.parse(event.data);
    updateCardPrice(data.symbol, data.price);
};
```

### Push Notifications
```javascript
// Request permission
Notification.requestPermission();

// Send notification
new Notification('Portfolio Alert', {
    body: 'Your Tom Brady card just hit $5,000!',
    icon: 'icon.png'
});
```

### Dark/Light Mode Toggle
```javascript
function toggleTheme() {
    document.body.classList.toggle('dark-mode');
    localStorage.setItem('theme', document.body.className);
}

// Load saved theme
if (localStorage.getItem('theme') === 'dark-mode') {
    document.body.classList.add('dark-mode');
}
```

---

## Monitoring & Analytics

### Add Google Analytics
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_ID');
</script>
```

### Track User Events
```javascript
function trackEvent(category, action, label) {
    gtag('event', action, {
        'event_category': category,
        'event_label': label
    });
}

// Example usage
trackEvent('trading', 'buy', 'WTTBR');
```

---

## Backup & Recovery

### Auto-Save Portfolio
```javascript
// Auto-save every minute
setInterval(() => {
    const backup = JSON.stringify(cardsData);
    localStorage.setItem('portfolio-backup-' + Date.now(), backup);
}, 60000);
```

### Export Portfolio
```javascript
function exportPortfolio() {
    const data = JSON.stringify(cardsData, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'portfolio-' + new Date().toISOString() + '.json';
    a.click();
}
```

---

## Support & Resources

### Documentation
- `DASHBOARD_DOCUMENTATION.md` - Feature documentation
- Smart contracts: `verifyvault-HOC-Engine.sol`
- Configuration: `hardhat_config.js`

### Development Tools
```bash
# Install dependencies
npm install

# Compile smart contracts
npm run compile

# Run tests
npm run test

# Deploy contracts
npm run deploy
```

### Community & Help
- 📧 Email: support@verifyvault.io
- 💬 Discord: [Join Community]
- 🐦 Twitter: @VerifyVault
- 📚 Docs: docs.verifyvault.io

---

## Changelog

### v2.0.0 (Advanced Dashboard)
- ✨ Trading simulation panel
- ✨ Real-time market ticker
- ✨ Advanced alerts system
- ✨ Performance metrics
- 🚀 Improved responsive design

### v1.0.0 (Production Dashboard)
- ✅ Portfolio analytics
- ✅ Chart.js integration
- ✅ Smart contract display
- ✅ Sport filtering
- ✅ Responsive design

---

## License

MIT License - Free for personal and commercial use

---

**Ready to deploy? Pick a file and get started:**

1. **Just want to view?** → Open `verifyvault-dashboard.html` in browser
2. **Need advanced features?** → Use `verifyvault-advanced-dashboard.html`
3. **Building custom features?** → Follow the customization guide above

**Questions?** Check `DASHBOARD_DOCUMENTATION.md` or contact support@verifyvault.io
