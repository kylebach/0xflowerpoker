import {task} from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import * as acc from './account';

task('accounts', 'Prints the list of accounts', async (args, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(await account.address);
  }
});

module.exports = {
  solidity: '0.8.4',
  networks: {
    hardhat: {
      url: 'http://127.0.0.1:8545/',
      accounts: [
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
        '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
      ],
    },
    polygon: {
      url: 'https://polygon-mainnet.g.alchemy.com/v2/uwMkDmxEuiiXnQsqKx9GHbvG7aJoOgEa',
      accounts: [
        acc.default.account,
      ],
    },
  },
};
