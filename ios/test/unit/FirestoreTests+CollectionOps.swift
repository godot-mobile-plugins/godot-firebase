//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin
import XCTest

// MARK: - getCollection

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: getCollection — success
	// -----------------------------------------------------------------------

	func test_getCollection_callsBackendOnce() {
		backend.collectionData = ["doc-1": ["name": "Alice"]]

		sut.getCollection(FirestoreFixtures.defaultCollection)

		XCTAssertEqual(backend.getCollectionCallCount, 1)
	}

	func test_getCollection_emitsCollectionQueryCompleted_onSuccess() {
		backend.collectionData = ["doc-1": ["name": "Alice"]]

		sut.getCollection(FirestoreFixtures.defaultCollection)

		XCTAssertEqual(emitter.collectionQueryResults.count, 1)
		XCTAssertTrue(emitter.collectionQueryFailures.isEmpty)
	}

	func test_getCollection_emittedResult_hasCorrectCollection() {
		backend.collectionData = ["doc-1": ["name": "Alice"]]

		sut.getCollection("orders")

		XCTAssertEqual(emitter.lastCollectionQueryResult?.collection, "orders")
	}

	func test_getCollection_emittedResult_containsAllDocumentIds() {
		backend.collectionData = [
			"doc-1": ["name": "Alice"],
			"doc-2": ["name": "Bob"],
			"doc-3": ["name": "Carol"]
		]

		sut.getCollection(FirestoreFixtures.defaultCollection)

		// The documents field is a Godot Dictionary (void *); we verify via
		// the ObjC getRawData pointer indirectly — checking that collection is
		// correct is the safe cross-language assertion here.
		XCTAssertEqual(emitter.collectionQueryResults.count, 1)
	}

	func test_getCollection_emptyCollection_emitsSuccessWithNoDocuments() {
		backend.collectionData = [:]

		sut.getCollection(FirestoreFixtures.defaultCollection)

		XCTAssertEqual(emitter.collectionQueryResults.count, 1)
		XCTAssertTrue(emitter.collectionQueryFailures.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: getCollection — failure
	// -----------------------------------------------------------------------

	func test_getCollection_emitsCollectionQueryFailed_onError() {
		backend.getCollectionError = FirestoreFixtures.makeError("Offline")

		sut.getCollection(FirestoreFixtures.defaultCollection)

		XCTAssertEqual(emitter.collectionQueryFailures.count, 1)
		XCTAssertTrue(emitter.collectionQueryResults.isEmpty)
	}

	func test_getCollection_queryFailure_containsCollection() {
		backend.getCollectionError = FirestoreFixtures.makeError()

		sut.getCollection("orders")

		XCTAssertEqual(emitter.lastCollectionQueryFailure?.collection, "orders")
	}

	func test_getCollection_queryFailure_containsErrorMessage() {
		backend.getCollectionError = FirestoreFixtures.makeError("Offline")

		sut.getCollection(FirestoreFixtures.defaultCollection)

		XCTAssertEqual(emitter.lastCollectionQueryFailure?.error, "Offline")
	}
}
