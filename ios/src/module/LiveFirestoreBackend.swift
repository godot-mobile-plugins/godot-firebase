//
// © 2026-present Firebase Team https://github.com/firebase-team
//

// This file is a member of the MODULE TARGET ONLY — not the test target.
// Keeping all FirebaseFirestore SDK references here means the test binary
// never links against FIRFirestore symbols, avoiding the
// "Undefined symbols: _OBJC_CLASS_$_FIRFirestore" linker error.

import FirebaseFirestore

// MARK: - LiveFirestoreBackend

/// Production `FirestoreBackend` that delegates every call to the Firebase
/// Firestore SDK.  Injected into `Firestore` by its `@objc convenience
/// init(emitter:)`, which is the sole entry point used by `firebase_plugin.mm`.
final class LiveFirestoreBackend: FirestoreBackend {

    private let db: FirebaseFirestore.Firestore

    init(db: FirebaseFirestore.Firestore = .firestore()) {
        self.db = db
    }

    func addDocument(
        toCollection collection: String,
        data: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        db.collection(collection).addDocument(data: data, completion: completion)
    }

    func setDocument(
        collection: String,
        documentId: String,
        data: [String: Any],
        merge: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        let ref = db.collection(collection).document(documentId)
        if merge {
            ref.setData(data, merge: true, completion: completion)
        } else {
            ref.setData(data, completion: completion)
        }
    }

    func updateDocument(
        collection: String,
        documentId: String,
        data: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        db.collection(collection).document(documentId).updateData(data, completion: completion)
    }

    func deleteDocument(
        collection: String,
        documentId: String,
        completion: @escaping (Error?) -> Void
    ) {
        db.collection(collection).document(documentId).delete(completion: completion)
    }

    func getDocument(
        collection: String,
        documentId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        db.collection(collection).document(documentId).getDocument { snapshot, error in
            if let error {
                completion(nil, error)
            } else if let snapshot, snapshot.exists, let data = snapshot.data() {
                completion(data, nil)
            } else {
                completion(nil, nil)    // document does not exist
            }
        }
    }

    func getCollection(
        collection: String,
        completion: @escaping ([String: [String: Any]]?, Error?) -> Void
    ) {
        db.collection(collection).getDocuments { snapshot, error in
            if let error {
                completion(nil, error)
            } else {
                let docs = snapshot?.documents.reduce(into: [String: [String: Any]]()) { acc, doc in
                    acc[doc.documentID] = doc.data()
                }
                completion(docs ?? [:], nil)
            }
        }
    }

    @discardableResult
    func addSnapshotListener(
        collection: String,
        documentId: String,
        onChange: @escaping ([String: Any]?, Error?) -> Void
    ) -> ListenerToken {
        let registration = db.collection(collection).document(documentId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(nil, error)
                } else if let snapshot, snapshot.exists, let data = snapshot.data() {
                    onChange(data, nil)
                } else {
                    onChange(nil, nil)   // deletion / non-existence
                }
            }

        let token = ListenerToken(key: "\(collection)/\(documentId)")
        // Store the Firebase registration inside the token so removeListener
        // can detach it.  Associated objects avoid adding a stored property to
        // the public ListenerToken type.
        objc_setAssociatedObject(
            token, &LiveFirestoreBackend.registrationKey,
            registration, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return token
    }

    func removeListener(token: ListenerToken) {
        let registration = objc_getAssociatedObject(
            token, &LiveFirestoreBackend.registrationKey
        ) as? ListenerRegistration
        registration?.remove()
    }

    // MARK: - Private

    private static var registrationKey: UInt8 = 0
}
