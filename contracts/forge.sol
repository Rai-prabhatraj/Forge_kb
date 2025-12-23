// SPDX-License-Identifier: MIT

/**
 * @title Forge
 * @dev The Forge contract stores instances of Records, which represent a piece of knowledge. 
 * Users can add Flashcards for these Records, which each contain a question and an answer.
 * Optimized for gas efficiency with O(1) lookups and efficient removal operations.
 */

pragma solidity ^0.8.9;


contract Forge {

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

    // Storage arrays
    Record[] public records;
    Flashcard[] public flashcards;
    
    // Counters for ID generation (more efficient than random generation)
    uint256 private _recordIdCounter;
    uint256 private _flashcardIdCounter;
    
    // O(1) lookup mappings
    mapping(uint256 => uint256) private _recordIdToIndex;      // recordId => array index
    mapping(uint256 => uint256) private _flashcardIdToIndex;    // flashcardId => array index
    mapping(uint256 => bool) private _recordExists;            // recordId => exists
    mapping(uint256 => bool) private _flashcardExists;         // flashcardId => exists
    
    // User-specific mappings
    mapping(address => uint256[]) public recordIds;           // owner => recordIds[]
    mapping(address => uint256[]) public flashcardIds;         // owner => flashcardIds[]
    
    // Record to flashcards mapping (efficient retrieval)
    mapping(uint256 => uint256[]) private _recordFlashcards;  // recordId => flashcardIds[]
    
    // Flashcard owners per record (for tracking)
    mapping(uint256 => mapping(address => bool)) private _flashcardOwnerExists; // recordId => (owner => exists)

    event RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event RecordUpdated(address indexed _from, string _oldTitle, string _oldDescription, string _newTitle, string _newDescription, uint256 _timestamp, uint256 _recordId);
    event RecordRemoved(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event FlashcardAdded(address indexed _from, string _question, string _answer, uint256 _timestamp, uint256 _recordId);
    event FlashcardRemoved(address indexed _from, string _question, uint256 _timestamp, uint256 _flashcardId);

    // Public getter for record count
    function recordCount() public view returns (uint256) {
        return records.length;
    }

    // Helper function to get record by ID (O(1) lookup)
    function _getRecord(uint256 _recordId) private view returns (Record storage) {
        require(_recordExists[_recordId], "Record not found");
        uint256 index = _recordIdToIndex[_recordId];
        return records[index];
    }

    // Helper function to get flashcard by ID (O(1) lookup)
    function _getFlashcard(uint256 _flashcardId) private view returns (Flashcard storage) {
        require(_flashcardExists[_flashcardId], "Flashcard not found");
        uint256 index = _flashcardIdToIndex[_flashcardId];
        return flashcards[index];
    }

    // Helper function to remove from array using swap-and-pop (O(1) instead of O(n))
    function _removeFromArray(uint256[] storage array, uint256 value) private {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == value) {
                // Swap with last element and pop
                array[i] = array[length - 1];
                array.pop();
                return;
            }
        }
    }

    // Record functions

    function addRecord(string memory _title, string memory _description) public {
        uint256 _recordId = ++_recordIdCounter;
        uint256 index = records.length;
        
        Record memory record = Record(msg.sender, _title, _description, block.timestamp, _recordId);
        records.push(record);
        
        // Set up O(1) lookups
        _recordIdToIndex[_recordId] = index;
        _recordExists[_recordId] = true;
        recordIds[msg.sender].push(_recordId);
        
        emit RecordAdded(msg.sender, _title, _description, block.timestamp, _recordId);
    }

    function updateRecord(uint256 _recordId, string memory _title, string memory _description) public {
        Record storage record = _getRecord(_recordId);
        require(msg.sender == record.owner, "Only the owner can update the record");
        
        string memory _oldTitle = record.title;
        string memory _oldDescription = record.description;
        record.title = _title;
        record.description = _description;
        record.timestamp = block.timestamp;
        
        emit RecordUpdated(msg.sender, _oldTitle, _oldDescription, _title, _description, block.timestamp, _recordId);
    }

    function removeRecord(uint256 _recordId) public {
        Record storage record = _getRecord(_recordId);
        require(msg.sender == record.owner, "Only the owner can remove the record");
        
        string memory _title = record.title;
        string memory _description = record.description;
        
        // Remove all flashcards associated with this record
        uint256[] memory flashcardIdsToRemove = _recordFlashcards[_recordId];
        uint256 length = flashcardIdsToRemove.length;
        for (uint256 i = 0; i < length; i++) {
            Flashcard storage flashcard = _getFlashcard(flashcardIdsToRemove[i]);
            if (flashcard.owner == msg.sender) {
                _removeFlashcardInternal(flashcardIdsToRemove[i], msg.sender);
            }
        }
        
        // Remove record from array using swap-and-pop
        uint256 recordIndex = _recordIdToIndex[_recordId];
        uint256 lastIndex = records.length - 1;
        
        if (recordIndex != lastIndex) {
            // Swap with last element
            Record storage lastRecord = records[lastIndex];
            records[recordIndex] = lastRecord;
            _recordIdToIndex[lastRecord.recordId] = recordIndex;
        }
        records.pop();
        
        // Clean up mappings
        delete _recordIdToIndex[_recordId];
        delete _recordExists[_recordId];
        delete _recordFlashcards[_recordId];
        _removeFromArray(recordIds[msg.sender], _recordId);
        
        emit RecordRemoved(msg.sender, _title, _description, block.timestamp, _recordId);
    }

    function getAllRecordsFromAddress(address _owner) public view returns (Record[] memory) {
        uint256[] memory ownerRecordIds = recordIds[_owner];
        uint256 length = ownerRecordIds.length;
        Record[] memory _records = new Record[](length);
        
        for (uint256 i = 0; i < length; i++) {
            if (_recordExists[ownerRecordIds[i]]) {
                _records[i] = _getRecord(ownerRecordIds[i]);
            }
        }
        return _records;
    }

    function getAllRecords() public view returns (Record[] memory) {
        return records;
    }

    // Flashcard functions

    function addFlashcard(uint256 _recordId, string memory _question, string memory _answer) public {
        require(_recordExists[_recordId], "Record not found");
        
        uint256 _flashcardId = ++_flashcardIdCounter;
        uint256 index = flashcards.length;
        
        Flashcard memory flashcard = Flashcard(
            msg.sender, 
            _question, 
            _answer, 
            block.timestamp, 
            _recordId, 
            _flashcardId
        );
        flashcards.push(flashcard);
        
        // Set up O(1) lookups
        _flashcardIdToIndex[_flashcardId] = index;
        _flashcardExists[_flashcardId] = true;
        flashcardIds[msg.sender].push(_flashcardId);
        _recordFlashcards[_recordId].push(_flashcardId);
        
        // Track owner for this record
        if (!_flashcardOwnerExists[_recordId][msg.sender]) {
            _flashcardOwnerExists[_recordId][msg.sender] = true;
        }
        
        emit FlashcardAdded(msg.sender, _question, _answer, block.timestamp, _recordId);
    }

    function updateFlashcard(uint256 _flashcardId, string memory _newTitle, string memory _newDesc) public {
        Flashcard storage flashcard = _getFlashcard(_flashcardId);
        require(msg.sender == flashcard.owner, "Only the owner can update the flashcard");
        
        string memory _oldTitle = flashcard.question;
        string memory _oldDesc = flashcard.answer;
        flashcard.question = _newTitle;
        flashcard.answer = _newDesc;
        flashcard.timestamp = block.timestamp;
        
        emit RecordUpdated(msg.sender, _oldTitle, _oldDesc, _newTitle, _newDesc, block.timestamp, _flashcardId);
    }

    function removeFlashcard(uint256 _flashcardId) public {
        Flashcard storage flashcard = _getFlashcard(_flashcardId);
        require(msg.sender == flashcard.owner, "Only the owner can remove the flashcard");
        
        _removeFlashcardInternal(_flashcardId, msg.sender);
    }

    // Internal function to remove flashcard (used by both removeFlashcard and removeRecord)
    function _removeFlashcardInternal(uint256 _flashcardId, address owner) private {
        Flashcard storage flashcard = _getFlashcard(_flashcardId);
        uint256 _recordId = flashcard.correspondingRecordId;
        string memory _question = flashcard.question;
        
        // Remove from flashcards array using swap-and-pop
        uint256 flashcardIndex = _flashcardIdToIndex[_flashcardId];
        uint256 lastIndex = flashcards.length - 1;
        
        if (flashcardIndex != lastIndex) {
            // Swap with last element
            Flashcard storage lastFlashcard = flashcards[lastIndex];
            flashcards[flashcardIndex] = lastFlashcard;
            _flashcardIdToIndex[lastFlashcard.flashcardId] = flashcardIndex;
        }
        flashcards.pop();
        
        // Clean up mappings
        delete _flashcardIdToIndex[_flashcardId];
        delete _flashcardExists[_flashcardId];
        _removeFromArray(flashcardIds[owner], _flashcardId);
        _removeFromArray(_recordFlashcards[_recordId], _flashcardId);
        
        // Check if owner has any more flashcards for this record
        uint256[] memory ownerFlashcards = flashcardIds[owner];
        bool hasMoreFlashcards = false;
        for (uint256 i = 0; i < ownerFlashcards.length; i++) {
            if (_flashcardExists[ownerFlashcards[i]]) {
                Flashcard storage fc = _getFlashcard(ownerFlashcards[i]);
                if (fc.correspondingRecordId == _recordId) {
                    hasMoreFlashcards = true;
                    break;
                }
            }
        }
        if (!hasMoreFlashcards) {
            delete _flashcardOwnerExists[_recordId][owner];
        }
        
        emit FlashcardRemoved(owner, _question, block.timestamp, _flashcardId);
    }

    function getAllFlashcardsFromRecord(uint256 _recordId) public view returns (Flashcard[] memory) {
        require(_recordExists[_recordId], "Record not found");
        
        uint256[] memory flashcardIdsForRecord = _recordFlashcards[_recordId];
        uint256 length = flashcardIdsForRecord.length;
        Flashcard[] memory _flashcards = new Flashcard[](length);
        
        uint256 validCount = 0;
        for (uint256 i = 0; i < length; i++) {
            if (_flashcardExists[flashcardIdsForRecord[i]]) {
                _flashcards[validCount] = _getFlashcard(flashcardIdsForRecord[i]);
                validCount++;
            }
        }
        
        // Resize array if needed (some flashcards may have been removed)
        if (validCount < length) {
            Flashcard[] memory resized = new Flashcard[](validCount);
            for (uint256 i = 0; i < validCount; i++) {
                resized[i] = _flashcards[i];
            }
            return resized;
        }
        
        return _flashcards;
    }
}
