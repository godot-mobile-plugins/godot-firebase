//
// © 2026-present Firebase Team https://github.com/firebase-team
//

// NOTE: This file intentionally does NOT import FirebaseFirestore.
// The live Firebase backend lives in LiveFirestoreBackend.swift, which is
// a member of the module target only.  The test target compiles this file
// but not LiveFirestoreBackend.swift, so the test binary never references
// FIRFirestore symbols and the linker does not need the Firebase SDK.

import Foundation

// MARK: - ListenerToken

/// Opaque handle to an active real-time Firestore snapshot listener.
///
/// Production code: `LiveFirestoreBackend` stores a Firebase
/// `ListenerRegistration` inside this token via an associated object.
/// Test code: `MockFirestoreBackend` uses only the `key` string.
/// Neither caller inspects internals — detachment always goes through
/// `FirestoreBackend.removeListener(token:)`.
public final class ListenerToken {
    let key: String
    init(key: String) { self.key = key }
}

// MARK: - FirestoreBackend

/// Abstracts every Firebase Firestore SDK call made by the `Firestore` class.
///
/// - `LiveFirestoreBackend` (in `LiveFirestoreBackend.swift`, module target
///   only) is the production implementation.
/// - `MockFirestoreBackend` (in `FirestoreFixtures.swift`, test target only)
///   drives all callbacks synchronously for offline unit testing.
public protocol FirestoreBackend: AnyObject {

    /// Add a new document with an auto-generated ID.
    func addDocument(
        toCollection collection: String,
        data: [String: Any],
        completion: @escaping (Error?) -> Void
    )

    /// Create or overwrite a document at a specific path.
    func setDocument(
        collection: String,
        documentId: String,
        data: [String: Any],
        merge: Bool,
        completion: @escaping (Error?) -> Void
    )

    /// Update specific fields of an existing document.
    func updateDocument(
        collection: String,
        documentId: String,
        data: [String: Any],
        completion: @escaping (Error?) -> Void
    )

    /// Delete a document at a specific path.
    func deleteDocument(
        collection: String,
        documentId: String,
        completion: @escaping (Error?) -> Void
    )

    /// Fetch a single document.
    /// Completion receives `(data, nil)` on success, `(nil, nil)` when the
    /// document does not exist, or `(nil, error)` on failure.
    func getDocument(
        collection: String,
        documentId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    )

    /// Fetch all documents in a collection, keyed by Firestore document ID.
    func getCollection(
        collection: String,
        completion: @escaping ([String: [String: Any]]?, Error?) -> Void
    )

    /// Attach a real-time snapshot listener to a document.
    /// - Returns: A `ListenerToken` that must be passed to `removeListener` to detach.
    @discardableResult
    func addSnapshotListener(
        collection: String,
        documentId: String,
        onChange: @escaping ([String: Any]?, Error?) -> Void
    ) -> ListenerToken

    /// Detach a previously attached snapshot listener.
    func removeListener(token: ListenerToken)
}

// MARK: - Firestore

/// Handles all Firestore database operations for the Firebase Godot plugin.
///
/// Each method maps 1-to-1 with a `FirebasePlugin` C++ method and bridges
/// results into Godot signals via the `SignalEmitting` protocol.
///
/// The class is `@objc final` so `firebase_plugin.mm` can allocate and call
/// it as a plain Objective-C object.
///
/// Dependency injection: the designated `init(emitter:backend:)` accepts any
/// `FirestoreBackend`.  The `@objc convenience init(emitter:)` — the only
/// entry point called from `firebase_plugin.mm` — supplies `LiveFirestoreBackend`
/// from `LiveFirestoreBackend.swift`.  The test target never compiles that file,
/// so no Firebase SDK symbols are pulled into the test binary.
@objc final class Firestore: NSObject {

    // MARK: - Properties

    private let backend: any FirestoreBackend
    private let emitter: any SignalEmitting

    /// Active listener tokens, keyed by "collection/documentId".
    private var listenerTokens: [String: ListenerToken] = [:]

    // MARK: - Initialisation

    /// Testable initialiser — both collaborators are injected.
    init(emitter: any SignalEmitting, backend: any FirestoreBackend) {
        self.emitter = emitter
        self.backend = backend
        super.init()
    }

    /// Production initialiser called by `firebase_plugin.mm`.
    /// Guarded by `FIREBASE_PLUGIN_MODULE` (set only on the module target)
    /// so the test target never sees the reference to `LiveFirestoreBackend`.
    #if FIREBASE_PLUGIN_MODULE
    @objc convenience init(emitter: any SignalEmitting) {
        self.init(emitter: emitter, backend: LiveFirestoreBackend())
    }
    #endif

    // MARK: - Private Helpers

    private func listenerKey(collection: String, documentId: String) -> String {
        "\(collection)/\(documentId)"
    }

    // MARK: - Write Operations

    /// Adds a new document to `collection`; Firestore auto-generates the ID.
    @objc func addDocument(_ document: FirestoreDocument) {
        let collection = document.collection
        let data: [String: Any] = document.documentDataAsDictionary()

        backend.addDocument(toCollection: collection, data: data) { [weak self] (error: Error?) in
            guard let self else { return }
            if let error {
                self.emitter.emitDocumentWriteFailed(
                    FirestoreError(collection: collection, documentId: nil,
                                   error: error.localizedDescription))
            } else {
                self.emitter.emitDocumentWritten(document)
            }
        }
    }

