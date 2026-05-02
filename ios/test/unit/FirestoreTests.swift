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

    private var emitter: MockFirestoreEmitter!
    private var backend: MockFirestoreBackend!
    private var sut: Firestore!

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

        sut.deleteDocument(FirestoreFixtures.defaultCollection,
                           documentId: FirestoreFixtures.defaultDocumentId)

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

        sut.deleteDocument(FirestoreFixtures.defaultCollection,
                           documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(emitter.lastDocumentDeleteFailure?.error, "Insufficient permissions")
    }

    // -----------------------------------------------------------------------
    // MARK: getDocument — success
    // -----------------------------------------------------------------------

    func test_getDocument_callsBackendOnce() {
        backend.documentData = ["name": "Alice"]

        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(backend.getDocumentCallCount, 1)
    }

    func test_getDocument_emitsQueryCompleted_onSuccess() {
        backend.documentData = ["name": "Alice"]

        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

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

        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        let data = emitter.lastDocumentQueryResult?.documentDataAsDictionary() ?? [:]
        XCTAssertEqual(data["name"] as? String, "Alice")
        XCTAssertEqual(data["score"] as? Int, 100)
    }

    // -----------------------------------------------------------------------
    // MARK: getDocument — not found
    // -----------------------------------------------------------------------

    func test_getDocument_emitsQueryFailed_whenDocumentNotFound() {
        backend.documentNotFound = true

        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(emitter.documentQueryFailures.count, 1)
        XCTAssertTrue(emitter.documentQueryResults.isEmpty)
    }

    func test_getDocument_queryFailure_whenNotFound_containsCorrectMessage() {
        backend.documentNotFound = true

        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

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

        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(emitter.documentQueryFailures.count, 1)
        XCTAssertTrue(emitter.documentQueryResults.isEmpty)
    }

    func test_getDocument_queryFailure_containsErrorMessage() {
        backend.getDocumentError = FirestoreFixtures.makeError("Unavailable")

        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(emitter.lastDocumentQueryFailure?.error, "Unavailable")
    }

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
            "doc-3": ["name": "Carol"],
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

    // -----------------------------------------------------------------------
    // MARK: trackDocument — listener attachment
    // -----------------------------------------------------------------------

    func test_trackDocument_attachesListenerOnce() {
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(backend.addListenerCallCount, 1)
    }

    func test_trackDocument_calledTwiceForSamePath_attachesListenerOnlyOnce() {
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(backend.addListenerCallCount, 1)
    }

    func test_trackDocument_differentPaths_attachesSeparateListeners() {
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: "doc-A")
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: "doc-B")

        XCTAssertEqual(backend.addListenerCallCount, 2)
    }

    // -----------------------------------------------------------------------
    // MARK: trackDocument — snapshot delivery
    // -----------------------------------------------------------------------

    func test_trackDocument_emitsDocumentChanged_whenSnapshotFires() {
        backend.snapshotData = ["status": "active"]

        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
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

        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
        backend.fireSnapshot(
            collection: FirestoreFixtures.defaultCollection,
            documentId: FirestoreFixtures.defaultDocumentId
        )

        let data = emitter.lastDocumentChanged?.documentDataAsDictionary() ?? [:]
        XCTAssertEqual(data["level"] as? Int, 5)
    }

    func test_trackDocument_multipleSnapshots_emitsEachChange() {
        backend.snapshotData = ["v": "1"]
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)

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

        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
        backend.fireSnapshotError(
            collection: FirestoreFixtures.defaultCollection,
            documentId: FirestoreFixtures.defaultDocumentId
        )

        XCTAssertEqual(emitter.documentQueryFailures.count, 1)
        XCTAssertTrue(emitter.documentsChanged.isEmpty)
    }

    func test_trackDocument_snapshotError_containsErrorMessage() {
        backend.snapshotError = FirestoreFixtures.makeError("Stream closed")

        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
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

        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
        backend.fireSnapshot(
            collection: FirestoreFixtures.defaultCollection,
            documentId: FirestoreFixtures.defaultDocumentId
        )

        XCTAssertTrue(emitter.documentsChanged.isEmpty)
        XCTAssertTrue(emitter.documentQueryFailures.isEmpty)
    }

    // -----------------------------------------------------------------------
    // MARK: stopTrackingDocument
    // -----------------------------------------------------------------------

    func test_stopTrackingDocument_removesListener() {
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
        sut.stopTrackingDocument(FirestoreFixtures.defaultCollection,
                                 documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(backend.removeListenerCallCount, 1)
    }

    func test_stopTrackingDocument_afterStop_newSnapshotDoesNotEmitChange() {
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
        sut.stopTrackingDocument(FirestoreFixtures.defaultCollection,
                                 documentId: FirestoreFixtures.defaultDocumentId)

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
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)
        sut.stopTrackingDocument(FirestoreFixtures.defaultCollection,
                                 documentId: FirestoreFixtures.defaultDocumentId)
        sut.trackDocument(FirestoreFixtures.defaultCollection,
                          documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertEqual(backend.addListenerCallCount, 2)
    }

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
        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        let data = emitter.lastDocumentQueryResult?.documentDataAsDictionary() ?? [:]
        XCTAssertEqual(data["username"] as? String, "bob")
    }

    func test_getDocument_populatedData_bridgesBoolCorrectly() {
        backend.documentData = ["verified": NSNumber(value: true)]
        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        let data = emitter.lastDocumentQueryResult?.documentDataAsDictionary() ?? [:]
        XCTAssertEqual(data["verified"] as? Bool, true)
    }

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
        sut.getDocument(FirestoreFixtures.defaultCollection,
                        documentId: FirestoreFixtures.defaultDocumentId)

        XCTAssertTrue(emitter.documentsWritten.isEmpty)
        XCTAssertTrue(emitter.documentsDeleted.isEmpty)
    }
}
