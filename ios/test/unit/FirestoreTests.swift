//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin    // adjust to your actual module name
import XCTest

// MARK: - FirestoreTests

final class FirestoreTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: Shared fixtures — recreated before every test
	// -----------------------------------------------------------------------

	var emitter: MockFirestoreEmitter!
	var backend: MockFirestoreBackend!
	var sut: Firestore!

	override func setUp() {
		super.setUp()
		emitter = MockFirestoreEmitter()
		backend = MockFirestoreBackend()
		sut = Firestore(emitter: emitter, backend: backend)
	}

	override func tearDown() {
		sut = nil
		backend = nil
		emitter = nil
		super.tearDown()
	}
}

// MARK: - addDocument

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: addDocument — success
	// -----------------------------------------------------------------------

	func test_addDocument_callsBackendOnce() {
		let doc = FirestoreFixtures.makeDocument()

		sut.addDocument(doc)

		XCTAssertEqual(backend.addDocumentCallCount, 1)
	}

	func test_addDocument_emitsDocumentWritten_onSuccess() {
		let doc = FirestoreFixtures.makeDocument(
			collection: "orders",
			documentId: "ord-1"
		)

		sut.addDocument(doc)

		XCTAssertEqual(emitter.documentsWritten.count, 1)
		XCTAssertTrue(emitter.documentWriteFailures.isEmpty)
	}

	func test_addDocument_emittedDocument_hasCorrectCollection() {
		let doc = FirestoreFixtures.makeDocument(collection: "orders")

		sut.addDocument(doc)

		XCTAssertEqual(emitter.lastDocumentWritten?.collection, "orders")
	}

	func test_addDocument_emittedDocument_preservesData() {
		let data: [String: Any] = ["title": "Test Order", "quantity": NSNumber(value: 3)]
		let doc = FirestoreFixtures.makeDocument(data: data)

		sut.addDocument(doc)

		let emitted = emitter.lastDocumentWritten
		let emittedData = emitted?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(emittedData["title"] as? String, "Test Order")
		XCTAssertEqual(emittedData["quantity"] as? Int, 3)
	}

	// -----------------------------------------------------------------------
	// MARK: addDocument — failure
	// -----------------------------------------------------------------------

	func test_addDocument_emitsDocumentWriteFailed_onError() {
		backend.addDocumentError = FirestoreFixtures.makeError("Quota exceeded")
		let doc = FirestoreFixtures.makeDocument()

		sut.addDocument(doc)

		XCTAssertEqual(emitter.documentWriteFailures.count, 1)
		XCTAssertTrue(emitter.documentsWritten.isEmpty)
	}

	func test_addDocument_writeFailure_containsErrorMessage() {
		backend.addDocumentError = FirestoreFixtures.makeError("Quota exceeded")
		let doc = FirestoreFixtures.makeDocument(collection: "orders")

		sut.addDocument(doc)

		XCTAssertEqual(emitter.lastDocumentWriteFailure?.error, "Quota exceeded")
	}

	func test_addDocument_writeFailure_containsCollection() {
		backend.addDocumentError = FirestoreFixtures.makeError()
		let doc = FirestoreFixtures.makeDocument(collection: "orders")

		sut.addDocument(doc)

		XCTAssertEqual(emitter.lastDocumentWriteFailure?.collection, "orders")
	}
}

