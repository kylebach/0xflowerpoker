import {expect} from 'chai';
import {ethers} from 'hardhat';
import {Greeter} from '../typechain-types';

describe('Contract Tests', function() {
  let contract: Greeter;

  this.beforeEach(async function() {
    const factory = await ethers.getContractFactory('Greeter');
    contract = await factory.deploy('Hello, Hardhat!');
    await contract.deployed();
  });

  it('should do something right', async function() {
    const message = await contract.greet();
    expect('Hello, Hardhat!', message);
  });
});
