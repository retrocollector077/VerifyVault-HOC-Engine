const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

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

  // Deploy BTBBZFractionalVault
  const Vault = await ethers.getContractFactory("BTBBZFractionalVault");
  const vault = await Vault.deploy(wbtbbz.address, nft.address);
  await vault.deployed();
  console.log("BTBBZFractionalVault deployed to:", vault.address);

  // Mint all 420 NFTs using uploaded_cids.json
  const cidMap = JSON.parse(fs.readFileSync("uploaded_cids.json"));
  const tokenURIs = Object.keys(cidMap)
    .sort((a, b) => parseInt(a) - parseInt(b))
    .map(name => `ipfs://${cidMap[name]}`);

  for (let i = 0; i < tokenURIs.length; i++) {
    const uri = tokenURIs[i];
    const tx = await nft.mint(deployer.address, uri);
    await tx.wait();
    console.log(`Minted token #${i + 1} → ${uri}`);
  }

  console.log("All NFTs minted and contracts deployed.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});