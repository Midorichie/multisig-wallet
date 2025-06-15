# Multi-Signature Wallet with Timelock

A secure, multi-signature wallet implementation on the Stacks blockchain with enhanced security features including timelock functionality.

## 🚀 Features

### Core Multi-Sig Functionality
- **Multi-signature transactions**: Require multiple approvals before executing transactions
- **Dynamic signer management**: Add/remove signers with proper authorization
- **Configurable thresholds**: Set required number of signatures
- **Proposal system**: Create, vote on, and execute proposals

### Security Enhancements (Phase 2)
- **Input validation**: All amounts and principals are validated before processing
- **Balance verification**: Ensures sufficient funds before proposal creation and execution
- **Authorization checks**: Only authorized signers can perform critical operations
- **Reentrancy protection**: State changes occur before external calls

### Timelock Integration
- **Time-delayed execution**: Critical operations can be delayed for security
- **Configurable delays**: Set custom delays between 1 day and 1 week
- **Emergency controls**: Cancel queued transactions if needed
- **Authorized operators**: Manage who can queue and execute timelock transactions

## 📁 Project Structure

```
multisig-wallet/
├── contracts/
│   ├── multisig.clar      # Main multi-sig wallet contract
│   ├── utils.clar         # Utility functions and helpers
│   └── timelock.clar      # Timelock contract for delayed execution
├── Clarinet.toml          # Project configuration
└── README.md              # This file
```

## 🔧 Installation & Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- Stacks CLI (optional, for deployment)

### Quick Start

1. **Clone and setup**:
   ```bash
   git clone <your-repo>
   cd multisig-wallet
   clarinet check
   ```

2. **Run tests**:
   ```bash
   clarinet test
   ```

3. **Start development**:
   ```bash
   clarinet console
   ```

## 📋 Usage Examples

### Basic Multi-Sig Operations

#### Create a Proposal
```clarity
;; Create a proposal to send 1000 microSTX to an address
(contract-call? .multisig create-proposal 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX5N1Q1QV25F u1000)
```

#### Vote on a Proposal
```clarity
;; Vote on proposal ID 1
(contract-call? .multisig vote-proposal u1)
```

#### Execute a Proposal
```clarity
;; Execute proposal ID 1 (after enough signatures)
(contract-call? .multisig execute-proposal u1)
```

### Signer Management

#### Add a New Signer
```clarity
(contract-call? .multisig add-signer 'SP2HTBVD3JG9C05J7HBJTHGR0GGW7KX5N1Q1QV25F)
```

#### Remove a Signer
```clarity
(contract-call? .multisig remove-signer 'SP2HTBVD3JG9C05J7HBJTHGR0GGW7KX5N1Q1QV25F)
```

### Timelock Operations

#### Queue a Transaction
```clarity
;; Queue a transaction with 1-day delay
(contract-call? .timelock queue-transaction 
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX5N1Q1QV25F 
  u1000 
  0x 
  u144)
```

#### Execute a Timelock Transaction
```clarity
;; Execute after delay period
(contract-call? .timelock execute-transaction u1)
```

## 🔒 Security Features

### Input Validation
- All amounts must be greater than 0
- Principal addresses are validated
- Sufficient balance checks before operations

### Access Control
- Only authorized signers can create proposals
- Signer-only voting and execution
- Protected signer management functions

### Timelock Protection
- Configurable delays for sensitive operations
- Emergency cancellation capabilities
- Authorized operator management

## 🧪 Testing

The project includes comprehensive tests for:
- Multi-signature functionality
- Security edge cases
- Timelock operations
- Access control mechanisms

Run tests with:
```bash
clarinet test
```

## 📊 Contract Details

### Main Contract (multisig.clar)
- **Functions**: 8 public functions, 4 read-only functions
- **Storage**: Proposals, signers, votes tracking
- **Security**: Input validation, authorization checks

### Utils Contract (utils.clar)
- **Purpose**: Helper functions and validations
- **Functions**: Principal validation, math utilities, time helpers
- **Integration**: Used by main contract for validations

### Timelock Contract (timelock.clar)
- **Purpose**: Time-delayed execution for enhanced security
- **Features**: Queue, execute, cancel operations
- **Delays**: Configurable from 1 day to 1 week

## 🚨 Security Considerations

1. **Test thoroughly**: Always test on devnet/testnet before mainnet
2. **Validate inputs**: The contracts include validation, but always verify
3. **Monitor timelock**: Keep track of queued transactions
4. **Backup signers**: Ensure you don't lose access to signer keys
5. **Regular audits**: Consider professional security audits for production use

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details.

## 🆘 Support

For issues and questions:
- Create an issue in the repository
- Check the Stacks documentation
- Join the Stacks Discord community


