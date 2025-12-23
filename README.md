# Forge Contract


Forge is an Ethereum-compatible smart contract implemented in Solidity (^0.8.9) that provides a decentralized, immutable data storage layer for knowledge management. The contract implements a hierarchical data model where Record structs serve as parent entities containing metadata (title, description, ownership, timestamp), and Flashcard structs function as child entities linked via `correspondingRecordId` foreign key relationships. The contract maintains state through dynamic arrays and address-to-array mappings, enabling CRUD operations on both entity types with owner-based access control enforced at the contract level.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Smart Contract API](#smart-contract-api)
- [Testing](#testing)
- [Deployment](#deployment)
- [Project Structure](#project-structure)
- [License](#license)

## Overview

Forge provides a decentralized way to store and manage knowledge records with flashcards. Each record represents a piece of knowledge, and users can attach multiple flashcards (question-answer pairs) to help with learning and retention.

### Key Concepts

- **Records**: Represent pieces of knowledge with a title and description
- **Flashcards**: Question-answer pairs associated with a specific record
- **Ownership**: Each record and flashcard is owned by the address that created it

## Features

- ✅ Create, update, and remove knowledge records
- ✅ Add flashcards to records for learning purposes
- ✅ Update and remove flashcards
- ✅ Query all records from a specific address
- ✅ Query all records (marketplace view)
- ✅ Query all flashcards for a specific record
- ✅ Event emissions for all major operations
- ✅ Access control (only owners can modify their records/flashcards)

## Installation

### Prerequisites

- Node.js (v14 or higher)
- Yarn or npm package manager
- Hardhat development environment

### Setup Steps

1. **Clone the repository** (if applicable) or navigate to the project directory:
   ```bash
   cd forge/Forge-contract
   ```

2. **Install dependencies**:
   ```bash
   yarn install
   # or
   npm install
   ```

3. **Build the project**:
   ```bash
   yarn build
   # or
   npm run build
   ```

## Usage

### Development

To compile the contracts:
```bash
npx hardhat compile
```

To run tests:
```bash
yarn test
# or
npm run test
```

### Deployment

#### Using Thirdweb (Recommended)

1. **Deploy to a network**:
   ```bash
   yarn deploy
   # or
   npm run deploy
   ```

2. **Release the contract**:
   ```bash
   yarn release
   # or
   npm run release
   ```

#### Using Hardhat Scripts

Deploy using the provided script:
```bash
npx hardhat run scripts/deploy.js --network <network-name>
```

### Supported Networks

The project is configured for zkSync networks:

- **zkSync Testnet**: `zksync_testnet`
- **zkSync Mainnet**: `zksync_mainnet`

## 🔧 Smart Contract API

### Records

#### `addRecord(string memory _title, string memory _description)`
Creates a new knowledge record.

**Parameters:**
- `_title`: Title of the record
- `_description`: Description of the record

**Events:**
- `RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId)`

#### `updateRecord(uint256 _recordId, string memory _title, string memory _description)`
Updates an existing record. Only the owner can update.

**Parameters:**
- `_recordId`: ID of the record to update
- `_title`: New title
- `_description`: New description

**Events:**
- `RecordUpdated(address indexed _from, string _oldTitle, string _oldDescription, string _newTitle, string _newDescription, uint256 _timestamp, uint256 _recordId)`

#### `removeRecord(uint256 _recordId)`
Removes a record and all associated flashcards. Only the owner can remove.

**Parameters:**
- `_recordId`: ID of the record to remove

**Events:**
- `RecordRemoved(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId)`

#### `getAllRecordsFromAddress(address _owner)`
Returns all records created by a specific address.

**Returns:** `Record[]` - Array of records

#### `getAllRecords()`
Returns all records in the contract (marketplace view).

**Returns:** `Record[]` - Array of all records

### Flashcards

#### `addFlashcard(uint256 _recordId, string memory _question, string memory _answer)`
Adds a flashcard to a specific record.

**Parameters:**
- `_recordId`: ID of the record to attach the flashcard to
- `_question`: Question text
- `_answer`: Answer text

**Events:**
- `FlashcardAdded(address indexed _from, string _question, string _answer, uint256 _timestamp, uint256 _recordId)`

#### `updateFlashcard(uint256 _flashcardId, string memory _newTitle, string memory _newDesc)`
Updates an existing flashcard. Only the owner can update.

**Parameters:**
- `_flashcardId`: ID of the flashcard to update
- `_newTitle`: New question text
- `_newDesc`: New answer text

**Events:**
- `RecordUpdated(address indexed _from, string _oldTitle, string _oldDescription, string _newTitle, string _newDescription, uint256 _timestamp, uint256 _flashcardId)`

#### `removeFlashcard(uint256 _flashcardId)`
Removes a flashcard. Only the owner can remove.

**Parameters:**
- `_flashcardId`: ID of the flashcard to remove

**Events:**
- `FlashcardRemoved(address indexed _from, string _question, uint256 _timestamp, uint256 _flashcardId)`

#### `getAllFlashcardsFromRecord(uint256 _recordId)`
Returns all flashcards associated with a specific record.

**Returns:** `Flashcard[]` - Array of flashcards

### Data Structures

```solidity
struct Record {
    address owner;
    string title;
    string description;
    uint256 timestamp;
    uint256 recordId;
}

struct Flashcard {
    address owner;
    string question;
    string answer;
    uint256 timestamp;
    uint256 correspondingRecordId;
    uint256 flashcardId;
}
```

## Testing

Run the test suite:
```bash
yarn test
```

The test file (`test/Forge.js`) includes tests for:
- Contract deployment
- Record creation, updating, and removal
- Flashcard creation and retrieval
- Access control and ownership validation

## Project Structure

```
Forge-contract/
├── contracts/
│   └── Forge.sol          # Main smart contract
├── scripts/
│   ├── deploy.js           # Deployment script
│   └── convert.js          # Utility script
├── test/
│   └── Forge.js           # Test suite
├── hardhat.config.js       # Hardhat configuration
├── package.json            # Project dependencies
└── README.md               # This file
```

## Security Considerations

- **Access Control**: Only record/flashcard owners can modify or remove their content
- **Gas Optimization**: The current implementation uses array operations that may be gas-intensive for large datasets
- **Input Validation**: Consider adding input validation for string lengths and empty values in production

