# VerifyVault Smart Contract Deployment Automation
# PowerShell Script - Ready to Use
# Save as: deploy-verifyvault.ps1
# Run: .\deploy-verifyvault.ps1 -Network sepolia

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("sepolia", "mainnet", "polygon", "arbitrum", "localhost")]
    [string]$Network = "sepolia",
    
    [switch]$Initialize,
    [switch]$Test,
    [switch]$Verify,
    [switch]$Full
)

# Color function
function Write-Status {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Status = "Info"
    )
    
    $colors = @{
        "Info"    = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error"   = "Red"
    }
    
    Write-Host "► $Message" -ForegroundColor $colors[$Status]
}

# Check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..." "Info"
    
    # Check Node.js
    try {
        $nodeVersion = node --version
        Write-Status "✓ Node.js $nodeVersion installed" "Success"
    } catch {
        Write-Status "✗ Node.js not installed" "Error"
        Write-Status "Download from: https://nodejs.org/" "Warning"
        exit 1
    }
    
    # Check npm
    try {
        $npmVersion = npm --version
        Write-Status "✓ npm $npmVersion installed" "Success"
    } catch {
        Write-Status "✗ npm not installed" "Error"
        exit 1
    }
    
    # Check .env file
    if (-not (Test-Path ".env")) {
        Write-Status "✗ .env file not found" "Warning"
        return $false
    } else {
        Write-Status "✓ .env file exists" "Success"
        return $true
    }
}

# Initialize project
function Initialize-Project {
    Write-Status "Initializing project..." "Info"
    
    # Create project directory
    if (-not (Test-Path "contracts")) {
        Write-Status "Creating project structure..." "Info"
        New-Item -ItemType Directory -Name "contracts" -Force | Out-Null
        New-Item -ItemType Directory -Name "scripts" -Force | Out-Null
        New-Item -ItemType Directory -Name "test" -Force | Out-Null
        Write-Status "✓ Project directories created" "Success"
    }
    
    # Install dependencies
    Write-Status "Installing dependencies..." "Info"
    npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
    npm install @openzeppelin/contracts @openzeppelin/contracts-upgradeable
    npm install dotenv ethers
    npm install --save-dev @nomicfoundation/hardhat-verify
    
    Write-Status "✓ Dependencies installed" "Success"
    
    # Create .env file if doesn't exist
    if (-not (Test-Path ".env")) {
        Write-Status "Creating .env file..." "Info"
        $envContent = @"
# Network RPC URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
POLYGON_RPC_URL=https://polygon-rpc.com
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc

# Your Private Key (⚠️ Keep this secret!)
PRIVATE_KEY=0x

# Wallet Address
DEPLOYER_ACCOUNT=0x

# Etherscan API Key
ETHERSCAN_API_KEY=

# Gas Configuration
GAS_PRICE=50000000000
GAS_LIMIT=8000000
"@
        $envContent | Out-File -FilePath ".env" -Encoding UTF8
        Write-Status "✓ .env file created - UPDATE WITH YOUR KEYS!" "Warning"
        Write-Status "Edit .env file with your private key and API keys" "Warning"
        exit 1
    }
}

# Compile contracts
function Compile-Contracts {
    Write-Status "Compiling smart contracts..." "Info"
    
    npx hardhat compile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓ Contracts compiled successfully" "Success"
        return $true
    } else {
        Write-Status "✗ Compilation failed" "Error"
        return $false
    }
}

# Run tests
function Run-Tests {
    Write-Status "Running tests..." "Info"
    
    npx hardhat test
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓ All tests passed" "Success"
        return $true
    } else {
        Write-Status "✗ Tests failed" "Error"
        return $false
    }
}

