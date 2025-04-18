# Project Configuration
PROJECT_NAME := ERC20-side-project
SRC_DIR := src
SCRIPT_DIR := script
TEST_DIR := test
BUILD_DIR := out
ENV_FILE := .env

# Foundry Configuration
FOUNDRY := forge
SOLC_VERSION := 0.8.20
RPC_URL = $(TESTNET_RPC_URL)
ACCOUNT = $(ACCOUNT)
ETHERSCAN_API_KEY = $(ETHERSCAN_API_KEY)

# Load environment variables from .env file
include $(ENV_FILE)
export $(shell grep -v '^#' .env | xargs)

# Default Target
.PHONY: all
all: build

# Install dependencies
.PHONY: install
install:
	@echo "Installing dependencies..."
	$(FOUNDRY) install OpenZeppelin/openzeppelin-contracts --no-commit

# Build the project
.PHONY: build
build:
	@echo "Building the project..."
	$(FOUNDRY) build

# Clean the build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

# Run tests
.PHONY: test
test:
	@echo "Running tests..."
	$(FOUNDRY) test

# Run a specific test file
.PHONY: test-unit
test-unit:
	@echo "Running a specific test file..."
	$(FOUNDRY) test --match-path $(TEST_DIR)/unit/TestMyTokenVesting.t.sol

.PHONY: test-integration
test-integration:
	@echo "Running integration tests..."
	$(FOUNDRY) test --match-path $(TEST_DIR)/Integration/InteractionsTest.t.sol

# Deploy contracts on a testnet
.PHONY: deploy-testnet
deploy-testnet:
	@echo "Deploying contracts on testnet..."
	$(FOUNDRY) script $(SCRIPT_DIR)/DeployMyTokenVesting.s.sol:DeployMyTokenVesting --rpc-url $(RPC_URL) --account $(ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# Format Solidity code
.PHONY: fmt
fmt:
	@echo "Formatting Solidity code..."
	$(FOUNDRY) fmt

# Run static analysis
.PHONY: analyze
analyze:
	@echo "Running static analysis..."
	slint $(SRC_DIR)

# Run gas snapshot
.PHONY: snapshot
snapshot:
	@echo "Running gas snapshot..."
	$(FOUNDRY) snapshot

# Help menu
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make build        - Build the project"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make test         - Run all tests"
	@echo "  make test-file    - Run a specific test file"
	@echo "  make deploy       - Deploy contracts"
	@echo "  make fmt          - Format Solidity code"
	@echo "  make analyze      - Run static analysis"
	@echo "  make snapshot     - Run gas snapshot"
	@echo "  make help         - Show this help menu"

.PHONY: print-env
print-env:
	@echo "SEPOLIA_RPC_URL=$(SEPOLIA_RPC_URL)"
	@echo "RPC_URL=$(RPC_URL)"
