/* eslint-disable require-jsdoc */
import {ethers} from 'hardhat';

async function main() {
  const fpFactory = await ethers.getContractFactory('FlowerPoker');
  const fp = await fpFactory.deploy();

  await fp.deployed();

  console.log('Flower Poker contract deployed to:', fp.address);
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
