const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying from:", deployer.address);

  // Deploy WrappedBTBBZ
  const WrappedBTBBZ = await ethers.getContractFactory("WrappedBTBBZ");
  const wbtbbz = await WrappedBTBBZ.deploy();
  await wbtbbz.deployed();
  console.log("WrappedBTBBZ deployed to:", wbtbbz.address);

  // Deploy VerifyVaultERC721
  const VerifyVault = await ethers.getContractFactory("VerifyVaultERC721");
  const nft = await VerifyVault.deploy();
  await nft.deployed();
  console.log("VerifyVaultERC721 deployed to:", nft.address);

  // Deploy Vault
  const Vault = await ethers.getContractFactory("BTBBZFractionalVault");
  const vault = await Vault.deploy(wbtbbz.address, nft.address);
  await vault.deployed();
  console.log("Vault deployed to:", vault.address);

  // Load token metadata URIs
  const tokensData = JSON.parse(fs.readFileSync("verifyvault_tokenized_cards.json"));

  // Mint NFTs with actual URIs
  for (let i = 0; i < tokensData.length; i++) {
    const { uri } = tokensData[i]; // ensure your JSON has 'uri'
    const tx = await nft.mint(deployer.address, uri);
    await tx.wait();
    console.log(`Minted token #${i + 1} with URI: ${uri}`);
  }

  console.log("Deployment and minting complete.");
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});