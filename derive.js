const { ethers } = require('ethers');

// Your private key
const privateKey = '35501ee6920610b1b2f395bab96abbcea3e1eeb6ff927729ab0d435b51ef0';

// Derive the wallet address
const wallet = new ethers.Wallet(privateKey);
const walletAddress = wallet.address;

console.log(`Ethereum Wallet Address: ${walletAddress}`);
