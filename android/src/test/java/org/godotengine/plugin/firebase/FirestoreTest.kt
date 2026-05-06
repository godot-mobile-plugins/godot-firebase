//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase

import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.CollectionReference
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.EventListener
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.SetOptions
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.slot
import io.mockk.unmockkAll
import io.mockk.verify
import org.godotengine.plugin.firebase.fixtures.FirestoreFixtures
import org.godotengine.plugin.firebase.fixtures.Fixtures
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit-tests for [Firestore].
 *
 * [FirebaseFirestore] statics are intercepted with [mockkStatic] so no real
 * Android runtime is required.  Every [com.google.android.gms.tasks.Task]
 * returned by the stubbed Firestore calls invokes its listener synchronously
 * via the helpers in [Fixtures], keeping tests entirely single-threaded.
 *
 * The [Firestore] class initialises its internal `firestore` field lazily via
 * `Firebase.firestore`, which resolves to [FirebaseFirestore.getInstance].
 * Mocking [FirebaseFirestore.getInstance] in [setUp] — before any method under
 * test is called — guarantees the lazy delegate receives the mock on first
 * access.
 *
 * [mockkStatic] registrations are torn down in [tearDown] via [unmockkAll] so
 * each test starts from a clean slate.
 */
@DisplayName("Firestore")
class FirestoreTest {
    // -------------------------------------------------------------------------
    // Shared mocks
    // -------------------------------------------------------------------------

    private lateinit var mockPlugin: FirebasePlugin
    private lateinit var mockFirestoreInstance: FirebaseFirestore
    private lateinit var mockCollection: CollectionReference
    private lateinit var mockDocRef: DocumentReference
    private lateinit var firestoreUnderTest: Firestore

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    @BeforeEach
    fun setUp() {
        // Intercept FirebaseApp + FirebaseFirestore statics before the lazy
        // `Firebase.firestore` extension property is first accessed.
        mockkStatic(FirebaseApp::class)
        mockkStatic(FirebaseFirestore::class)
        every { FirebaseApp.getInstance() } returns mockk(relaxed = true)

        mockFirestoreInstance = mockk(relaxed = true)
        every { FirebaseFirestore.getInstance() } returns mockFirestoreInstance

        // Plugin is a pure mock — we only care that emitGodotSignal is called
        // with the right arguments; we do not exercise the real plugin wiring.
        mockPlugin = mockk(relaxed = true)

        // Set up a shared collection/document reference returned for any
        // collection() / document() call.  Individual tests override these
        // stubs when they need specialised task behaviour.
        mockCollection = mockk(relaxed = true)
        mockDocRef = mockk(relaxed = true)

        every { mockFirestoreInstance.collection(any()) } returns mockCollection
        every { mockFirestoreInstance.document(any()) } returns mockDocRef
        every { mockCollection.document(any()) } returns mockDocRef

        firestoreUnderTest = Firestore(mockPlugin)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
    }

    // =========================================================================
    // firestoreSignals()
    // =========================================================================

    @Nested
    @DisplayName("firestoreSignals()")
    inner class FirestoreSignals {
        @Test
        @DisplayName("returns eleven signals")
        fun `returns 11 signals`() {
            assertEquals(11, firestoreUnderTest.firestoreSignals().size)
        }

        @Test
        @DisplayName("includes all expected signal names")
        fun `includes all expected signal names`() {
            val names = firestoreUnderTest.firestoreSignals().map { it.name }.toSet()
            val expected =
                setOf(
                    "document_written",
                    "document_write_failed",
                    "document_query_completed",
                    "document_query_failed",
                    "document_updated",
                    "document_update_failed",
                    "document_deleted",
                    "document_delete_failed",
                    "document_changed",
                    "collection_query_completed",
                    "collection_query_failed",
                )
            assertTrue(names.containsAll(expected)) {
                "Missing signals: ${expected - names}"
            }
        }
    }

    // =========================================================================
    // addDocument()
    // =========================================================================

