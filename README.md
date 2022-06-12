# Flower Poker Contract

A Smart contract implentation of the game https://runelive.fandom.com/wiki/Flower_Poker using chainlink verifiable random functions. This ensures provably fair flower-pokering, powered by the blockchain!

## ABI For UI
ABI will be output to `./ABI` upon build.

```
  function createMatch(uint256) payable returns (uint256)
```
- Creates a new flower poker offer, with value equal to the deposit amount
- Emits event `offerPosted(matchId, amount)` 

```
    function createHouseMatch(uint256) payable returns (uint256)
```
- Creates a new flower poker offer against the house, with value equal to the deposit amount
- Calls chainlink VRF, awaits callback to determin winner and payout
- Emits event `FlowersPlanted(chainlinkVRFRequestId, matchId)` 

```
  function acceptMatch(uint256) payable
```
- Accepts an existing offer that is in the 'READY' state, must depost value equal to offer sum
- Calls chaillink VRF, awaits callback to determin winner and payout
- Emits event `FlowersPlanted(chainlinkVRFRequestId, matchId)` 

```
  function matches(uint256) view returns (uint256, uint256, address, address, uint8, uint8, uint8)
```
- Returns an match at a specific index
```
   struct Match {
        uint256 id;
        uint256 sum;
        address player1;
        address player2;
        uint8[5] player1draws;
        uint8[5] player2draws;
        MatchResult player1Result;
        MatchResult player2Result;
        MatchState state;
    }
```

## Building & Deploying

Requires `./secrets.ts` file. Deploying will require chaning contract to your own Chainlink information. See https://docs.chain.link/docs/chainlink-vrf/example-contracts/ for more information.

```
export default {
  rpc: 'https://polygon-rpc.com',
  account: 'ETH / POLYGON PRIVATE KEY',
};
```

Deployment to test network:
```shell
npx hardhat node &
npx hardhat run scripts/deploy.ts --network hardhat
```

Deployment to ploygon network:
```shell
npx hardhat run scripts/deploy.ts --network polygon
```

The ABI will be output to `./ABI`,
typescript types output to `./typechain-types`

