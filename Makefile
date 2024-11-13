-include .env

.PHONY: all test deploy fund withdraw clean help anvil install format verify-deployment interact coverage coverage-report

help:
	@echo "Usage:"
	@echo "  Network Commands:"
	@echo "    make anvil                    - Run local Anvil chain"
	@echo "    make verify-deployment        - Get deployed FundMe address"
	@echo ""
	@echo "  Build & Test Commands:"
	@echo "    make build                    - Build the project"
	@echo "    make test                     - Run all tests"
	@echo "    make test-unit               - Run unit tests"
	@echo "    make test-integration        - Run integration tests"
	@echo "    make coverage                - Run test coverage for all tests"
	@echo "    make coverage-report         - Generate detailed HTML coverage report"
	@echo "    make format                   - Format code"
	@echo ""
	@echo "  Deployment Commands:"
	@echo "    make deploy-anvil            - Deploy to Anvil"
	@echo "    make deploy-sepolia          - Deploy to Sepolia"
	@echo ""
	@echo "  Interaction Commands:"
	@echo "    make fund                     - Fund the contract"
	@echo "    make withdraw                 - Withdraw from contract"
	@echo "    make check-balance           - Check contract balance"

# Network Commands
anvil :
	@echo "Starting Anvil local chain..."
	@anvil

# Build Commands
build:
	@echo "Building contracts..."
	@forge build

clean:
	@echo "Cleaning build files..."
	@forge clean

format:
	@echo "Formatting code..."
	@forge fmt

# Test Commands
test:
	@echo "Running all tests..."
	@forge test

test-unit:
	@echo "Running unit tests..."
	@forge test --match-path test/unit/** -vvv

test-integration:
	@echo "Running integration tests..."
	@forge test --match-path test/integration/** -vvv

# Coverage Commands
coverage:
	@echo "Running test coverage for all tests..."
	@forge coverage

coverage-detailed:
	@echo "Running test coverage for all tests..."
	@forge coverage --report debug

coverage-report:
	@echo "Generating detailed HTML coverage report..."
	@forge coverage --report lcov
	@genhtml lcov.info --output-directory coverage

# Deployment Commands
deploy-anvil:
	@echo "Deploying to Anvil..."
	@forge script script/DeployFundMe.s.sol:DeployFundMe \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--password $(PASSWORD) \
		--broadcast -vvvv

deploy-sepolia:
	@echo "🚀 Deploying to Sepolia..."
	@forge script script/DeployFundMe.s.sol:DeployFundMe \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account $(SEPOLIA_ACCOUNT) \
		--password $(PASSWORD) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv

# Interaction Commands
fund:
	@echo "Funding contract..."
	@forge script script/Interactions.s.sol:FundFundMe \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--password $(PASSWORD) \
		--broadcast -vvvv

withdraw:
	@echo "Withdrawing from contract..."
	@forge script script/Interactions.s.sol:WithdrawFundMe \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--password $(PASSWORD) \
		--broadcast -vvvv

# Utility Commands
verify-deployment:
	@echo "Verifying deployment..."
	@cast call $(FUNDME_ADDRESS) "i_owner()(address)" --rpc-url $(RPC_URL)

check-balance:
	@echo "Checking contract balance..."
	@cast balance $(FUNDME_ADDRESS) --rpc-url $(RPC_URL)
	@echo "Checking your funded amount..."
	@cast call $(FUNDME_ADDRESS) "getAddressToAmountFunded(address)(uint256)" $(SENDER) --rpc-url $(RPC_URL)

install:
	@echo "Installing dependencies..."
	@forge install Cyfrin/foundry-devops@0.0.11 --no-commit
	@forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
	@forge install foundry-rs/forge-std@v1.5.3 --no-commit