//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import org.godotengine.godot.Dictionary
import org.godotengine.plugin.firebase.fixtures.FirestoreFixtures
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

@DisplayName("FirestoreResult")
class FirestoreResultTest {
    // -------------------------------------------------------------------------
    // Default (no-arg) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("default constructor")
    inner class DefaultConstructor {
        @Test
        @DisplayName("collection defaults to empty string")
        fun `collection defaults to empty string`() {
            assertEquals("", FirestoreResult().collection)
        }

        @Test
        @DisplayName("documents defaults to empty Dictionary")
        fun `documents defaults to empty Dictionary`() {
            assertTrue(FirestoreResult().documents.isEmpty())
        }
    }

    // -------------------------------------------------------------------------
    // (collection, documents?) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("constructor(collection, documents?)")
    inner class CollectionDocumentsConstructor {
        @Test
        @DisplayName("stores the collection name")
        fun `stores collection`() {
            val result = FirestoreResult("players")
            assertEquals("players", result.collection)
        }

        @Test
        @DisplayName("stores a non-null documents Dictionary")
        fun `stores non-null documents`() {
            val docs = Dictionary()
            docs["doc-1"] = "data"
            val result = FirestoreResult("players", docs)
            assertEquals("data", result.documents["doc-1"])
        }

        @Test
        @DisplayName("omits DOCUMENTS_PROPERTY key when documents is null")
        fun `omits documents key when null`() {
            val result = FirestoreResult("players", null)
            // The key must be absent; the property getter returns an empty Dictionary
            val raw = result.getRawData()
            assertTrue(!raw.containsKey(FirestoreResult.DOCUMENTS_PROPERTY) || result.documents.isEmpty())
        }
    }

    // -------------------------------------------------------------------------
    // (collection, QuerySnapshot) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("constructor(collection, QuerySnapshot)")
    inner class QuerySnapshotConstructor {
        @Test
        @DisplayName("stores the collection name")
        fun `stores collection from query snapshot`() {
            val qs = FirestoreFixtures.mockQuerySnapshot()
            val result = FirestoreResult("scores", qs)
            assertEquals("scores", result.collection)
        }

        @Test
        @DisplayName("produces an empty documents Dictionary for an empty QuerySnapshot")
        fun `empty documents for empty snapshot`() {
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = emptyList())
            val result = FirestoreResult("scores", qs)
            assertTrue(result.documents.isEmpty())
        }

        @Test
        @DisplayName("indexes each document by its ID")
        fun `indexes documents by id`() {
            val docs =
                listOf(
                    FirestoreFixtures.mockDocumentSnapshot(id = "a", data = mapOf("x" to 1)),
                    FirestoreFixtures.mockDocumentSnapshot(id = "b", data = mapOf("x" to 2)),
                )
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = docs)
            val result = FirestoreResult("scores", qs)