    /// Creates or overwrites a document at the path encoded in `document`.
    /// When `merge` is `true`, fields absent from the payload are preserved.
    @objc func setDocument(_ document: FirestoreDocument, merge: Bool) {
        let collection = document.collection
        let documentId = document.documentId
        let data: [String: Any] = document.documentDataAsDictionary()

        backend.setDocument(
            collection: collection, documentId: documentId,
            data: data, merge: merge
        ) { [weak self] (error: Error?) in
            guard let self else { return }
            if let error {
                self.emitter.emitDocumentWriteFailed(
                    FirestoreError(collection: collection, documentId: documentId,
                                   error: error.localizedDescription))
            } else {
                self.emitter.emitDocumentWritten(document)
            }
        }
    }

    /// Updates specific fields of an existing document.
    /// Fails (emits `emitDocumentUpdateFailed`) if the document does not exist.
    @objc func updateDocument(_ document: FirestoreDocument) {
        let collection = document.collection
        let documentId = document.documentId
        let data: [String: Any] = document.documentDataAsDictionary()

        backend.updateDocument(
            collection: collection, documentId: documentId, data: data
        ) { [weak self] (error: Error?) in
            guard let self else { return }
            if let error {
                self.emitter.emitDocumentUpdateFailed(
                    FirestoreError(collection: collection, documentId: documentId,
                                   error: error.localizedDescription))
            } else {
                self.emitter.emitDocumentUpdated(document)
            }
        }
    }

    /// Permanently deletes a document from Firestore.
    @objc func deleteDocument(_ collection: String, documentId: String) {
        backend.deleteDocument(collection: collection, documentId: documentId) { [weak self] (error: Error?) in
            guard let self else { return }
            if let error {
                self.emitter.emitDocumentDeleteFailed(
                    FirestoreError(collection: collection, documentId: documentId,
                                   error: error.localizedDescription))
            } else {
                self.emitter.emitDocumentDeleted(
                    FirestoreDocument(collection: collection, documentId: documentId,
                                      documentData: nil))
            }
        }
    }

    // MARK: - Read Operations

    /// Fetches a single document by collection path and document ID.
    @objc func getDocument(_ collection: String, documentId: String) {
        backend.getDocument(
            collection: collection, documentId: documentId
        ) { [weak self] (data: [String: Any]?, error: Error?) in
            guard let self else { return }

            if let error {
                self.emitter.emitDocumentQueryFailed(
                    FirestoreError(collection: collection, documentId: documentId,
                                   error: error.localizedDescription))
                return
            }

            guard let data else {
                self.emitter.emitDocumentQueryFailed(
                    FirestoreError(collection: collection, documentId: documentId,
                                   error: "Document not found."))
                return
            }

            let document = FirestoreDocument(collection: collection, documentId: documentId,
                                             documentData: nil)
            document.populateDocumentData(data)
            self.emitter.emitDocumentQueryCompleted(document)
        }
    }

    /// Fetches every document in a collection.
    /// The emitted `FirestoreResult` is keyed by Firestore document ID.
    @objc func getCollection(_ collection: String) {
        backend.getCollection(
            collection: collection
        ) { [weak self] (documents: [String: [String: Any]]?, error: Error?) in
            guard let self else { return }

            if let error {
                self.emitter.emitCollectionQueryFailed(
                    FirestoreError(collection: collection, documentId: nil,
                                   error: error.localizedDescription))
                return
            }

            let result = FirestoreResult(collection: collection, documents: nil)
            result.populateDocuments(documents ?? [:])
            self.emitter.emitCollectionQueryCompleted(result)
        }
    }

    // MARK: - Real-time Listeners

    /// Attaches a real-time snapshot listener to the specified document.
    /// Data changes fire `emitDocumentChanged`.  Deletion events (nil data,
    /// no error) are silently ignored.  Re-calling for the same path is a no-op.
    @objc func trackDocument(_ collection: String, documentId: String) {
        let key = listenerKey(collection: collection, documentId: documentId)
        guard listenerTokens[key] == nil else { return }

        let token = backend.addSnapshotListener(
            collection: collection, documentId: documentId
        ) { [weak self] (data: [String: Any]?, error: Error?) in
            guard let self else { return }

            if let error {
                self.emitter.emitDocumentQueryFailed(
                    FirestoreError(collection: collection, documentId: documentId,
                                   error: error.localizedDescription))
                return
            }

            guard let data else { return }   // deletion / non-existence — ignore

            let document = FirestoreDocument(collection: collection, documentId: documentId,
                                             documentData: nil)
            document.populateDocumentData(data)
            self.emitter.emitDocumentChanged(document)
        }

        listenerTokens[key] = token
    }

    /// Detaches the real-time listener for the specified document.
    /// Calling this for a path that is not tracked is a no-op.
    @objc func stopTrackingDocument(_ collection: String, documentId: String) {
        let key = listenerKey(collection: collection, documentId: documentId)
        if let token = listenerTokens.removeValue(forKey: key) {
            backend.removeListener(token: token)
        }
    }
}
