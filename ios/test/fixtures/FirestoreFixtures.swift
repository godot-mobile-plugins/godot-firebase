//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin    // adjust to your actual module name
import Foundation
import XCTest

// MARK: - MockFirestoreEmitter

/// Captures every Firestore signal emitted by the Firestore class so tests can
/// assert on outcomes without needing a live Godot object.
final class MockFirestoreEmitter: NSObject, SignalEmitting {

    // -----------------------------------------------------------------------
    // MARK: Captured Firestore signals
    // -----------------------------------------------------------------------

    private(set) var documentsWritten: [FirestoreDocument] = []
    private(set) var documentWriteFailures: [FirestoreError] = []
    private(set) var documentsUpdated: [FirestoreDocument] = []
    private(set) var documentUpdateFailures: [FirestoreError] = []
    private(set) var documentsDeleted: [FirestoreDocument] = []
    private(set) var documentDeleteFailures: [FirestoreError] = []
    private(set) var documentsChanged: [FirestoreDocument] = []
    private(set) var documentQueryResults: [FirestoreDocument] = []
    private(set) var documentQueryFailures: [FirestoreError] = []
    private(set) var collectionQueryResults: [FirestoreResult] = []
    private(set) var collectionQueryFailures: [FirestoreError] = []

    // Convenience last-value accessors
    var lastDocumentWritten: FirestoreDocument?        { documentsWritten.last }
    var lastDocumentWriteFailure: FirestoreError?      { documentWriteFailures.last }
    var lastDocumentUpdated: FirestoreDocument?        { documentsUpdated.last }
    var lastDocumentUpdateFailure: FirestoreError?     { documentUpdateFailures.last }
    var lastDocumentDeleted: FirestoreDocument?        { documentsDeleted.last }
    var lastDocumentDeleteFailure: FirestoreError?     { documentDeleteFailures.last }
    var lastDocumentChanged: FirestoreDocument?        { documentsChanged.last }
    var lastDocumentQueryResult: FirestoreDocument?    { documentQueryResults.last }
    var lastDocumentQueryFailure: FirestoreError?      { documentQueryFailures.last }
    var lastCollectionQueryResult: FirestoreResult?    { collectionQueryResults.last }
    var lastCollectionQueryFailure: FirestoreError?    { collectionQueryFailures.last }

    func reset() {
        documentsWritten          = []
        documentWriteFailures     = []
        documentsUpdated          = []
        documentUpdateFailures    = []
        documentsDeleted          = []
        documentDeleteFailures    = []
        documentsChanged          = []
        documentQueryResults      = []
        documentQueryFailures     = []
        collectionQueryResults    = []
        collectionQueryFailures   = []
    }

    // -----------------------------------------------------------------------
    // MARK: SignalEmitting — Authentication (no-ops for Firestore tests)
    // -----------------------------------------------------------------------

    func emitAuthSuccess(_ user: GodotFirebaseUser) {}
    func emitAuthFailure(_ error: String) {}
    func emitLinkSuccess(_ user: GodotFirebaseUser) {}
    func emitLinkFailure(_ error: String) {}
    func emitSignOutSuccess(_ success: Bool) {}
    func emitPasswordResetSent(_ success: Bool) {}
    func emitEmailVerificationSent(_ success: Bool) {}
    func emitUserDeleted(_ success: Bool) {}

    // -----------------------------------------------------------------------
    // MARK: SignalEmitting — Firestore
    // -----------------------------------------------------------------------

    func emitDocumentWritten(_ document: FirestoreDocument)          { documentsWritten.append(document) }
    func emitDocumentWriteFailed(_ error: FirestoreError)            { documentWriteFailures.append(error) }
    func emitDocumentUpdated(_ document: FirestoreDocument)          { documentsUpdated.append(document) }
    func emitDocumentUpdateFailed(_ error: FirestoreError)           { documentUpdateFailures.append(error) }
    func emitDocumentDeleted(_ document: FirestoreDocument)          { documentsDeleted.append(document) }
    func emitDocumentDeleteFailed(_ error: FirestoreError)           { documentDeleteFailures.append(error) }
    func emitDocumentChanged(_ result: FirestoreDocument)            { documentsChanged.append(result) }
    func emitDocumentQueryCompleted(_ result: FirestoreDocument)     { documentQueryResults.append(result) }
    func emitDocumentQueryFailed(_ error: FirestoreError)            { documentQueryFailures.append(error) }
    func emitCollectionQueryCompleted(_ result: FirestoreResult)     { collectionQueryResults.append(result) }
    func emitCollectionQueryFailed(_ error: FirestoreError)          { collectionQueryFailures.append(error) }
}

