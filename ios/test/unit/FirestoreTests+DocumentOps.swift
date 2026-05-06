//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin
import XCTest

// MARK: - deleteDocument

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: deleteDocument — success
	// -----------------------------------------------------------------------

	func test_deleteDocument_callsBackendOnce() {
		sut.deleteDocument(FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(backend.deleteDocumentCallCount, 1)
	}

	func test_deleteDocument_emitsDocumentDeleted_onSuccess() {
		sut.deleteDocument(FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.documentsDeleted.count, 1)
		XCTAssertTrue(emitter.documentDeleteFailures.isEmpty)
	}

	func test_deleteDocument_emittedDocument_hasCorrectPath() {
		sut.deleteDocument("archive", documentId: "old-doc")

		XCTAssertEqual(emitter.lastDocumentDeleted?.collection, "archive")
		XCTAssertEqual(emitter.lastDocumentDeleted?.documentId, "old-doc")
	}

	// -----------------------------------------------------------------------
	// MARK: deleteDocument — failure
	// -----------------------------------------------------------------------

	func test_deleteDocument_emitsDeleteFailed_onError() {
		backend.deleteDocumentError = FirestoreFixtures.makeError("Not found")

		sut.deleteDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.documentDeleteFailures.count, 1)
		XCTAssertTrue(emitter.documentsDeleted.isEmpty)
	}

	func test_deleteDocument_deleteFailure_containsCollection() {
		backend.deleteDocumentError = FirestoreFixtures.makeError()

		sut.deleteDocument("archive", documentId: "old-doc")

		XCTAssertEqual(emitter.lastDocumentDeleteFailure?.collection, "archive")
	}

	func test_deleteDocument_deleteFailure_containsDocumentId() {
		backend.deleteDocumentError = FirestoreFixtures.makeError()

		sut.deleteDocument(FirestoreFixtures.defaultCollection, documentId: "old-doc")

		XCTAssertEqual(emitter.lastDocumentDeleteFailure?.documentId, "old-doc")
	}

	func test_deleteDocument_deleteFailure_containsErrorMessage() {
		backend.deleteDocumentError = FirestoreFixtures.makeError("Insufficient permissions")

		sut.deleteDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.lastDocumentDeleteFailure?.error, "Insufficient permissions")
	}
}

// MARK: - getDocument

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: getDocument — success
	// -----------------------------------------------------------------------

	func test_getDocument_callsBackendOnce() {
		backend.documentData = ["name": "Alice"]

		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(backend.getDocumentCallCount, 1)
	}

	func test_getDocument_emitsQueryCompleted_onSuccess() {
		backend.documentData = ["name": "Alice"]

		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.documentQueryResults.count, 1)
		XCTAssertTrue(emitter.documentQueryFailures.isEmpty)
	}

	func test_getDocument_emittedDocument_hasCorrectPath() {
		backend.documentData = ["name": "Alice"]

		sut.getDocument("users", documentId: "u-1")

		XCTAssertEqual(emitter.lastDocumentQueryResult?.collection, "users")
		XCTAssertEqual(emitter.lastDocumentQueryResult?.documentId, "u-1")
	}

	func test_getDocument_emittedDocument_containsData() {
		backend.documentData = ["name": "Alice", "score": NSNumber(value: 100)]

		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		let data = emitter.lastDocumentQueryResult?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(data["name"] as? String, "Alice")
		XCTAssertEqual(data["score"] as? Int, 100)
	}

	// -----------------------------------------------------------------------
	// MARK: getDocument — not found
	// -----------------------------------------------------------------------

	func test_getDocument_emitsQueryFailed_whenDocumentNotFound() {
		backend.documentNotFound = true

		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.documentQueryFailures.count, 1)
		XCTAssertTrue(emitter.documentQueryResults.isEmpty)
	}

	func test_getDocument_queryFailure_whenNotFound_containsCorrectMessage() {
		backend.documentNotFound = true

		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.lastDocumentQueryFailure?.error, "Document not found.")
	}

	func test_getDocument_queryFailure_whenNotFound_containsPath() {
		backend.documentNotFound = true

		sut.getDocument("users", documentId: "ghost")

		XCTAssertEqual(emitter.lastDocumentQueryFailure?.collection, "users")
		XCTAssertEqual(emitter.lastDocumentQueryFailure?.documentId, "ghost")
	}

	// -----------------------------------------------------------------------
	// MARK: getDocument — backend error
	// -----------------------------------------------------------------------

	func test_getDocument_emitsQueryFailed_onBackendError() {
		backend.getDocumentError = FirestoreFixtures.makeError("Unavailable")

		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.documentQueryFailures.count, 1)
		XCTAssertTrue(emitter.documentQueryResults.isEmpty)
	}

	func test_getDocument_queryFailure_containsErrorMessage() {
		backend.getDocumentError = FirestoreFixtures.makeError("Unavailable")

		sut.getDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(emitter.lastDocumentQueryFailure?.error, "Unavailable")
	}
}
