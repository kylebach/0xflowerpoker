/* eslint-disable require-jsdoc */
import {ethers} from 'hardhat';

async function main() {
  const Bet = await ethers.getContractFactory('Bet');
  const bet = await Bet.deploy(false);

  await bet.deployed();

  console.log('Greeter deployed to:', bet.address);
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