// MARK: - MockFirestoreBackend

/// In-memory `FirestoreBackend` that drives all completion handlers
/// **synchronously** so tests remain single-threaded and need no
/// `XCTestExpectation`.
///
/// `FirestoreBackend` is defined in `FirestoreBackend.swift` (module target)
/// and is therefore visible here via `@testable import`.
final class MockFirestoreBackend: FirestoreBackend {

    // -----------------------------------------------------------------------
    // MARK: Per-operation error stubs
    // -----------------------------------------------------------------------

    /// Non-nil → `addDocument` completion delivers this error.
    var addDocumentError: Error?

    /// Non-nil → `setDocument` completion delivers this error.
    var setDocumentError: Error?

    /// Non-nil → `updateDocument` completion delivers this error.
    var updateDocumentError: Error?

    /// Non-nil → `deleteDocument` completion delivers this error.
    var deleteDocumentError: Error?

    /// Non-nil → `getDocument` completion delivers this error.
    var getDocumentError: Error?

    /// `true` → `getDocument` reports the document as non-existent (nil data, nil error).
    var documentNotFound: Bool = false

    /// Data returned by `getDocument` on success.
    var documentData: [String: Any]?

    /// Non-nil → `getCollection` completion delivers this error.
    var getCollectionError: Error?

    /// Data returned by `getCollection` on success, keyed by document ID.
    var collectionData: [String: [String: Any]] = [:]

    // -----------------------------------------------------------------------
    // MARK: Snapshot listener control
    // -----------------------------------------------------------------------

    /// Active listeners stored by "collection/documentId" key.
    private var listeners: [String: ([String: Any]?, Error?) -> Void] = [:]

    /// Data delivered to the snapshot callback when `fireSnapshot` is called.
    var snapshotData: [String: Any]?

    /// Error delivered to the snapshot callback when `fireSnapshotError` is called.
    var snapshotError: Error?

    /// Manually triggers the snapshot listener for the given path with `snapshotData`.
    func fireSnapshot(collection: String, documentId: String) {
        listeners["\(collection)/\(documentId)"]?(snapshotData, nil)
    }

    /// Manually triggers the snapshot listener for the given path with `snapshotError`.
    func fireSnapshotError(collection: String, documentId: String) {
        listeners["\(collection)/\(documentId)"]?(nil, snapshotError)
    }

    // -----------------------------------------------------------------------
    // MARK: Call counters (for "called exactly once" assertions)
    // -----------------------------------------------------------------------

    private(set) var addDocumentCallCount    = 0
    private(set) var setDocumentCallCount    = 0
    private(set) var updateDocumentCallCount = 0
    private(set) var deleteDocumentCallCount = 0
    private(set) var getDocumentCallCount    = 0
    private(set) var getCollectionCallCount  = 0
    private(set) var addListenerCallCount    = 0
    private(set) var removeListenerCallCount = 0

    // -----------------------------------------------------------------------
    // MARK: FirestoreBackend
    // -----------------------------------------------------------------------

    func addDocument(
        toCollection collection: String,
        data: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        addDocumentCallCount += 1
        completion(addDocumentError)
    }

    func setDocument(
        collection: String,
        documentId: String,
        data: [String: Any],
        merge: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        setDocumentCallCount += 1
        completion(setDocumentError)
    }

    func updateDocument(
        collection: String,
        documentId: String,
        data: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        updateDocumentCallCount += 1
        completion(updateDocumentError)
    }

    func deleteDocument(
        collection: String,
        documentId: String,
        completion: @escaping (Error?) -> Void
    ) {
        deleteDocumentCallCount += 1
        completion(deleteDocumentError)
    }

    func getDocument(
        collection: String,
        documentId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        getDocumentCallCount += 1
        if let error = getDocumentError {
            completion(nil, error)
        } else if documentNotFound {
            completion(nil, nil)        // exists == false
        } else {
            completion(documentData, nil)
        }
    }

