# VerifyVault Smart Contract Deployment - PowerShell Guide
## Complete Setup and Deployment Instructions

---

## 📋 Pre-Deployment Checklist

- [ ] Node.js installed (v14+)
- [ ] PowerShell 7+ or Windows PowerShell
- [ ] MetaMask or other wallet
- [ ] Testnet ETH for gas fees
- [ ] Infura/Alchemy API key
- [ ] Private key safely stored

---

## Part 1: Environment Setup

### Step 1: Create Project Directory

```powershell
# Open PowerShell as Administrator

# Create project folder
New-Item -ItemType Directory -Name "verifyvault-contracts" -Force
cd verifyvault-contracts

# Verify location
Get-Location
```

### Step 2: Initialize Node Project

```powershell
# Initialize npm project
npm init -y

# Should see: package.json created
```

### Step 3: Install Dependencies

```powershell
# Install Hardhat
npm install --save-dev hardhat

# Install Hardhat plugins
npm install --save-dev @nomicfoundation/hardhat-toolbox

# Install OpenZeppelin contracts
npm install @openzeppelin/contracts @openzeppelin/contracts-upgradeable

# Install dotenv for environment variables
npm install dotenv

# Install ethers.js (should come with hardhat-toolbox)
npm install ethers

# Install Hardhat verify plugin (optional, for Etherscan)
npm install --save-dev @nomicfoundation/hardhat-verify

# Verify installations
npm list --depth=0
```

### Step 4: Initialize Hardhat Project

```powershell
# Create Hardhat config
npx hardhat

# When prompted, select:
# - "Create a TypeScript project" or "Create a JavaScript project"
# - Add .gitignore? Yes
# - Install sample project dependencies? No

# This creates:
# - hardhat.config.js
# - contracts/ folder
# - test/ folder
# - scripts/ folder
```

---

## Part 2: Configure Hardhat

### Step 1: Create Environment File

```powershell
# Create .env file
New-Item -ItemType File -Name ".env" -Force

# Edit .env with PowerShell
Add-Content -Path ".env" -Value @"
# Network URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
POLYGON_RPC_URL=https://polygon-rpc.com
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc

# Private Keys
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
DEPLOYER_ACCOUNT=0xYOUR_WALLET_ADDRESS_HERE

# Etherscan API Key (for verification)
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# Other configuration
GAS_PRICE=50000000000
GAS_LIMIT=8000000
"@
```

### Step 2: Update hardhat.config.js

```powershell
# Edit hardhat.config.js
# Replace entire content with this:
```

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL;
const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL;
const ARBITRUM_RPC_URL = process.env.ARBITRUM_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 1,
    },
    polygon: {
      url: POLYGON_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 137,
    },
    arbitrum: {
      url: ARBITRUM_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 42161,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: "YOUR_COINMARKETCAP_API_KEY", // Optional
  },
};
```

---

## Part 3: Add Smart Contracts

### Step 1: Create Contract Directory

```powershell
# Create contracts folder if not exists
New-Item -ItemType Directory -Name "contracts" -Force

# List contracts
Get-ChildItem contracts/
```

### Step 2: Add Your Smart Contracts

Create your contract files:

```powershell
# Create main HOC contract
New-Item -ItemType File -Name "contracts/VerifyVaultHOC.sol"

# Create token contract
New-Item -ItemType File -Name "contracts/VerifyVaultToken.sol"

# Create marketplace contract
New-Item -ItemType File -Name "contracts/VerifyVaultMarketplace.sol"
```

### Example VerifyVaultHOC.sol

```powershell
# Add content to contract
Add-Content -Path "contracts/VerifyVaultHOC.sol" -Value @"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract VerifyVaultHOC is ERC721, Ownable, Pausable {
    uint256 private _tokenIdCounter;
    
    mapping(uint256 => string) private _cardMetadata;
    mapping(uint256 => uint256) private _cardValue;
    
    event CardTokenized(uint256 indexed tokenId, string metadata, uint256 value);
    event CardValueUpdated(uint256 indexed tokenId, uint256 newValue);
    
    constructor() ERC721("VerifyVault HOC", "VHOC") {}
    
    function tokenizeCard(
        address to,
        string memory metadata,
        uint256 value
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        _cardMetadata[tokenId] = metadata;
        _cardValue[tokenId] = value;
        
        emit CardTokenized(tokenId, metadata, value);
        return tokenId;
    }
    
    function updateCardValue(uint256 tokenId, uint256 newValue) 
        public 
        onlyOwner 
    {
        _cardValue[tokenId] = newValue;
        emit CardValueUpdated(tokenId, newValue);
    }
    
    function getCardValue(uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return _cardValue[tokenId];
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
}
"@
```

---

## Part 4: Compile Contracts

### Step 1: Compile

```powershell
# Compile contracts
npx hardhat compile

