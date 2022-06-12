import {task} from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-abi-exporter';
import * as secrets from './secrets';

task('accounts', 'Prints the list of accounts', async (args, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(await account.address);
  }
});

module.exports = {
  solidity: '0.8.4',
  networks: {
    hardhat: {},
    polygon: {
      url: secrets.default.rpc,
      accounts: [
        secrets.default.account,
      ],
    },
  },
  abiExporter: [
    {
      runOnCompile: true,
      clear: false,
      flat: false,
      path: './abi/',
      pretty: false,
    },
  ],
};
