//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.fixtures

import com.google.firebase.firestore.CollectionReference
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.QuerySnapshot
import io.mockk.every
import io.mockk.mockk
import org.godotengine.godot.Dictionary
import org.godotengine.plugin.firebase.model.FirestoreDocument
import org.godotengine.plugin.firebase.model.FirestoreError
import org.godotengine.plugin.firebase.model.FirestoreResult

/**
 * Central factory for Firestore-related test fixtures used across the Firebase
 * plugin test suite.
 *
 * Complements the auth-focused [Fixtures] object with:
 *  - Pre-configured [CollectionReference] / [DocumentReference] mocks
 *  - Pre-configured [DocumentSnapshot] and [QuerySnapshot] mocks
 *  - A relaxed [ListenerRegistration] mock for real-time listener tests
 *  - Convenience builders for [FirestoreDocument], [FirestoreError], and [FirestoreResult]
 *
 * All snapshot mocks wire up the full reference graph
 * (`snapshot.reference.parent.path`) so that constructors in the model layer
 * that access those fields do not throw.
 */
object FirestoreFixtures {
    // -------------------------------------------------------------------------
    // CollectionReference
    // -------------------------------------------------------------------------

    /**
     * Returns a mocked [CollectionReference] whose [CollectionReference.path]
     * returns [path].
     */
    fun mockCollectionReference(path: String = "test-collection"): CollectionReference =
        mockk<CollectionReference>().also {
            every { it.path } returns path
        }

    // -------------------------------------------------------------------------
    // DocumentReference
    // -------------------------------------------------------------------------

    /**
     * Returns a relaxed mocked [DocumentReference] with [id] and a parent
     * [CollectionReference] whose path is [collectionPath].
     *
     * Relaxed so that callers can override only the specific interactions they
     * care about while the rest silently no-op.
     */
    fun mockDocumentReference(
        id: String = "doc-123",
        collectionPath: String = "test-collection",
    ): DocumentReference {
        val mockColl = mockCollectionReference(collectionPath)
        return mockk<DocumentReference>(relaxed = true).also { ref ->
            every { ref.id } returns id
            every { ref.parent } returns mockColl
        }
    }

    // -------------------------------------------------------------------------
    // DocumentSnapshot
    // -------------------------------------------------------------------------

    /**
     * Returns a mocked [DocumentSnapshot] with the given field values.
     *
     * When [exists] is `false`, [DocumentSnapshot.data] returns `null` to
     * mirror Firestore's own behaviour for absent documents.
     */
    fun mockDocumentSnapshot(
        id: String = "doc-123",
        collectionPath: String = "test-collection",
        data: Map<String, Any?> = mapOf("field" to "value"),
        exists: Boolean = true,
    ): DocumentSnapshot {
        val docRef = mockDocumentReference(id, collectionPath)
        return mockk<DocumentSnapshot>().also { snapshot ->
            every { snapshot.id } returns id
            every { snapshot.exists() } returns exists
            every { snapshot.data } returns if (exists) data else null
            every { snapshot.reference } returns docRef
        }
    }

    /**
     * Returns a [DocumentSnapshot] mock whose data map contains nested
     * structures (a nested map and a list), useful for testing
     * [Firestore.convertValueToGodotType] via [Firestore.getDocument] /
     * [Firestore.trackDocument].
     */
    fun mockNestedDocumentSnapshot(
        id: String = "doc-nested",
        collectionPath: String = "test-collection",
    ): DocumentSnapshot =
        mockDocumentSnapshot(
            id = id,
            collectionPath = collectionPath,
            data =
                mapOf(
                    "name" to "Alice",
                    "meta" to mapOf("level" to 5, "active" to true),
                    "tags" to listOf("hero", "warrior"),
                ),
        )

    // -------------------------------------------------------------------------
    // QuerySnapshot
    // -------------------------------------------------------------------------

    /**
     * Returns a mocked [QuerySnapshot] whose [QuerySnapshot.documents] list
     * contains [documents]. Defaults to an empty list (empty collection result).
     */
    fun mockQuerySnapshot(documents: List<DocumentSnapshot> = emptyList()): QuerySnapshot =
        mockk<QuerySnapshot>().also { qs ->
            every { qs.documents } returns documents
        }

    // -------------------------------------------------------------------------
    // ListenerRegistration
    // -------------------------------------------------------------------------

    /**
     * Returns a relaxed [ListenerRegistration] mock. All interactions
     * (including [ListenerRegistration.remove]) silently succeed.
     */
    fun mockListenerRegistration(): ListenerRegistration = mockk(relaxed = true)

    // -------------------------------------------------------------------------
    // FirestoreDocument
    // -------------------------------------------------------------------------

    /**
     * Constructs a [FirestoreDocument] via the raw [Dictionary] constructor so
     * tests control every key precisely.
     *
     * Omitting [data] produces a document with no [FirestoreDocument.DOCUMENT_DATA_PROPERTY]
     * entry, which mirrors what [Firestore.setDocument] / [Firestore.deleteDocument]
     * emit after a successful write.
     */
    fun firestoreDocument(
        collection: String = "test-collection",
        documentId: String = "doc-123",
        data: Dictionary? = null,
    ): FirestoreDocument {
        val dict = Dictionary()
        dict[FirestoreDocument.COLLECTION_PROPERTY] = collection
        dict[FirestoreDocument.DOCUMENT_ID_PROPERTY] = documentId
        if (data != null) {
            dict[FirestoreDocument.DOCUMENT_DATA_PROPERTY] = data
        }
        return FirestoreDocument(dict)
    }

    /**
     * Returns a [FirestoreDocument] pre-populated with sample document data,
     * ready to pass into [Firestore.addDocument] / [Firestore.setDocument] /
     * [Firestore.updateDocument].
     */
    fun firestoreDocumentWithData(
        collection: String = "test-collection",
        documentId: String = "doc-123",
    ): FirestoreDocument {
        val data = Dictionary()
        data["name"] = "Alice"
        data["score"] = 42
        return firestoreDocument(collection, documentId, data)
    }

    // -------------------------------------------------------------------------
    // FirestoreError
    // -------------------------------------------------------------------------

    /**
     * Returns a [FirestoreError] with sensible defaults. Pass `documentId = null`
     * to simulate collection-level errors where no specific document is known.
     */
    fun firestoreError(
        collection: String = "test-collection",
        documentId: String? = "doc-123",
        error: String = "Test error",
    ): FirestoreError = FirestoreError(collection, documentId, error)

    // -------------------------------------------------------------------------
    // FirestoreResult
    // -------------------------------------------------------------------------

    /**
     * Returns a [FirestoreResult] with an optional pre-built [documents]
     * dictionary. Passing `null` simulates a result with no document data yet
     * set (equivalent to the no-document constructor).
     */
    fun firestoreResult(
        collection: String = "test-collection",
        documents: Dictionary? = null,
    ): FirestoreResult = FirestoreResult(collection, documents)
}