# You should see:
# Compiling 1 file with 0.8.29
# Successfully compiled 1 Solidity file
```

### Step 2: Check for Errors

```powershell
# If errors, view them
npx hardhat compile 2>&1 | Tee-Object -FilePath "compile-log.txt"

# View compile log
Get-Content compile-log.txt
```

---

## Part 5: Create Deployment Script

### Step 1: Create Deploy Script

```powershell
# Create deployment script
New-Item -ItemType File -Name "scripts/deploy.js"
```

### Step 2: Add Deployment Code

```powershell
Add-Content -Path "scripts/deploy.js" -Value @"
const hre = require("hardhat");

async function main() {
    console.log("Starting deployment...");
    
    // Get deployer account
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    
    // Get account balance
    const balance = await deployer.getBalance();
    console.log("Account balance:", hre.ethers.utils.formatEther(balance), "ETH");
    
    // Deploy VerifyVaultHOC
    console.log("\nDeploying VerifyVaultHOC...");
    const VerifyVaultHOC = await hre.ethers.getContractFactory("VerifyVaultHOC");
    const hocContract = await VerifyVaultHOC.deploy();
    await hocContract.deployed();
    
    console.log("VerifyVaultHOC deployed to:", hocContract.address);
    
    // Save deployment info
    const deploymentInfo = {
        network: hre.network.name,
        deployer: deployer.address,
        VerifyVaultHOC: hocContract.address,
        deploymentTime: new Date().toISOString(),
        blockNumber: await hre.ethers.provider.getBlockNumber()
    };
    
    // Write to file
    const fs = require("fs");
    fs.writeFileSync(
        "deployments.json",
        JSON.stringify(deploymentInfo, null, 2)
    );
    
    console.log("\nDeployment Info:");
    console.log(JSON.stringify(deploymentInfo, null, 2));
    
    return deploymentInfo;
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
"@
```

---

## Part 6: Deploy to Testnet

### Step 1: Get Testnet ETH

```powershell
# Get Sepolia testnet ETH from faucet
# Visit: https://sepoliafaucet.com
# Or: https://www.infura.io/faucet/sepolia

Write-Host "Go to faucet and request testnet ETH for your wallet address"
Read-Host "Press Enter after receiving ETH"
```

### Step 2: Deploy to Sepolia

```powershell
# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia

# Expected output:
# Starting deployment...
# Deploying with account: 0x...
# Account balance: X.XXX ETH
# 
# Deploying VerifyVaultHOC...
# VerifyVaultHOC deployed to: 0x...
```

### Step 3: Verify Deployment

```powershell
# Check deployment
Get-Content deployments.json | ConvertFrom-Json

# Should show contract addresses
```

---

## Part 7: Verify Contract on Etherscan

### Step 1: Update hardhat.config.js

Already done in Step 2 of Part 2 (includes etherscan configuration)

### Step 2: Verify Contract

```powershell
# Verify on Etherscan
npx hardhat verify --network sepolia [CONTRACT_ADDRESS]

# Example:
# npx hardhat verify --network sepolia 0x1234567890123456789012345678901234567890

# Expected output:
# Successfully verified contract on the block explorer.
```

### Step 3: View on Etherscan

```powershell
# Contract address format
Write-Host "View contract at: https://sepolia.etherscan.io/address/[CONTRACT_ADDRESS]"

# Replace [CONTRACT_ADDRESS] with your actual address
```

---

## Part 8: Deploy to Mainnet

### ⚠️ WARNING: Use Real ETH!

```powershell
# Update .env with MAINNET_RPC_URL and PRIVATE_KEY
# Make sure you have ETH for gas fees

# Deploy to Mainnet
npx hardhat run scripts/deploy.js --network mainnet

# This costs REAL money - double check everything!
```

---

## Part 9: Testing (Before Mainnet)

### Step 1: Create Test File

```powershell
New-Item -ItemType File -Name "test/VerifyVaultHOC.test.js"
```

### Step 2: Add Tests

```powershell
Add-Content -Path "test/VerifyVaultHOC.test.js" -Value @"
const { expect } = require("chai");

describe("VerifyVaultHOC", function () {
    let hoc;
    let owner, addr1;
    
    beforeEach(async function () {
        const VerifyVaultHOC = await ethers.getContractFactory("VerifyVaultHOC");
        hoc = await VerifyVaultHOC.deploy();
        [owner, addr1] = await ethers.getSigners();
    });
    
    it("Should tokenize a card", async function () {
        const tx = await hoc.tokenizeCard(
            owner.address,
            "Josh Allen PSA 8",
            ethers.utils.parseEther("100")
        );
        
        expect(tx).to.emit(hoc, "CardTokenized");
    });
    
    it("Should get card value", async function () {
        await hoc.tokenizeCard(
            owner.address,
            "Test Card",
            ethers.utils.parseEther("50")
        );
        
        const value = await hoc.getCardValue(0);
        expect(value).to.equal(ethers.utils.parseEther("50"));
    });
});
"@
```

### Step 3: Run Tests

```powershell
# Run tests on local hardhat network
npx hardhat test

# Expected output:
# VerifyVaultHOC
#   ✓ Should tokenize a card
#   ✓ Should get card value
# 
# 2 passing
```

---

## Part 10: Complete Deployment Checklist

```powershell
# Create deployment checklist
Add-Content -Path "DEPLOYMENT_CHECKLIST.md" -Value @"
# Deployment Checklist

## Pre-Deployment
- [ ] Node.js installed
- [ ] All dependencies installed (npm list)
- [ ] .env file created with all keys
- [ ] Private key loaded safely
- [ ] Contracts compile without errors (npx hardhat compile)
- [ ] Tests pass (npx hardhat test)

## Testnet Deployment (Sepolia)
- [ ] Have testnet ETH from faucet
- [ ] Deployment script created and tested
- [ ] Deploy to Sepolia (npx hardhat run scripts/deploy.js --network sepolia)
- [ ] Verify contract on Etherscan
- [ ] Test contract functions on Sepolia
- [ ] Document contract addresses

## Mainnet Deployment
- [ ] Review all code one final time
- [ ] Have mainnet ETH for gas
- [ ] Gas price is acceptable
- [ ] All testnet functionality verified
- [ ] Deploy to mainnet (npx hardhat run scripts/deploy.js --network mainnet)
- [ ] Verify contract on Etherscan
- [ ] Monitor first transactions

## Post-Deployment
- [ ] Update documentation with contract addresses
- [ ] Communicate deployment to team
- [ ] Monitor contract for issues
- [ ] Update frontend with contract addresses
"@

# Display checklist
Get-Content DEPLOYMENT_CHECKLIST.md
```

---

## Part 11: Useful PowerShell Commands

### Check Network Status

```powershell
# Check Sepolia network
npx hardhat run -e "
  const provider = ethers.getDefaultProvider('sepolia');
  provider.getBlockNumber().then(block => {
    console.log('Latest block:', block);
  });
" --network sepolia
```

### Get Account Balance

```powershell
# Check balance on Sepolia
npx hardhat run -e "
  const [signer] = await ethers.getSigners();
  const balance = await signer.getBalance();
  console.log('Balance:', ethers.utils.formatEther(balance), 'ETH');
" --network sepolia
```

### Interact with Deployed Contract

```powershell
# Create interaction script
Add-Content -Path "scripts/interact.js" -Value @"
const hre = require("hardhat");

async function main() {
    // Load deployment info
    const deployments = require("../deployments.json");
    const contractAddress = deployments.VerifyVaultHOC;
    
    // Connect to contract
    const hoc = await hre.ethers.getContractAt(
        "VerifyVaultHOC",
        contractAddress
    );
    
    // Interact with contract
    const tx = await hoc.tokenizeCard(
        "0x1234567890123456789012345678901234567890",
        "Josh Allen #304",
        hre.ethers.utils.parseEther("167")
    );
    
    console.log("Transaction:", tx.hash);
    const receipt = await tx.wait();
    console.log("Confirmed!");
}

main().catch(console.error);
"@

# Run interaction script
npx hardhat run scripts/interact.js --network sepolia
```

---

## Part 12: Network Configuration Reference

### Sepolia Testnet
```powershell
# Network: Sepolia
# Chain ID: 11155111
# RPC: https://sepolia.infura.io/v3/YOUR_PROJECT_ID
# Faucet: https://sepoliafaucet.com
# Explorer: https://sepolia.etherscan.io
```

### Mainnet
```powershell
# Network: Ethereum Mainnet
# Chain ID: 1
# RPC: https://mainnet.infura.io/v3/YOUR_PROJECT_ID
# Explorer: https://etherscan.io
# ⚠️ REAL MONEY - Be careful!
```

### Polygon
```powershell
# Network: Polygon
# Chain ID: 137
# RPC: https://polygon-rpc.com
# Explorer: https://polygonscan.com
# Faucet: https://faucet.polygon.technology
```

### Arbitrum
```powershell
# Network: Arbitrum One
# Chain ID: 42161
# RPC: https://arb1.arbitrum.io/rpc
# Explorer: https://arbiscan.io
# Faucet: https://faucet.arbitrum.io
```

---

## Complete PowerShell Deployment Script

```powershell
# Save as: deploy-all.ps1

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("sepolia", "mainnet", "polygon", "arbitrum")]
    [string]$Network,
    
    [switch]$Verify,
    [switch]$Test
)