# Deploy contracts
function Deploy-Contracts {
    param([string]$Network)
    
    Write-Status "Deploying to $Network..." "Info"
    
    # Show what we're doing
    Write-Host ""
    Write-Status "Network: $Network" "Info"
    
    # Deploy
    npx hardhat run scripts/deploy.js --network $Network
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓ Deployment successful" "Success"
        
        # Show deployment info
        if (Test-Path "deployments.json") {
            Write-Host ""
            Write-Status "Deployment Information:" "Info"
            $deployments = Get-Content deployments.json | ConvertFrom-Json
            $deployments | Format-Table -AutoSize
        }
        
        return $true
    } else {
        Write-Status "✗ Deployment failed" "Error"
        return $false
    }
}

# Verify contracts
function Verify-Contracts {
    param([string]$Network)
    
    if (-not (Test-Path "deployments.json")) {
        Write-Status "✗ No deployment info found" "Error"
        return $false
    }
    
    Write-Status "Verifying contracts on Etherscan..." "Info"
    
    $deployments = Get-Content deployments.json | ConvertFrom-Json
    $contractAddress = $deployments.VerifyVaultHOC
    
    Write-Status "Verifying: $contractAddress" "Info"
    
    npx hardhat verify --network $Network $contractAddress
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓ Contract verified on Etherscan" "Success"
        Write-Status "View at: https://etherscan.io/address/$contractAddress" "Info"
        return $true
    } else {
        Write-Status "✗ Verification failed" "Error"
        return $false
    }
}

# Check balance
function Check-Balance {
    param([string]$Network)
    
    Write-Status "Checking account balance on $Network..." "Info"
    
    $checkScript = @"
const hre = require("hardhat");
async function checkBalance() {
    const [deployer] = await hre.ethers.getSigners();
    const balance = await deployer.getBalance();
    console.log('Address:', deployer.address);
    console.log('Balance:', hre.ethers.utils.formatEther(balance), 'ETH');
}
checkBalance();
"@
    
    $checkScript | npx hardhat run /dev/stdin --network $Network
}

# Main execution
function Main {
    Clear-Host
    
    Write-Host "╔════════════════════════════════════════════╗"
    Write-Host "║     VerifyVault Smart Contract Deploy      ║"
    Write-Host "║          PowerShell Automation             ║"
    Write-Host "╚════════════════════════════════════════════╝"
    Write-Host ""
    
    # Handle -Full flag
    if ($Full) {
        $Initialize = $true
        $Test = $true
        $Verify = $true
    }
    
    # Step 1: Initialize if requested
    if ($Initialize) {
        Initialize-Project
        Write-Host ""
    }
    
    # Step 2: Test prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Status "Please set up your .env file first" "Warning"
        Write-Status "Copy example from deployment guide" "Info"
        exit 1
    }
    Write-Host ""
    
    # Step 3: Check balance
    Write-Host ""
    Check-Balance -Network $Network
    Write-Host ""
    
    # Step 4: Compile
    if (-not (Compile-Contracts)) {
        exit 1
    }
    Write-Host ""
    
    # Step 5: Test if requested
    if ($Test) {
        if (-not (Run-Tests)) {
            Write-Status "Fix test failures before deploying" "Warning"
            exit 1
        }
        Write-Host ""
    }
    
    # Step 6: Deploy
    if (-not (Deploy-Contracts -Network $Network)) {
        exit 1
    }
    Write-Host ""
    
    # Step 7: Verify if requested
    if ($Verify) {
        Verify-Contracts -Network $Network
        Write-Host ""
    }
    
    # Success
    Write-Host "╔════════════════════════════════════════════╗"
    Write-Host "║         ✅ Deployment Complete!            ║"
    Write-Host "╚════════════════════════════════════════════╝"
    Write-Host ""
    Write-Status "Next steps:" "Info"
    Write-Status "1. Check deployments.json for contract addresses" "Info"
    Write-Status "2. Update your frontend with contract addresses" "Info"
    Write-Status "3. Monitor contract on block explorer" "Info"
    Write-Host ""
}

# Run
Main
