//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin
import XCTest

// MARK: - trackDocument

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: trackDocument — listener attachment
	// -----------------------------------------------------------------------

	func test_trackDocument_attachesListenerOnce() {
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(backend.addListenerCallCount, 1)
	}

	func test_trackDocument_calledTwiceForSamePath_attachesListenerOnlyOnce() {
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(backend.addListenerCallCount, 1)
	}

	func test_trackDocument_differentPaths_attachesSeparateListeners() {
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: "doc-A")
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: "doc-B")

		XCTAssertEqual(backend.addListenerCallCount, 2)
	}

	// -----------------------------------------------------------------------
	// MARK: trackDocument — snapshot delivery
	// -----------------------------------------------------------------------

	func test_trackDocument_emitsDocumentChanged_whenSnapshotFires() {
		backend.snapshotData = ["status": "active"]

		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		backend.fireSnapshot(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)

		XCTAssertEqual(emitter.documentsChanged.count, 1)
		XCTAssertTrue(emitter.documentQueryFailures.isEmpty)
	}

	func test_trackDocument_emittedChange_hasCorrectPath() {
		backend.snapshotData = ["x": "y"]

		sut.trackDocument("events", documentId: "evt-1")
		backend.fireSnapshot(collection: "events", documentId: "evt-1")

		XCTAssertEqual(emitter.lastDocumentChanged?.collection, "events")
		XCTAssertEqual(emitter.lastDocumentChanged?.documentId, "evt-1")
	}

	func test_trackDocument_emittedChange_containsSnapshotData() {
		backend.snapshotData = ["level": NSNumber(value: 5)]

		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		backend.fireSnapshot(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)

		let data = emitter.lastDocumentChanged?.documentDataAsDictionary() ?? [:]
		XCTAssertEqual(data["level"] as? Int, 5)
	}

	func test_trackDocument_multipleSnapshots_emitsEachChange() {
		backend.snapshotData = ["v": "1"]
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		backend.fireSnapshot(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)
		backend.snapshotData = ["v": "2"]
		backend.fireSnapshot(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)

		XCTAssertEqual(emitter.documentsChanged.count, 2)
	}

	// -----------------------------------------------------------------------
	// MARK: trackDocument — snapshot error
	// -----------------------------------------------------------------------

	func test_trackDocument_emitsDocumentQueryFailed_onSnapshotError() {
		backend.snapshotError = FirestoreFixtures.makeError("Stream closed")

		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		backend.fireSnapshotError(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)

		XCTAssertEqual(emitter.documentQueryFailures.count, 1)
		XCTAssertTrue(emitter.documentsChanged.isEmpty)
	}

	func test_trackDocument_snapshotError_containsErrorMessage() {
		backend.snapshotError = FirestoreFixtures.makeError("Stream closed")

		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		backend.fireSnapshotError(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)

		XCTAssertEqual(emitter.lastDocumentQueryFailure?.error, "Stream closed")
	}

	func test_trackDocument_nilSnapshot_doesNotEmitChange() {
		// A nil snapshot with no error simulates a document deletion event;
		// the implementation silently ignores it (no signal emitted).
		backend.snapshotData = nil
		backend.snapshotError = nil

		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		backend.fireSnapshot(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)

		XCTAssertTrue(emitter.documentsChanged.isEmpty)
		XCTAssertTrue(emitter.documentQueryFailures.isEmpty)
	}
}

// MARK: - stopTrackingDocument

extension FirestoreTests {

	// -----------------------------------------------------------------------
	// MARK: stopTrackingDocument
	// -----------------------------------------------------------------------

	func test_stopTrackingDocument_removesListener() {
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		sut.stopTrackingDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(backend.removeListenerCallCount, 1)
	}

	func test_stopTrackingDocument_afterStop_newSnapshotDoesNotEmitChange() {
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		sut.stopTrackingDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		backend.snapshotData = ["x": "y"]
		backend.fireSnapshot(
			collection: FirestoreFixtures.defaultCollection,
			documentId: FirestoreFixtures.defaultDocumentId
		)

		XCTAssertTrue(emitter.documentsChanged.isEmpty)
	}

	func test_stopTrackingDocument_thatWasNeverTracked_doesNotCrash() {
		// Should be a no-op — must not throw or crash.
		sut.stopTrackingDocument("ghost", documentId: "ghost-doc")

		XCTAssertEqual(backend.removeListenerCallCount, 0)
	}

	func test_stopTracking_onePath_doesNotAffectOtherListener() {
		backend.snapshotData = ["keep": "me"]
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: "doc-A")
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: "doc-B")

		sut.stopTrackingDocument(FirestoreFixtures.defaultCollection, documentId: "doc-A")

		// doc-B listener still fires
		backend.fireSnapshot(
			collection: FirestoreFixtures.defaultCollection, documentId: "doc-B"
		)

		XCTAssertEqual(emitter.documentsChanged.count, 1)
		XCTAssertEqual(emitter.lastDocumentChanged?.documentId, "doc-B")
	}

	func test_retrackDocument_afterStop_attachesNewListener() {
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		sut.stopTrackingDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)
		sut.trackDocument(FirestoreFixtures.defaultCollection, documentId: FirestoreFixtures.defaultDocumentId)

		XCTAssertEqual(backend.addListenerCallCount, 2)
	}
}