Write-Host "╔════════════════════════════════════════╗"
Write-Host "║  VerifyVault Contract Deployment      ║"
Write-Host "║  Network: $Network"
Write-Host "╚════════════════════════════════════════╝"

# Step 1: Run tests if requested
if ($Test) {
    Write-Host "`n[1/4] Running tests..." -ForegroundColor Green
    npx hardhat test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Tests failed! Aborting deployment." -ForegroundColor Red
        exit 1
    }
}

# Step 2: Compile contracts
Write-Host "`n[2/4] Compiling contracts..." -ForegroundColor Green
npx hardhat compile
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed! Aborting deployment." -ForegroundColor Red
    exit 1
}

# Step 3: Deploy
Write-Host "`n[3/4] Deploying to $Network..." -ForegroundColor Green
npx hardhat run scripts/deploy.js --network $Network
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Verify (if requested)
if ($Verify) {
    Write-Host "`n[4/4] Verifying contracts..." -ForegroundColor Green
    $deployments = Get-Content deployments.json | ConvertFrom-Json
    npx hardhat verify --network $Network $deployments.VerifyVaultHOC
}

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Get-Content deployments.json | ConvertFrom-Json | Format-Table
```

### Usage:

```powershell
# Deploy to Sepolia with tests and verification
.\deploy-all.ps1 -Network sepolia -Test -Verify