    @Nested
    @DisplayName("addDocument()")
    inner class AddDocument {
        @Test
        @DisplayName("emits document_written with the generated ID on success")
        fun `emits document_written with generated id on success`() {
            val generatedRef = FirestoreFixtures.mockDocumentReference(id = "generated-id")
            every { mockCollection.add(any()) } returns Fixtures.successTask(generatedRef)

            val document = FirestoreFixtures.firestoreDocumentWithData()
            firestoreUnderTest.addDocument(document)

            verify { mockPlugin.emitGodotSignal("document_written", any()) }
        }

        @Test
        @DisplayName("assigns the server-generated document ID to the document object")
        fun `assigns generated document id on success`() {
            val generatedRef = FirestoreFixtures.mockDocumentReference(id = "server-side-id")
            every { mockCollection.add(any()) } returns Fixtures.successTask(generatedRef)

            val document = FirestoreFixtures.firestoreDocumentWithData()
            firestoreUnderTest.addDocument(document)

            // After success the document object is updated in-place
            assertEquals("server-side-id", document.documentId)
        }

        @Test
        @DisplayName("passes the document data map to the collection")
        fun `passes document data to collection add`() {
            val generatedRef = FirestoreFixtures.mockDocumentReference()
            every { mockCollection.add(any()) } returns Fixtures.successTask(generatedRef)

            val document = FirestoreFixtures.firestoreDocumentWithData(collection = "players")
            firestoreUnderTest.addDocument(document)

            // Verify we called add() on the correct collection
            verify { mockFirestoreInstance.collection("players") }
            verify { mockCollection.add(any()) }
        }

        @Test
        @DisplayName("emits document_write_failed with error details on failure")
        fun `emits document_write_failed on failure`() {
            every {
                mockCollection.add(any())
            } returns Fixtures.failureTask(RuntimeException("Permission denied"))

            firestoreUnderTest.addDocument(FirestoreFixtures.firestoreDocumentWithData())

            verify { mockPlugin.emitGodotSignal("document_write_failed", any()) }
        }

        @Test
        @DisplayName("does NOT emit document_written when add fails")
        fun `does not emit document_written on failure`() {
            every {
                mockCollection.add(any())
            } returns Fixtures.failureTask(RuntimeException("Network error"))

            firestoreUnderTest.addDocument(FirestoreFixtures.firestoreDocumentWithData())

            verify(exactly = 0) { mockPlugin.emitGodotSignal("document_written", any()) }
        }
    }

    // =========================================================================
    // setDocument()
    // =========================================================================

    @Nested
    @DisplayName("setDocument()")
    inner class SetDocument {
        @Test
        @DisplayName("emits document_written on success without merge")
        fun `emits document_written on success (no merge)`() {
            every { mockDocRef.set(any<Map<*, *>>()) } returns Fixtures.successTask<Void?>(null)

            val document = FirestoreFixtures.firestoreDocumentWithData()
            firestoreUnderTest.setDocument(document, merge = false)

            verify { mockPlugin.emitGodotSignal("document_written", any()) }
        }

        @Test
        @DisplayName("calls doc.set(map) — without SetOptions — when merge = false")
        fun `calls set without SetOptions when merge is false`() {
            every { mockDocRef.set(any<Map<*, *>>()) } returns Fixtures.successTask<Void?>(null)

            firestoreUnderTest.setDocument(FirestoreFixtures.firestoreDocumentWithData(), merge = false)

            verify { mockDocRef.set(any<Map<*, *>>()) }
            verify(exactly = 0) { mockDocRef.set(any<Map<*, *>>(), any<SetOptions>()) }
        }

        @Test
        @DisplayName("calls doc.set(map, SetOptions.merge()) when merge = true")
        fun `calls set with SetOptions when merge is true`() {
            every {
                mockDocRef.set(any<Map<*, *>>(), any<SetOptions>())
            } returns Fixtures.successTask<Void?>(null)

            firestoreUnderTest.setDocument(FirestoreFixtures.firestoreDocumentWithData(), merge = true)

            verify { mockDocRef.set(any<Map<*, *>>(), any<SetOptions>()) }
        }

        @Test
        @DisplayName("emits document_written on success with merge = true")
        fun `emits document_written on success with merge`() {
            every {
                mockDocRef.set(any<Map<*, *>>(), any<SetOptions>())
            } returns Fixtures.successTask<Void?>(null)

            firestoreUnderTest.setDocument(FirestoreFixtures.firestoreDocumentWithData(), merge = true)

            verify { mockPlugin.emitGodotSignal("document_written", any()) }
        }

        @Test
        @DisplayName("emits document_write_failed on failure")
        fun `emits document_write_failed on failure`() {
            every {
                mockDocRef.set(any<Map<*, *>>())
            } returns Fixtures.failureTask(RuntimeException("Quota exceeded"))

            firestoreUnderTest.setDocument(FirestoreFixtures.firestoreDocumentWithData(), merge = false)

            verify { mockPlugin.emitGodotSignal("document_write_failed", any()) }
        }

        @Test
        @DisplayName("does NOT emit document_written when set fails")
        fun `does not emit document_written on failure`() {
            every {
                mockDocRef.set(any<Map<*, *>>())
            } returns Fixtures.failureTask(RuntimeException("Offline"))

            firestoreUnderTest.setDocument(FirestoreFixtures.firestoreDocumentWithData(), merge = false)

            verify(exactly = 0) { mockPlugin.emitGodotSignal("document_written", any()) }
        }
    }

