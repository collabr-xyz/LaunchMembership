# LaunchMembership Smart Contract

A smart contract for creating and managing membership NFTs for clubs or communities, with payment in $GROW tokens.

## Features

- Membership NFTs with ERC-721 standard
- Payment in $GROW tokens (ERC-20)
- Role-based permissions (Admin, Moderator)
- Configurable membership limit and price
- Customizable club information

## Prerequisites

- Node.js and npm
- thirdweb CLI
- $GROW token contract address

## Setup

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

## Configuration

Before deploying, you'll need:
- Your $GROW token contract address
- Club details (name, description, image URI)
- Membership parameters (limit, price)
- NFT details (name, symbol)

## Deployment with thirdweb

Deploy the contract using thirdweb CLI:

```bash
npx thirdweb deploy
```

During the deployment process with thirdweb, you'll need to provide the constructor parameters:
- Club name, description, and image URI
- Membership limit and price
- NFT name and symbol
- $GROW token contract address

> [!IMPORTANT]
> This requires a secret key to make it work. Get your secret key [here](https://thirdweb.com/dashboard/settings/api-keys).
> Pass your secret key as a value after `-k` flag.
> ```bash
> npm run deploy -- -k <your-secret-key>
> # or
> yarn deploy -k <your-secret-key>

## Contract Interaction

### For Club Owners/Admins

1. **Update Club Information**:
```solidity
function updateClubInfo(string memory _newName, string memory _newDescription, string memory _newImageURI) external
```

2. **Update Membership Price**:
```solidity
function updateMembershipPrice(uint256 _newPrice) external
```

3. **Update Membership Limit**:
```solidity
function updateMembershipLimit(uint256 _newLimit) external
```

4. **Manage Moderators**:
```solidity
function addModerator(address _moderator) external
function removeModerator(address _moderator) external
```

5. **Withdraw Tokens**:
```solidity
function withdrawTokens() external
```

### For Users

1. **Purchase Membership**:
   - First, approve the LaunchMembership contract to spend your $GROW tokens:
   ```solidity
   // On the $GROW token contract
   function approve(address spender, uint256 amount) external returns (bool)
   ```
   - Then purchase the membership:
   ```solidity
   function purchaseMembership() external returns (uint256)
   ```

2. **Check Membership Status**:
```solidity
function isMember(address _address) public view returns (bool)
```

## Important Notes

1. Users must approve the contract to spend their $GROW tokens before purchasing a membership.
2. The contract owner should set the correct $GROW token address during deployment.
3. The membership price should be specified in the smallest unit of the token (e.g., wei for tokens with 18 decimals).

## License

MIT

## Getting Started

Create a project using this example:

```bash
npx thirdweb create --contract --template hardhat-javascript-starter
```

You can start editing the page by modifying `contracts/Contract.sol`.

To add functionality to your contracts, you can use the `@thirdweb-dev/contracts` package which provides base contracts and extensions to inherit. The package is already installed with this project. Head to our [Contracts Extensions Docs](https://portal.thirdweb.com/contractkit) to learn more.

## Building the project

After any changes to the contract, run:

```bash
npm run build
# or
yarn build
```

to compile your contracts. This will also detect the [Contracts Extensions Docs](https://portal.thirdweb.com/contractkit) detected on your contract.

## Releasing Contracts

If you want to release a version of your contracts publicly, you can use one of the followings command:

```bash
npm run release
# or
yarn release
```

## Join our Discord!

For any questions, suggestions, join our discord at [https://discord.gg/thirdweb](https://discord.gg/thirdweb).