            assertTrue(result.documents.containsKey("a"))
            assertTrue(result.documents.containsKey("b"))
        }

        @Test
        @DisplayName("stores documents count matching the snapshot")
        fun `documents count matches snapshot`() {
            val docs =
                listOf(
                    FirestoreFixtures.mockDocumentSnapshot(id = "a"),
                    FirestoreFixtures.mockDocumentSnapshot(id = "b"),
                    FirestoreFixtures.mockDocumentSnapshot(id = "c"),
                )
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = docs)
            val result = FirestoreResult("scores", qs)

            assertEquals(3, result.documents.size)
        }

        @Test
        @DisplayName("each indexed value is a Dictionary (FirestoreDocument raw data)")
        fun `each document value is a Dictionary`() {
            val docs =
                listOf(
                    FirestoreFixtures.mockDocumentSnapshot(id = "doc-1", data = mapOf("name" to "Alice")),
                )
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = docs)
            val result = FirestoreResult("players", qs)

            val entry = result.documents["doc-1"]
            assertTrue(entry is Dictionary)
        }

        @Test
        @DisplayName("document collection path is stored inside each indexed entry")
        fun `document entry contains collection path`() {
            val docs =
                listOf(
                    FirestoreFixtures.mockDocumentSnapshot(
                        id = "doc-1",
                        collectionPath = "players",
                        data = mapOf("name" to "Bob"),
                    ),
                )
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = docs)
            val result = FirestoreResult("players", qs)

            val entry = result.documents["doc-1"] as Dictionary
            assertEquals("players", entry[FirestoreDocument.COLLECTION_PROPERTY])
        }

        @Test
        @DisplayName("document data is stored inside each indexed entry")
        fun `document entry contains document data`() {
            val docs =
                listOf(
                    FirestoreFixtures.mockDocumentSnapshot(
                        id = "doc-1",
                        data = mapOf("score" to 99),
                    ),
                )
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = docs)
            val result = FirestoreResult("leaderboard", qs)

            val entry = result.documents["doc-1"] as Dictionary
            val documentData = entry[FirestoreDocument.DOCUMENT_DATA_PROPERTY] as Dictionary
            assertEquals(99, documentData["score"])
        }

        @Test
        @DisplayName("each document entry has the correct document_id key")
        fun `document entry contains correct document_id`() {
            val docs =
                listOf(
                    FirestoreFixtures.mockDocumentSnapshot(id = "user-42"),
                )
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = docs)
            val result = FirestoreResult("users", qs)

            val entry = result.documents["user-42"] as Dictionary
            assertEquals("user-42", entry[FirestoreDocument.DOCUMENT_ID_PROPERTY])
        }
    }

    // -------------------------------------------------------------------------
    // Property setters
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("property setters")
    inner class PropertySetters {
        @Test
        @DisplayName("collection setter updates the value")
        fun `collection setter`() {
            val result = FirestoreResult()
            result.collection = "new-collection"
            assertEquals("new-collection", result.collection)
        }

        @Test
        @DisplayName("documents setter updates the value")
        fun `documents setter`() {
            val result = FirestoreResult()
            val newDocs = Dictionary()
            newDocs["doc-x"] = "payload"
            result.documents = newDocs
            assertEquals("payload", result.documents["doc-x"])
        }
    }

    // -------------------------------------------------------------------------
    // getRawData()
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("getRawData()")
    inner class GetRawData {
        @Test
        @DisplayName("returns a non-null Dictionary")
        fun `returns non-null dictionary`() {
            assertNotNull(FirestoreResult("col").getRawData())
        }

        @Test
        @DisplayName("contains COLLECTION_PROPERTY after construction")
        fun `contains collection key`() {
            val result = FirestoreResult("my-col")
            assertEquals("my-col", result.getRawData()[FirestoreResult.COLLECTION_PROPERTY])
        }

        @Test
        @DisplayName("contains DOCUMENTS_PROPERTY when documents were supplied")
        fun `contains documents key when documents supplied`() {
            val docs = Dictionary()
            docs["doc-1"] = "data"
            val result = FirestoreResult("col", docs)
            assertNotNull(result.getRawData()[FirestoreResult.DOCUMENTS_PROPERTY])
        }

        @Test
        @DisplayName("getRawData returns the same Dictionary instance on successive calls")
        fun `getRawData returns same instance`() {
            val result = FirestoreResult("col")
            assertSame(result.getRawData(), result.getRawData())
        }

        @Test
        @DisplayName("mutations via setters are visible in getRawData()")
        fun `setter mutations visible in raw data`() {
            val result = FirestoreResult()
            result.collection = "mutated-col"
            assertEquals("mutated-col", result.getRawData()[FirestoreResult.COLLECTION_PROPERTY])
        }

        @Test
        @DisplayName("DOCUMENTS_PROPERTY reflects documents populated from QuerySnapshot")
        fun `documents from QuerySnapshot visible in raw data`() {
            val docs = listOf(FirestoreFixtures.mockDocumentSnapshot(id = "snap-doc"))
            val qs = FirestoreFixtures.mockQuerySnapshot(documents = docs)
            val result = FirestoreResult("col", qs)

            val raw = result.getRawData()
            val documents = raw[FirestoreResult.DOCUMENTS_PROPERTY] as Dictionary
            assertTrue(documents.containsKey("snap-doc"))
        }
    }

    // -------------------------------------------------------------------------
    // Companion object constants
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("companion object constants")
    inner class CompanionConstants {
        @Test
        @DisplayName("COLLECTION_PROPERTY has expected key string")
        fun `COLLECTION_PROPERTY value`() {
            assertEquals("collection", FirestoreResult.COLLECTION_PROPERTY)
        }

        @Test
        @DisplayName("DOCUMENTS_PROPERTY has expected key string")
        fun `DOCUMENTS_PROPERTY value`() {
            assertEquals("documents", FirestoreResult.DOCUMENTS_PROPERTY)
        }
    }
}