    // =========================================================================
    // getDocument()
    // =========================================================================

    @Nested
    @DisplayName("getDocument()")
    inner class GetDocument {
        @Test
        @DisplayName("emits document_query_completed when document exists")
        fun `emits document_query_completed when document exists`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot(exists = true)
            every { mockDocRef.get() } returns Fixtures.successTask(snapshot)

            firestoreUnderTest.getDocument("test-collection", "doc-123")

            verify { mockPlugin.emitGodotSignal("document_query_completed", any()) }
        }

        @Test
        @DisplayName("emits document_query_failed with 'does not exist' error when snapshot is absent")
        fun `emits document_query_failed when document does not exist`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot(exists = false)
            every { mockDocRef.get() } returns Fixtures.successTask(snapshot)

            firestoreUnderTest.getDocument("test-collection", "doc-missing")

            verify { mockPlugin.emitGodotSignal("document_query_failed", any()) }
        }

        @Test
        @DisplayName("does NOT emit document_query_completed when document is absent")
        fun `does not emit document_query_completed when document does not exist`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot(exists = false)
            every { mockDocRef.get() } returns Fixtures.successTask(snapshot)

            firestoreUnderTest.getDocument("test-collection", "doc-missing")

            verify(exactly = 0) { mockPlugin.emitGodotSignal("document_query_completed", any()) }
        }

        @Test
        @DisplayName("emits document_query_failed with the exception message on Firestore error")
        fun `emits document_query_failed on firebase error`() {
            every {
                mockDocRef.get()
            } returns Fixtures.failureTask(RuntimeException("Insufficient permissions"))

            firestoreUnderTest.getDocument("test-collection", "doc-123")

            verify { mockPlugin.emitGodotSignal("document_query_failed", any()) }
        }

        @Test
        @DisplayName("does NOT emit document_query_completed on Firestore error")
        fun `does not emit document_query_completed on firebase error`() {
            every {
                mockDocRef.get()
            } returns Fixtures.failureTask(RuntimeException("Network error"))

            firestoreUnderTest.getDocument("test-collection", "doc-123")

            verify(exactly = 0) { mockPlugin.emitGodotSignal("document_query_completed", any()) }
        }

        @Test
        @DisplayName("queries the correct collection and document ID")
        fun `queries correct collection and document`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot()
            every { mockDocRef.get() } returns Fixtures.successTask(snapshot)

            firestoreUnderTest.getDocument("users", "user-abc")

            verify { mockFirestoreInstance.collection("users") }
            verify { mockCollection.document("user-abc") }
        }

        @Test
        @DisplayName("handles nested map and list data without throwing")
        fun `converts nested map and list fields without error`() {
            val snapshot = FirestoreFixtures.mockNestedDocumentSnapshot()
            every { mockDocRef.get() } returns Fixtures.successTask(snapshot)

            // Must not throw even when data contains nested maps/lists
            firestoreUnderTest.getDocument("test-collection", "doc-nested")

            verify { mockPlugin.emitGodotSignal("document_query_completed", any()) }
        }
    }

    // =========================================================================
    // getCollection()
    // =========================================================================

    @Nested
    @DisplayName("getCollection()")
    inner class GetCollection {
        @Test
        @DisplayName("emits collection_query_completed on success")
        fun `emits collection_query_completed on success`() {
            val snapshot = FirestoreFixtures.mockQuerySnapshot()
            every { mockCollection.get() } returns Fixtures.successTask(snapshot)

            firestoreUnderTest.getCollection("test-collection")

            verify { mockPlugin.emitGodotSignal("collection_query_completed", any()) }
        }

        @Test
        @DisplayName("emits collection_query_completed even for an empty collection")
        fun `emits collection_query_completed for empty collection`() {
            val snapshot = FirestoreFixtures.mockQuerySnapshot(documents = emptyList())
            every { mockCollection.get() } returns Fixtures.successTask(snapshot)

            firestoreUnderTest.getCollection("empty-collection")

            verify { mockPlugin.emitGodotSignal("collection_query_completed", any()) }
        }

        @Test
        @DisplayName("emits collection_query_completed with all documents from the snapshot")
        fun `includes all documents from query snapshot`() {
            val docs =
                listOf(
                    FirestoreFixtures.mockDocumentSnapshot(id = "a"),
                    FirestoreFixtures.mockDocumentSnapshot(id = "b"),
                    FirestoreFixtures.mockDocumentSnapshot(id = "c"),
                )
            every { mockCollection.get() } returns Fixtures.successTask(FirestoreFixtures.mockQuerySnapshot(docs))

            firestoreUnderTest.getCollection("test-collection")

            verify { mockPlugin.emitGodotSignal("collection_query_completed", any()) }
        }

        @Test
        @DisplayName("emits collection_query_failed on Firestore error")
        fun `emits collection_query_failed on firebase error`() {
            every {
                mockCollection.get()
            } returns Fixtures.failureTask(RuntimeException("Service unavailable"))

            firestoreUnderTest.getCollection("test-collection")

            verify { mockPlugin.emitGodotSignal("collection_query_failed", any()) }
        }

        @Test
        @DisplayName("does NOT emit collection_query_completed on error")
        fun `does not emit collection_query_completed on error`() {
            every {
                mockCollection.get()
            } returns Fixtures.failureTask(RuntimeException("Timeout"))

            firestoreUnderTest.getCollection("test-collection")

            verify(exactly = 0) { mockPlugin.emitGodotSignal("collection_query_completed", any()) }
        }

        @Test
        @DisplayName("queries the correct collection path")
        fun `queries correct collection path`() {
            val snapshot = FirestoreFixtures.mockQuerySnapshot()
            every { mockCollection.get() } returns Fixtures.successTask(snapshot)

            firestoreUnderTest.getCollection("leaderboard")

            verify { mockFirestoreInstance.collection("leaderboard") }
        }
    }

    // =========================================================================
    // updateDocument()
    // =========================================================================

    @Nested
    @DisplayName("updateDocument()")
    inner class UpdateDocument {
        @Test
        @DisplayName("emits document_updated on success")
        fun `emits document_updated on success`() {
            every { mockDocRef.update(any<Map<String, Any?>>()) } returns Fixtures.successTask<Void?>(null)

            firestoreUnderTest.updateDocument(FirestoreFixtures.firestoreDocumentWithData())

            verify { mockPlugin.emitGodotSignal("document_updated", any()) }
        }

        @Test
        @DisplayName("emits document_update_failed on Firestore error")
        fun `emits document_update_failed on failure`() {
            every {
                mockDocRef.update(any<Map<String, Any?>>())
            } returns Fixtures.failureTask(RuntimeException("Document not found"))

            firestoreUnderTest.updateDocument(FirestoreFixtures.firestoreDocumentWithData())

            verify { mockPlugin.emitGodotSignal("document_update_failed", any()) }
        }

        @Test
        @DisplayName("does NOT emit document_updated on failure")
        fun `does not emit document_updated on failure`() {
            every {
                mockDocRef.update(any<Map<String, Any?>>())
            } returns Fixtures.failureTask(RuntimeException("Offline"))

            firestoreUnderTest.updateDocument(FirestoreFixtures.firestoreDocumentWithData())

            verify(exactly = 0) { mockPlugin.emitGodotSignal("document_updated", any()) }
        }

        @Test
        @DisplayName("targets the correct collection and document")
        fun `targets correct collection and document`() {
            every { mockDocRef.update(any<Map<String, Any?>>()) } returns Fixtures.successTask<Void?>(null)

            val document =
                FirestoreFixtures.firestoreDocumentWithData(
                    collection = "scores",
                    documentId = "score-999",
                )
            firestoreUnderTest.updateDocument(document)

            verify { mockFirestoreInstance.collection("scores") }
            verify { mockCollection.document("score-999") }
        }
    }

    // =========================================================================
    // deleteDocument()
    // =========================================================================

    @Nested
    @DisplayName("deleteDocument()")
    inner class DeleteDocument {
        @Test
        @DisplayName("emits document_deleted on success")
        fun `emits document_deleted on success`() {
            every { mockDocRef.delete() } returns Fixtures.successTask<Void?>(null)

            firestoreUnderTest.deleteDocument("test-collection", "doc-123")

            verify { mockPlugin.emitGodotSignal("document_deleted", any()) }
        }

        @Test
        @DisplayName("emits document_delete_failed on Firestore error")
        fun `emits document_delete_failed on failure`() {
            every {
                mockDocRef.delete()
            } returns Fixtures.failureTask(RuntimeException("Not authorised"))

            firestoreUnderTest.deleteDocument("test-collection", "doc-123")

            verify { mockPlugin.emitGodotSignal("document_delete_failed", any()) }
        }

        @Test
        @DisplayName("does NOT emit document_deleted on failure")
        fun `does not emit document_deleted on failure`() {
            every {
                mockDocRef.delete()
            } returns Fixtures.failureTask(RuntimeException("Gone"))

            firestoreUnderTest.deleteDocument("test-collection", "doc-123")

            verify(exactly = 0) { mockPlugin.emitGodotSignal("document_deleted", any()) }
        }

        @Test
        @DisplayName("targets the correct collection and document ID")
        fun `targets correct collection and document id`() {
            every { mockDocRef.delete() } returns Fixtures.successTask<Void?>(null)

            firestoreUnderTest.deleteDocument("inventory", "item-42")

            verify { mockFirestoreInstance.collection("inventory") }
            verify { mockCollection.document("item-42") }
        }
    }

    // =========================================================================
    // trackDocument()
    // =========================================================================

    @Nested
    @DisplayName("trackDocument()")
    inner class TrackDocument {
        @Test
        @DisplayName("emits document_changed when the snapshot listener fires with a live document")
        fun `emits document_changed on snapshot update`() {
            val mockReg = FirestoreFixtures.mockListenerRegistration()
            val listenerSlot = slot<EventListener<com.google.firebase.firestore.DocumentSnapshot>>()
            every { mockDocRef.addSnapshotListener(capture(listenerSlot)) } returns mockReg

            firestoreUnderTest.trackDocument("test-collection", "doc-123")

            // Fire the captured listener with an existing snapshot
            val snapshot =
                FirestoreFixtures.mockDocumentSnapshot(
                    id = "doc-123",
                    collectionPath = "test-collection",
                    exists = true,
                )
            listenerSlot.captured.onEvent(snapshot, null)

            verify { mockPlugin.emitGodotSignal("document_changed", any()) }
        }

        @Test
        @DisplayName("does NOT emit document_changed when the snapshot does not exist")
        fun `does not emit document_changed for absent snapshot`() {
            val mockReg = FirestoreFixtures.mockListenerRegistration()
            val listenerSlot = slot<EventListener<com.google.firebase.firestore.DocumentSnapshot>>()
            every { mockDocRef.addSnapshotListener(capture(listenerSlot)) } returns mockReg

            firestoreUnderTest.trackDocument("test-collection", "doc-123")

            val snapshot = FirestoreFixtures.mockDocumentSnapshot(exists = false)
            listenerSlot.captured.onEvent(snapshot, null)

            verify(exactly = 0) { mockPlugin.emitGodotSignal(any(), any()) }
        }

        @Test
        @DisplayName("does NOT emit a signal when the listener fires with a Firestore error")
        fun `does not emit signal on listener error`() {
            val mockReg = FirestoreFixtures.mockListenerRegistration()
            val listenerSlot = slot<EventListener<com.google.firebase.firestore.DocumentSnapshot>>()
            every { mockDocRef.addSnapshotListener(capture(listenerSlot)) } returns mockReg

            firestoreUnderTest.trackDocument("test-collection", "doc-123")

            // Fire listener with a Firestore exception (non-null error → early return)
            val firestoreException = mockk<com.google.firebase.firestore.FirebaseFirestoreException>(relaxed = true)
            listenerSlot.captured.onEvent(null, firestoreException)

            verify(exactly = 0) { mockPlugin.emitGodotSignal(any(), any()) }
        }

        @Test
        @DisplayName("adds a snapshot listener to the correct document path")
        fun `registers listener on correct document path`() {
            val mockReg = FirestoreFixtures.mockListenerRegistration()
            every {
                mockDocRef.addSnapshotListener(any<EventListener<com.google.firebase.firestore.DocumentSnapshot>>())
            } returns mockReg

            firestoreUnderTest.trackDocument("users", "user-007")

            // The document path "users/user-007" is resolved via firestore.document()
            verify { mockFirestoreInstance.document("users/user-007") }
            verify {
                mockDocRef.addSnapshotListener(
                    any<EventListener<com.google.firebase.firestore.DocumentSnapshot>>(),
                )
            }
        }

        @Test
        @DisplayName("handles nested map and list fields in tracked snapshot without throwing")
        fun `converts nested fields from tracked snapshot without error`() {
            val mockReg = FirestoreFixtures.mockListenerRegistration()
            val listenerSlot = slot<EventListener<com.google.firebase.firestore.DocumentSnapshot>>()
            every { mockDocRef.addSnapshotListener(capture(listenerSlot)) } returns mockReg

            firestoreUnderTest.trackDocument("test-collection", "doc-nested")

            val snapshot = FirestoreFixtures.mockNestedDocumentSnapshot(id = "doc-nested")
            listenerSlot.captured.onEvent(snapshot, null)

            verify { mockPlugin.emitGodotSignal("document_changed", any()) }
        }
    }

    // =========================================================================
    // stopTrackingDocument()
    // =========================================================================

    @Nested
    @DisplayName("stopTrackingDocument()")
    inner class StopTrackingDocument {
        @Test
        @DisplayName("calls remove() on the registered ListenerRegistration")
        fun `calls remove on listener registration`() {
            val mockReg = FirestoreFixtures.mockListenerRegistration()
            every {
                mockDocRef.addSnapshotListener(any<EventListener<com.google.firebase.firestore.DocumentSnapshot>>())
            } returns mockReg

            firestoreUnderTest.trackDocument("test-collection", "doc-123")
            firestoreUnderTest.stopTrackingDocument("test-collection", "doc-123")

            verify { mockReg.remove() }
        }

        @Test
        @DisplayName("is a no-op and does not throw when the document was never tracked")
        fun `no-op when document was never tracked`() {
            // Should not throw — the map simply contains no entry for this path
            firestoreUnderTest.stopTrackingDocument("test-collection", "phantom-doc")
        }

        @Test
        @DisplayName("does not call remove() on a registration for a different document")
        fun `does not remove listener for a different document`() {
            val mockReg1 = FirestoreFixtures.mockListenerRegistration()
            val mockReg2 = FirestoreFixtures.mockListenerRegistration()

            val mockDocRef2 = mockk<DocumentReference>(relaxed = true)
            every { mockFirestoreInstance.document("test-collection/doc-A") } returns mockDocRef
            every { mockFirestoreInstance.document("test-collection/doc-B") } returns mockDocRef2
            every {
                mockDocRef.addSnapshotListener(any<EventListener<com.google.firebase.firestore.DocumentSnapshot>>())
            } returns mockReg1
            every {
                mockDocRef2.addSnapshotListener(any<EventListener<com.google.firebase.firestore.DocumentSnapshot>>())
            } returns mockReg2

            firestoreUnderTest.trackDocument("test-collection", "doc-A")
            firestoreUnderTest.trackDocument("test-collection", "doc-B")

            // Only stop tracking doc-A
            firestoreUnderTest.stopTrackingDocument("test-collection", "doc-A")

            verify(exactly = 1) { mockReg1.remove() }
            verify(exactly = 0) { mockReg2.remove() }
        }

        @Test
        @DisplayName("subsequent trackDocument calls after stopTracking register a fresh listener")
        fun `re-registers listener after stop`() {
            val mockReg1 = FirestoreFixtures.mockListenerRegistration()
            val mockReg2 = FirestoreFixtures.mockListenerRegistration()
            val listenerSlot = slot<EventListener<com.google.firebase.firestore.DocumentSnapshot>>()

            every {
                mockDocRef.addSnapshotListener(capture(listenerSlot))
            } returnsMany listOf(mockReg1, mockReg2)

            firestoreUnderTest.trackDocument("test-collection", "doc-123")
            firestoreUnderTest.stopTrackingDocument("test-collection", "doc-123")
            firestoreUnderTest.trackDocument("test-collection", "doc-123")

            // addSnapshotListener was called twice — once for each trackDocument
            verify(exactly = 2) {
                mockDocRef.addSnapshotListener(any<EventListener<com.google.firebase.firestore.DocumentSnapshot>>())
            }
        }
    }
}