    func getCollection(
        collection: String,
        completion: @escaping ([String: [String: Any]]?, Error?) -> Void
    ) {
        getCollectionCallCount += 1
        if let error = getCollectionError {
            completion(nil, error)
        } else {
            completion(collectionData, nil)
        }
    }

    @discardableResult
    func addSnapshotListener(
        collection: String,
        documentId: String,
        onChange: @escaping ([String: Any]?, Error?) -> Void
    ) -> ListenerToken {
        addListenerCallCount += 1
        let key = "\(collection)/\(documentId)"
        listeners[key] = onChange
        return ListenerToken(key: key)
    }

    func removeListener(token: ListenerToken) {
        removeListenerCallCount += 1
        listeners.removeValue(forKey: token.key)
    }
}

// MARK: - FirestoreFixtures

/// Factory helpers shared across all Firestore test classes.
enum FirestoreFixtures {

    // -----------------------------------------------------------------------
    // MARK: Constants
    // -----------------------------------------------------------------------

    static let defaultCollection = "users"
    static let defaultDocumentId = "doc-001"
    static let altCollection     = "messages"
    static let altDocumentId     = "msg-999"

    // -----------------------------------------------------------------------
    // MARK: FirestoreDocument builders
    // -----------------------------------------------------------------------

    /// A document with minimal but complete data.
    static func makeDocument(
        collection: String = defaultCollection,
        documentId: String = defaultDocumentId,
        data: [String: Any] = ["name": "Alice", "score": 42]
    ) -> FirestoreDocument {
        let doc = FirestoreDocument(collection: collection, documentId: documentId,
                                    documentData: nil)
        doc.populateDocumentData(data)
        return doc
    }

    /// A document whose data exercises every Variant type the bridge must handle.
    static func makeDocumentWithAllTypes() -> FirestoreDocument {
        let data: [String: Any] = [
            "string_field": "hello",
            "int_field":    NSNumber(value: Int64(99)),
            "float_field":  NSNumber(value: Double(3.14)),
            "bool_field":   NSNumber(value: true),
            "nested_dict":  ["key": "value"],
            "array_field":  ["a", "b", "c"],
        ]
        return makeDocument(data: data)
    }

    /// A document with no data payload (simulates a newly created shell).
    static func makeEmptyDocument(
        collection: String = defaultCollection,
        documentId: String = defaultDocumentId
    ) -> FirestoreDocument {
        FirestoreDocument(collection: collection, documentId: documentId, documentData: nil)
    }

    // -----------------------------------------------------------------------
    // MARK: FirestoreResult builders
    // -----------------------------------------------------------------------

    /// A collection result containing two documents.
    static func makeResult(
        collection: String = defaultCollection,
        documents: [String: Any] = [
            "doc-001": ["name": "Alice"],
            "doc-002": ["name": "Bob"],
        ]
    ) -> FirestoreResult {
        let result = FirestoreResult(collection: collection, documents: nil)
        result.populateDocuments(documents)
        return result
    }

    /// An empty collection result.
    static func makeEmptyResult(collection: String = defaultCollection) -> FirestoreResult {
        FirestoreResult(collection: collection, documents: nil)
    }

    // -----------------------------------------------------------------------
    // MARK: FirestoreError builder
    // -----------------------------------------------------------------------

    static func makeFirestoreError(
        collection: String? = defaultCollection,
        documentId: String? = defaultDocumentId,
        message: String = "Test Firestore error"
    ) -> FirestoreError {
        FirestoreError(collection: collection, documentId: documentId, error: message)
    }

    // -----------------------------------------------------------------------
    // MARK: NSError builder
    // -----------------------------------------------------------------------

    static func makeError(_ message: String = "Test error") -> NSError {
        NSError(
            domain: "com.test.firestore",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    // -----------------------------------------------------------------------
    // MARK: SUT factory
    // -----------------------------------------------------------------------

    /// Creates a `Firestore` SUT wired to in-memory collaborators.
    ///
    /// - Returns: A labelled tuple of `(sut, emitter, backend)` so each test
    ///   can configure the backend before exercising an operation.
    static func makeSUT(
        emitter: MockFirestoreEmitter = MockFirestoreEmitter(),
        backend: MockFirestoreBackend = MockFirestoreBackend()
    ) -> (sut: Firestore, emitter: MockFirestoreEmitter, backend: MockFirestoreBackend) {
        let sut = Firestore(emitter: emitter, backend: backend)
        return (sut, emitter, backend)
    }
}