# Deploy to Mainnet (no tests)
.\deploy-all.ps1 -Network mainnet

# Just deploy to Polygon
.\deploy-all.ps1 -Network polygon
```

---

## Troubleshooting

### Issue: "Private Key not found"

```powershell
# Check .env file
Get-Content .env

# Verify PRIVATE_KEY is set:
# Should show: PRIVATE_KEY=0x...

# If missing:
Add-Content -Path ".env" -Value "PRIVATE_KEY=0xyourprivatekeyhere"
```

### Issue: "Insufficient funds for gas"

```powershell
# Check balance
npx hardhat run -e "
  const [signer] = await ethers.getSigners();
  const balance = await signer.getBalance();
  console.log('ETH Balance:', ethers.utils.formatEther(balance));
" --network sepolia

# Get more testnet ETH from faucet
# https://sepoliafaucet.com
```

### Issue: "Contract already exists at that address"

```powershell
# Clear artifacts and recompile
Remove-Item -Path "artifacts" -Recurse -Force
Remove-Item -Path "cache" -Recurse -Force
npx hardhat compile
```

---

## Summary

**Your deployment process:**

1. ✅ Environment setup (Part 1-2)
2. ✅ Add smart contracts (Part 3)
3. ✅ Compile (Part 4)
4. ✅ Create deploy script (Part 5)
5. ✅ Test on localhost
6. ✅ Deploy to Sepolia testnet (Part 6)
7. ✅ Verify on Etherscan (Part 7)
8. ✅ Deploy to Mainnet (Part 8)

**You're ready to deploy!** 🚀

