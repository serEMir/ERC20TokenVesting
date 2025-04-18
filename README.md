# ERC20 Token Vesting Project

This project implements an ERC20 token (`EMirERC20`) and a token vesting contract (`MyTokenVesting`) to manage the gradual release of tokens to beneficiaries. It includes deployment scripts, unit tests, and integration tests to ensure robust functionality.

---

## Table of Contents

- [ERC20 Token Vesting Project](#erc20-token-vesting-project)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Project Structure](#project-structure)
  - [Getting Started](#getting-started)
  - [Usage](#usage)
  - [Contracts](#contracts)
  - [Testing](#testing)
  - [Makefile Commands](#makefile-commands)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)
  - [Contributions](#contributions)

---

## Overview

This project provides a complete implementation of an ERC20 token and a token vesting system. The vesting contract allows token owners to allocate tokens to beneficiaries with customizable vesting schedules, including cliff periods and periodic releases.

---

## Features

- **ERC20 Token (`EMirERC20`):**
  - Mintable and burnable token.
  - Role-based access control using OpenZeppelin's `AccessControl`.

- **Token Vesting Contract (`MyTokenVesting`):**
  - Supports cliff periods, vesting durations, and periodic token releases.
  - Allows revocation of unvested tokens.
  - Emits events for transparency.

- **Deployment and Testing:**
  - Deployment script using Foundry.
  - Comprehensive unit and integration tests.

---

## Project Structure

```plaintext
ERC20-side-project/
├── src/
│   ├── EMirERC20.sol                 # ERC20 token implementation
│   ├── MyTokenVesting.sol            # Token vesting contract
├── script/
│   ├── DeployMyTokenVesting.s.sol    # Deployment script
├── test/
│   ├── unit/
│   │   ├── TestMyTokenVesting.t.sol  # Unit tests for MyTokenVesting
│   ├── Integration/
│   │   ├── InteractionsTest.t.sol    # Integration tests
├── Makefile                          # Build and automation commands
├── foundry.toml                      # Foundry configuration
└── README.md                         # Project documentation
```

---

## Getting Started

**Prerequisites**

- Foundry installed.
- Node.js and npm (optional, for additional tools).
- An Ethereum RPC URL (e.g., from [Alchemy](https://www.alchemy.com/) or [Infura](https://www.infura.io/)).

**Installation**

1. Clone the repository:
   ```bash
   git clone https://github.com/serEMir/ERC20TokenVesting.git
   cd ERC20TokenVesting
   ```
2. Install dependencies:
   ```bash
   make install
   ```
3. Set up environment variables:
   Create a `.env` file in the root directory and add the following:
   ```bash
   TESTNET_RPC_URL=<your-testnet-rpc-url>
   ETHERSCAN_API_KEY=<your-etherscan-api-key>
   ACCOUNT=<your-key-store-account-name>
   ```
   To create an encrypted private-key store use this command:
   ```bash
   cast wallet import <your-account-name> --interactive
   ```
   follow the prompt and make sure to provide a password.

---

## Usage

- **Building the Project**
  To compile the smart contracts:
  ```bash
  make build
  ```

- **Running Tests**
  Run all tests:
  ```bash
  make test
  ```
  
  Run unit tests:
  ```bash
  make test-unit
  ```
  
  Run integration tests:
  ```bash
  make test-integration
  ```

- **Deploying Contracts To a Testnet**
  To deploy the contracts:
  ```bash
  make deploy
  ```
  Ensure your `.env` file is  configured with the correct RPC URL, key-store account and API key.

---

## Contracts

**EMirERC20**

An ERC20 token with the following features:
- **Minting:** Only addresses with the `MINTER_ROLE` can mint tokens.
- **Burning:** Any token holder can burn their tokens.
- **Access Control:** Role-based permission using OpenZeppelin's `AccessControl`.

**MyTokenVesting**

A token vesting contract that allows token owners to allocate tokens to beneficiaries vesting schedules:
- **Cliff Period:** Tokens are locked for a specified duration before vesting begins.
- **Periodic Releases:** Tokens are released in intervals after the cliff period.
- **Revocation:** Unvested tokens can be revoked and returned to the owner.

---

## Testing

The project includes comprehensive unit and integration tests using Foundry's testing framework.

**Unit Tests**
- Located in `TestMyTokenVesting.t.sol`.
- Covers all edge cases for the `MytokenVesting` contract.

**Integration Tests**

- Located in `InteractionsTest.t.sol`.
- Tests interactions between `EMirERC20` and `MyTokenVesting`.

---

## Makefile Commands

The `Makefile` provides convenient commands for common tasks:
| Command               | Description                              |
|-----------------------|------------------------------------------|
| `make build`          | Build the project                       |
| `make clean`          | Clean build artifacts                   |
| `make test`           | Run all tests                           |
| `make test-unit`      | Run unit tests                          |
| `make test-integration` | Run integration tests                 |
| `make deploy`         | Deploy contracts to a testnet           |
| `make fmt`            | Format Solidity code                    |
| `make analyze`        | Run static analysis                     |
| `make snapshot`       | Run gas snapshot                        |

---

## License

This project is licensed under the MIT License.

---

## Acknowledgments

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) for secure and reusable smart contract components.
- [Foundry](https://github.com/foundry-rs/foundry) for the development and testing framework.

---

## Contributions

contributions to this project is highly appreciated.