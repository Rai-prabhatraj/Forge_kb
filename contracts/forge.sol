// SPDX-License-Identifier: MIT

/**
 * @title Forge
 * @dev The Forge contract stores instances of Records, which represent a piece of knowledge. 
 * Users can add Flashcards for these Records, which each contain a question and an answer.
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

    Record[] public records;
    uint256 public recordCount;
    Flashcard[] public flashcards;
    mapping(uint256 => address[]) public flashcardOwners;
    mapping(address => uint256[]) public recordIds;
    mapping(address => uint256[]) public flashcardIds;

    event RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event RecordUpdated(address indexed _from, string _oldTitle, string _oldDescription, string _newTitle, string _newDescription, uint256 _timestamp, uint256 _recordId);
    event RecordRemoved(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event FlashcardAdded(address indexed _from, string _question, string _answer, uint256 _timestamp, uint256 _recordId);
    event FlashcardRemoved(address indexed _from, string _question, uint256 _timestamp, uint256 _recordId);

    // helper functions

    function generateId(bool isRecord) private view returns (uint256) {
        uint256 randId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        // check if recordId already exists
        // two instances of recordId and flashcardId can be the same, 
        // but not two instances of recordId or two instances of flashcardId
        if (isRecord) {
            for (uint256 i = 0; i < records.length; i++) {
                if (records[i].recordId == randId) {
                    randId = generateId(isRecord);
                }
            }
        } else {
            for (uint256 i = 0; i < flashcards.length; i++) {
                if (flashcards[i].flashcardId == randId) {
                    randId = generateId(isRecord);
                }
            }
        }
        return randId;
    }

    // record functions

    function addRecord(string memory _title, string memory _description) public {
        // add record to records
        uint256 _recordId = generateId(true);
        Record memory record = Record(msg.sender, _title, _description, block.timestamp, _recordId);
        records.push(record);
        recordIds[msg.sender].push(_recordId);
        recordCount++;
        emit RecordAdded(msg.sender, _title, _description, block.timestamp, _recordId);
    }

    function findRecord(uint256 _recordId) private view returns (Record storage) {
        // find record in records using its recordId
        // useful to validate that the record exists
        for (uint256 i = 0; i < records.length; i++) {
            if (records[i].recordId == _recordId) {
                return records[i];
            }
        }
        revert("Record not found");
    }

    function updateRecord(uint256 _recordId, string memory _title, string memory _description) public {
        // update record in records using its recordId
        Record storage record = findRecord(_recordId); // for persistent change
        require(msg.sender == record.owner, "Only the owner can update the record");
        string memory _oldTitle = record.title;
        string memory _oldDescription = record.description;
        record.title = _title;
        record.description = _description;
        record.timestamp = block.timestamp;
        emit RecordUpdated(msg.sender, _oldTitle, _oldDescription, _title, _description, block.timestamp, _recordId);
    }

    function removeRecord(uint256 _recordId) public { // this is so gas inefficient it's not even funny
        // remove record from records using its recordId
        // also remove all flashcards associated with the record
        
        // get rid of flashcardOwners first since every flashcards will be removed
        delete flashcardOwners[_recordId];
        // find record and remove it
        bool found = false;
        for (uint256 i = 0; i < records.length; i++) {
            if (_recordId == records[i].recordId) {
                found = true;
                Record memory record = records[i];
                require(msg.sender == record.owner, "Only the owner can remove the record");
                string memory _title = record.title;
                string memory _description = record.description;
                record.timestamp = block.timestamp;
                // remove record from records manually
                for (uint256 j = i; j < records.length - 1; j++) {
                    records[j] = records[j + 1];
                }
                records.pop();
                recordCount--;
                emit RecordRemoved(msg.sender, _title, _description, block.timestamp, _recordId);
            }
        }
        require(found, "Record not found");
        // remove recordId from recordIds
        for (uint256 i = 0; i < recordIds[msg.sender].length; i++) {
            if (recordIds[msg.sender][i] == _recordId) {
                for (uint256 j = i; j < recordIds[msg.sender].length - 1; j++) {
                    recordIds[msg.sender][j] = recordIds[msg.sender][j + 1];
                }
                recordIds[msg.sender].pop();
            }
        }
        // remove flashcards associated with the record
        uint256[] memory _flashcardIds = flashcardIds[msg.sender];
        for (uint256 i = 0; i < _flashcardIds.length; i++) { // this is giving me a headache
            removeFlashcard(_flashcardIds[i]);
        }
    }

    function getAllRecordsFromAddress(address _owner) public view returns (Record[] memory) {
        // get all records from an address, 
        // useful as a getter function for the user in the frontend
        Record[] memory _records = new Record[](recordIds[_owner].length);
        for (uint256 i = 0; i < recordIds[_owner].length; i++) {
            _records[i] = findRecord(recordIds[_owner][i]);
        }
        return _records;
    }

    function getAllRecords() public view returns (Record[] memory) {
        // get all records,
        // useful as a getter function to display a "marketplace" of records
        Record[] memory _records = new Record[](records.length);
        for (uint256 i = 0; i < records.length; i++) {
            _records[i] = records[i];
        }
        return _records;
    }

    // flashcard functions

    function addFlashcard(uint256 _recordId, string memory _question, string memory _answer) public {
        // add flashcard to specific record
        Record memory record = findRecord(_recordId); // check if record exists
        uint256 _flashcardId = generateId(false);
        Flashcard memory flashcard = Flashcard(msg.sender, _question, _answer, block.timestamp, _recordId, _flashcardId);
        flashcards.push(flashcard);
        flashcardIds[msg.sender].push(_flashcardId);
        // add msg.sender to flashcardOwners if not already there
        bool found = false;
        for (uint256 i = 0; i < flashcardOwners[_recordId].length; i++) {
            if (flashcardOwners[_recordId][i] == msg.sender) {
                found = true;
            }
        }
        if (!found) {
            flashcardOwners[_recordId].push(msg.sender);
        }
        emit FlashcardAdded(msg.sender, _question, _answer, block.timestamp, _recordId);
    }

    function updateFlashcard(uint256 _flashcardId, string memory _newTitle, string memory _newDesc) public {
        // update flashcard in flashcards using its flashcardId
        // find flashcardId first
        bool found = false;
        for (uint256 i = 0; i < flashcards.length; i++) {
            if (flashcards[i].flashcardId == _flashcardId) {
                require(msg.sender == flashcards[i].owner, "Only the owner can update the flashcard");
                found = true;
                Flashcard storage flashcard = flashcards[i]; // for persistent change
                string memory _oldTitle = flashcards[i].question;
                string memory _oldDesc = flashcards[i].answer;
                flashcard.question = _newTitle;
                flashcard.answer = _newDesc;
                flashcard.timestamp = block.timestamp;
                emit RecordUpdated(msg.sender, _oldTitle, _oldDesc, _newTitle, _newDesc, block.timestamp, _flashcardId);
            }
        }
        require(found, "Flashcard not found");
    }

    function removeFlashcard(uint256 _flashcardId) public { // by gods this is awful
        // remove flashcard from flashcards using its flashcardId
        // there is a lot of things you need to do to remove a flashcard
        // firstly, check if the flashcard exists and remove it from flashcardIds
        bool found = false;
        bool noMoreFlashcards = false;
        // look for flashcard in flashcardIds
        for (uint256 i = 0; i < flashcardIds[msg.sender].length; i++) {
            if (flashcardIds[msg.sender][i] == _flashcardId) {
                found = true;
                for (uint256 j = i; j < flashcardIds[msg.sender].length - 1; j++) {
                    flashcardIds[msg.sender][j] = flashcardIds[msg.sender][j + 1];
                }
                if (flashcardIds[msg.sender].length > 0) {
                    flashcardIds[msg.sender].pop();
                } else {
                    noMoreFlashcards = true;
                }
            }
        }
        require (found, "Flashcard not found");
        // look for flashcard in flashcards
        for (uint256 i = 0; i < flashcards.length; i++) {
            if (flashcards[i].flashcardId == _flashcardId) {
                require(msg.sender == flashcards[i].owner, "Only the owner can remove the flashcard");
                found = true;
                uint256 _recordId = flashcards[i].correspondingRecordId;
                string memory _question = flashcards[i].question;
                // remove flashcard from flashcards manually
                for (uint256 j = i; j < flashcards.length - 1; j++) {
                    flashcards[j] = flashcards[j + 1];
                }
                if (flashcards.length > 0) {
                    flashcards.pop();
                }
                // delete owner from flashcardOwners if no more flashcards
                if (noMoreFlashcards) {
                    for (uint256 j = 0; j < flashcardOwners[_recordId].length; j++) {
                        if (flashcardOwners[_recordId][j] == msg.sender) {
                            for (uint256 k = j; k < flashcardOwners[_recordId].length - 1; k++) {
                                flashcardOwners[_recordId][k] = flashcardOwners[_recordId][k + 1];
                            }
                            if (flashcardOwners[_recordId].length > 0) {
                                flashcardOwners[_recordId].pop();
                            }
                        }
                    }
                }
                emit FlashcardRemoved(msg.sender, _question, block.timestamp, _flashcardId);
            }
        }
    }

    function getAllFlashcardsFromRecord(uint256 _recordId) public view returns (Flashcard[] memory) {
        // get all flashcards from a record,
        // useful as a getter function for the user in the frontend
        Flashcard[] memory _flashcards = new Flashcard[](flashcardIds[msg.sender].length);
        for (uint256 i = 0; i < flashcards.length; i++) {
            if (flashcards[i].correspondingRecordId == _recordId) {
                for (uint256 j = 0; j < _flashcards.length; j++) {
                    if (_flashcards[j].owner == address(0)) {
                        _flashcards[j] = flashcards[i];
                        break;
                    }
                }
            }
        }
        return _flashcards;
    }
}