// MARK: - setDocument

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: setDocument (merge: false) — success
	// -----------------------------------------------------------------------

	func test_setDocument_noMerge_callsBackendOnce() {
		let doc = FirestoreFixtures.makeDocument()

		sut.setDocument(doc, merge: false)

		XCTAssertEqual(backend.setDocumentCallCount, 1)
	}

	func test_setDocument_noMerge_emitsDocumentWritten_onSuccess() {
		let doc = FirestoreFixtures.makeDocument()

		sut.setDocument(doc, merge: false)

		XCTAssertEqual(emitter.documentsWritten.count, 1)
		XCTAssertTrue(emitter.documentWriteFailures.isEmpty)
	}

	func test_setDocument_noMerge_emittedDocument_hasCorrectPath() {
		let doc = FirestoreFixtures.makeDocument(
			collection: "products",
			documentId: "prod-7"
		)

		sut.setDocument(doc, merge: false)

		XCTAssertEqual(emitter.lastDocumentWritten?.collection, "products")
		XCTAssertEqual(emitter.lastDocumentWritten?.documentId, "prod-7")
	}

	// -----------------------------------------------------------------------
	// MARK: setDocument (merge: true) — success
	// -----------------------------------------------------------------------

	func test_setDocument_merge_callsBackendOnce() {
		let doc = FirestoreFixtures.makeDocument()

		sut.setDocument(doc, merge: true)

		XCTAssertEqual(backend.setDocumentCallCount, 1)
	}

	func test_setDocument_merge_emitsDocumentWritten_onSuccess() {
		let doc = FirestoreFixtures.makeDocument()

		sut.setDocument(doc, merge: true)

		XCTAssertEqual(emitter.documentsWritten.count, 1)
		XCTAssertTrue(emitter.documentWriteFailures.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: setDocument — failure
	// -----------------------------------------------------------------------

	func test_setDocument_emitsWriteFailed_onError() {
		backend.setDocumentError = FirestoreFixtures.makeError("Permission denied")
		let doc = FirestoreFixtures.makeDocument()

		sut.setDocument(doc, merge: false)

		XCTAssertEqual(emitter.documentWriteFailures.count, 1)
		XCTAssertTrue(emitter.documentsWritten.isEmpty)
	}

	func test_setDocument_writeFailure_containsDocumentId() {
		backend.setDocumentError = FirestoreFixtures.makeError()
		let doc = FirestoreFixtures.makeDocument(documentId: "prod-7")

		sut.setDocument(doc, merge: false)

		XCTAssertEqual(emitter.lastDocumentWriteFailure?.documentId, "prod-7")
	}

	func test_setDocument_writeFailure_containsErrorMessage() {
		backend.setDocumentError = FirestoreFixtures.makeError("Permission denied")
		let doc = FirestoreFixtures.makeDocument()

		sut.setDocument(doc, merge: false)

		XCTAssertEqual(emitter.lastDocumentWriteFailure?.error, "Permission denied")
	}
}

// MARK: - updateDocument

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: updateDocument — success
	// -----------------------------------------------------------------------

	func test_updateDocument_callsBackendOnce() {
		let doc = FirestoreFixtures.makeDocument()

		sut.updateDocument(doc)

		XCTAssertEqual(backend.updateDocumentCallCount, 1)
	}

	func test_updateDocument_emitsDocumentUpdated_onSuccess() {
		let doc = FirestoreFixtures.makeDocument()

		sut.updateDocument(doc)

		XCTAssertEqual(emitter.documentsUpdated.count, 1)
		XCTAssertTrue(emitter.documentUpdateFailures.isEmpty)
	}

	func test_updateDocument_emittedDocument_hasCorrectPath() {
		let doc = FirestoreFixtures.makeDocument(
			collection: "users",
			documentId: "u-42"
		)

		sut.updateDocument(doc)

		XCTAssertEqual(emitter.lastDocumentUpdated?.collection, "users")
		XCTAssertEqual(emitter.lastDocumentUpdated?.documentId, "u-42")
	}

	// -----------------------------------------------------------------------
	// MARK: updateDocument — failure
	// -----------------------------------------------------------------------

	func test_updateDocument_emitsUpdateFailed_onError() {
		backend.updateDocumentError = FirestoreFixtures.makeError("Document not found")
		let doc = FirestoreFixtures.makeDocument()

		sut.updateDocument(doc)

		XCTAssertEqual(emitter.documentUpdateFailures.count, 1)
		XCTAssertTrue(emitter.documentsUpdated.isEmpty)
	}

	func test_updateDocument_updateFailure_containsCollection() {
		backend.updateDocumentError = FirestoreFixtures.makeError()
		let doc = FirestoreFixtures.makeDocument(collection: "users")

		sut.updateDocument(doc)

		XCTAssertEqual(emitter.lastDocumentUpdateFailure?.collection, "users")
	}

	func test_updateDocument_updateFailure_containsDocumentId() {
		backend.updateDocumentError = FirestoreFixtures.makeError()
		let doc = FirestoreFixtures.makeDocument(documentId: "u-42")

		sut.updateDocument(doc)

		XCTAssertEqual(emitter.lastDocumentUpdateFailure?.documentId, "u-42")
	}

	func test_updateDocument_updateFailure_containsErrorMessage() {
		backend.updateDocumentError = FirestoreFixtures.makeError("Document not found")
		let doc = FirestoreFixtures.makeDocument()

		sut.updateDocument(doc)

		XCTAssertEqual(emitter.lastDocumentUpdateFailure?.error, "Document not found")
	}
}
