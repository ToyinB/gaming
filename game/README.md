# Gaming Asset Smart Contract

A Clarity smart contract for managing in-game digital assets with trading functionality and marketplace features. This contract enables the creation, ownership management, and trading of gaming assets on the Stacks blockchain.

## Features

- Asset Creation and Management
- Ownership Tracking
- Asset Marketplace
- Asset Trading System
- Configurable Platform Fees
- Administrative Controls

## Contract Overview

### Asset Properties
- Unique Asset ID
- Owner Information
- Metadata Storage
- Creation Timestamp
- Transferability Flag
- Marketplace Integration

### Core Functionality

#### Asset Management
- Create new gaming assets
- Transfer assets between users
- Track asset ownership
- Manage asset metadata

#### Marketplace Features
- List assets for sale
- Unlist assets from marketplace
- Purchase listed assets
- Automated fee handling

## Function Reference

### Read-Only Functions

1. `get-asset (asset-id uint)`
   - Returns the complete information for a specific asset
   - Returns `none` if asset doesn't exist

2. `get-listing (asset-id uint)`
   - Returns marketplace listing information for an asset
   - Returns `none` if asset isn't listed

3. `get-user-assets (user principal)`
   - Returns the number of assets owned by a user
   - Default return is `{ asset-count: u0 }`

4. `get-owner (asset-id uint)`
   - Returns the current owner of an asset
   - Returns error if asset doesn't exist

### Public Functions

1. `create-asset (metadata (string-ascii 256)) (transferable bool)`
   - Creates a new asset with specified metadata
   - Sets initial owner as transaction sender
   - Returns: asset ID on success, error on failure

2. `transfer-asset (asset-id uint) (recipient principal)`
   - Transfers asset ownership to new recipient
   - Requirements:
     - Sender must be current owner
     - Asset must be transferable
     - Recipient cannot be sender

3. `list-asset (asset-id uint) (price uint)`
   - Lists asset on marketplace
   - Requirements:
     - Sender must be asset owner
     - Price must be greater than 0
     - Asset must not be already listed

4. `unlist-asset (asset-id uint)`
   - Removes asset listing from marketplace
   - Only asset seller can unlist

5. `buy-asset (asset-id uint)`
   - Purchases asset from marketplace
   - Automatically handles:
     - STX transfer to seller
     - Platform fee collection
     - Ownership transfer
     - Listing removal

### Administrative Functions

1. `set-platform-fee (new-fee uint)`
   - Updates platform fee percentage (in basis points)
   - Only callable by contract owner
   - Maximum fee: 100% (1000 basis points)

2. `transfer-ownership (new-owner principal)`
   - Transfers contract ownership
   - Only callable by current owner

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized action attempt
- `ERR-ASSET-NOT-FOUND (u101)`: Asset doesn't exist
- `ERR-INSUFFICIENT-BALANCE (u102)`: Insufficient funds for purchase
- `ERR-INVALID-PRICE (u103)`: Invalid price specified
- `ERR-ALREADY-LISTED (u104)`: Asset already listed
- `ERR-NOT-LISTED (u105)`: Asset not listed on marketplace
- `ERR-INVALID-PARAMS (u106)`: Invalid parameter values
- `ERR-SELF-TRANSFER (u107)`: Attempted transfer to self
- `ERR-INVALID-METADATA (u108)`: Invalid metadata format/length

## Platform Fees

- Default fee: 2.5% (25 basis points)
- Fees are collected in STX
- Fees are automatically transferred to contract owner
- Configurable by contract owner

## Security Features

- Ownership validation
- Transfer restrictions
- Input validation
- Self-transfer prevention
- Metadata length restrictions
- Administrative access controls

## Usage Examples

### Creating an Asset
```clarity
(contract-call? .gaming-asset-contract create-asset "Legendary Sword #1" true)
```

### Listing an Asset
```clarity
(contract-call? .gaming-asset-contract list-asset u1 u1000000) ;; List for 1 STX
```

### Purchasing an Asset
```clarity
(contract-call? .gaming-asset-contract buy-asset u1)
```

## Implementation Notes

- Metadata is limited to 256 ASCII characters
- Assets can be marked as non-transferable during creation
- Platform fees are calculated in basis points (1/100 of a percent)
- Contract maintains internal counters for asset IDs
- All monetary values are in STX

## Security Considerations

1. Always verify ownership before operations
2. Validate all input parameters
3. Check asset transferability before transfers
4. Ensure sufficient STX balance for purchases
5. Verify marketplace listing status
6. Administrative functions are protected
