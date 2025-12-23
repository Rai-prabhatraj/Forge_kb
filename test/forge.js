const { expect } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

describe("Forge", function () {
  let Forge;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const Forge = await ethers.getContractFactory("Forge");
    Forge = await Forge.deploy();
    await Forge.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should deploy successfully", async function () {
      expect(await Forge.getAddress()).to.be.properAddress;
    });

    it("Should have initial record count of 0", async function () {
      expect(await Forge.recordCount()).to.equal(0);
    });
  });

  describe("Records", function () {
    it("Should allow adding a record", async function () {
      const title = "Test Record";
      const description = "This is a test record";

      await expect(Forge.addRecord(title, description))
        .to.emit(Forge, "RecordAdded")
        .withArgs(owner.address, title, description, anyValue, anyValue);

      expect(await Forge.recordCount()).to.equal(1);
    });

    it("Should retrieve all records from an address", async function () {
      await Forge.addRecord("Record 1", "Description 1");
      await Forge.addRecord("Record 2", "Description 2");

      const records = await Forge.getAllRecordsFromAddress(owner.address);
      expect(records.length).to.equal(2);
      expect(records[0].title).to.equal("Record 1");
      expect(records[1].title).to.equal("Record 2");
    });

    it("Should allow updating a record by owner", async function () {
      await Forge.addRecord("Original Title", "Original Description");
      const records = await Forge.getAllRecordsFromAddress(owner.address);
      const recordId = records[0].recordId;

      await expect(Forge.updateRecord(recordId, "Updated Title", "Updated Description"))
        .to.emit(Forge, "RecordUpdated");

      const updatedRecords = await Forge.getAllRecordsFromAddress(owner.address);
      expect(updatedRecords[0].title).to.equal("Updated Title");
    });

    it("Should not allow updating a record by non-owner", async function () {
      await Forge.addRecord("Original Title", "Original Description");
      const records = await Forge.getAllRecordsFromAddress(owner.address);
      const recordId = records[0].recordId;

      await expect(
        Forge.connect(addr1).updateRecord(recordId, "Updated Title", "Updated Description")
      ).to.be.revertedWith("Only the owner can update the record");
    });
  });

  describe("Flashcards", function () {
    let recordId;

    beforeEach(async function () {
      await Forge.addRecord("Test Record", "Test Description");
      const records = await Forge.getAllRecordsFromAddress(owner.address);
      recordId = records[0].recordId;
    });

    it("Should allow adding a flashcard to a record", async function () {
      const question = "What is Solidity?";
      const answer = "A programming language for smart contracts";

      await expect(Forge.addFlashcard(recordId, question, answer))
        .to.emit(Forge, "FlashcardAdded")
        .withArgs(owner.address, question, answer, anyValue, recordId);
    });

    it("Should retrieve all flashcards from a record", async function () {
      await Forge.addFlashcard(recordId, "Question 1", "Answer 1");
      await Forge.addFlashcard(recordId, "Question 2", "Answer 2");

      const flashcards = await Forge.getAllFlashcardsFromRecord(recordId);
      expect(flashcards.length).to.be.greaterThan(0);
    });
  });
});

