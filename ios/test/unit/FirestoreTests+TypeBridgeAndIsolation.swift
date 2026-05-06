//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin
import XCTest

// MARK: - Type-bridge round-trip

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: Type-bridge round-trip
	// -----------------------------------------------------------------------

	func test_addDocument_stringField_roundTripsCorrectly() {
		let doc = FirestoreFixtures.makeDocument(data: ["key": "value"])
		var capturedData: [String: Any]?
		// Intercept via a custom backend subclass is impractical without
		// inheritance; verify through the emitted document instead.
		sut.addDocument(doc)

		capturedData = emitter.lastDocumentWritten?.documentDataAsDictionary()
		XCTAssertEqual(capturedData?["key"] as? String, "value")
	}

	func test_addDocument_intField_roundTripsCorrectly() {
		let doc = FirestoreFixtures.makeDocument(data: ["count": NSNumber(value: Int64(7))])
		sut.addDocument(doc)

		let data = emitter.lastDocumentWritten?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(data["count"] as? Int, 7)
	}

	func test_addDocument_boolField_roundTripsCorrectly() {
		let doc = FirestoreFixtures.makeDocument(data: ["active": NSNumber(value: true)])
		sut.addDocument(doc)

		let data = emitter.lastDocumentWritten?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(data["active"] as? Bool, true)
	}

	func test_addDocument_floatField_roundTripsCorrectly() {
		let doc = FirestoreFixtures.makeDocument(data: ["ratio": NSNumber(value: 0.5)])
		sut.addDocument(doc)

		let data = emitter.lastDocumentWritten?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(data["ratio"] as? Double ?? 0, 0.5, accuracy: 0.0001)
	}

	func test_addDocument_nestedDictField_roundTripsCorrectly() {
		let doc = FirestoreFixtures.makeDocument(data: ["meta": ["region": "us-west"]])
		sut.addDocument(doc)

		let data = emitter.lastDocumentWritten?.documentDataAsDictionary() ?? [:]
		let nested = data["meta"] as? [String: Any]
		XCTAssertEqual(nested?["region"] as? String, "us-west")
	}

	func test_getDocument_populatedData_bridgesStringCorrectly() {
		backend.documentData = ["username": "bob"]
		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		let data = emitter.lastDocumentQueryResult?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(data["username"] as? String, "bob")
	}

	func test_getDocument_populatedData_bridgesBoolCorrectly() {
		backend.documentData = ["verified": NSNumber(value: true)]
		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		let data = emitter.lastDocumentQueryResult?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(data["verified"] as? Bool, true)
	}
}

// MARK: - Signal isolation

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: Signal isolation (no cross-contamination between signal types)
	// -----------------------------------------------------------------------

	func test_successfulWrite_doesNotEmitAnyFailureSignals() {
		sut.addDocument(FirestoreFixtures.makeDocument())

		XCTAssertTrue(emitter.documentWriteFailures.isEmpty)
		XCTAssertTrue(emitter.documentUpdateFailures.isEmpty)
		XCTAssertTrue(emitter.documentDeleteFailures.isEmpty)
		XCTAssertTrue(emitter.documentQueryFailures.isEmpty)
		XCTAssertTrue(emitter.collectionQueryFailures.isEmpty)
	}

	func test_failedWrite_doesNotEmitAnySuccessSignals() {
		backend.addDocumentError = FirestoreFixtures.makeError()
		sut.addDocument(FirestoreFixtures.makeDocument())

		XCTAssertTrue(emitter.documentsWritten.isEmpty)
		XCTAssertTrue(emitter.documentsUpdated.isEmpty)
		XCTAssertTrue(emitter.documentsDeleted.isEmpty)
		XCTAssertTrue(emitter.documentQueryResults.isEmpty)
		XCTAssertTrue(emitter.collectionQueryResults.isEmpty)
	}

	func test_successfulQuery_doesNotEmitWriteOrDeleteSignals() {
		backend.documentData = ["x": "y"]
		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertTrue(emitter.documentsWritten.isEmpty)
		XCTAssertTrue(emitter.documentsDeleted.isEmpty)
	}
}
