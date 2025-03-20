# ZKsync Smart Contracts

This repository contains the Open Ticketing Ecosystem's core smart contracts adapted for ZKsync.

## Repository Contents

- `/contracts`: Contains the solidity smart contracts for the ticketing suite.

## Environment Setup

### Prerequisites

- Node.js and bun installed
- Docker installed (for local development)

### Setup Steps

1. Clone the repository

2. Install dependencies:
```
bun install
```

3. Set up environment variables:
   - Rename `.env.example` to `.env` 
   - Add your private key:
   ```
   WALLET_PRIVATE_KEY=your_private_key_here...
   ```

### Local Development Environment

To set up a local ZKsync development environment:

1. Start Docker:
```
docker compose up -d
```

2. Start ZKSync Local Node:
```
yarn zksync-cli dev start
```

## Compiling Contracts

To compile the contracts:

```
yarn compile
```

## Network Configuration

The project supports multiple networks for contract deployment. Network configurations are specified in `hardhat.config.ts`. You can add more networks by adjusting the `networks` section in this file.

## Useful Links

- [ZKsync Docs](https://docs.zksync.io/build)
- [ZKsync Official Site](https://zksync.io/)
- [ZKsync GitHub](https://github.com/matter-labs)
- [ZKsync Twitter](https://twitter.com/zksync)
- [ZKsync Discord](https://join.zksync.dev/)

## License

This project is under the [MIT](./LICENSE) license.