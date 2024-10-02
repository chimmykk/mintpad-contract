const fs = require('fs');
const path = require('path');

async function main() {
    // Adjust the path if the script is in the 'scripts' directory
    const artifactPath = path.join(__dirname, '../artifacts/contracts//MintpadCollectionFactory.sol//MintpadCollectionFactory.json');
    const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
    const bytecode = artifact.bytecode;
    console.log(`Bytecode length: ${bytecode.length / 2} bytes`); // /2 because it's a hex string
}

main();
