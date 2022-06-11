/* eslint-disable require-jsdoc */
import {ethers} from 'hardhat';

async function main() {
  const bet = await ethers.getContractAt('Bet',
      '0x1f7c55A6C8B08A1Bc677C8a585c9a60ec613E4bC');
  await bet.deployed();

  // const offer = await bet.makeOffer(100, {value: 100});

  const acc = await bet.acceptOffer(2, {value: 100, gasLimit: 100000});
  await acc.wait();
  console.log('acc data:', acc);
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
