//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import com.google.firebase.firestore.DocumentSnapshot
import io.mockk.every
import io.mockk.mockk
import org.godotengine.godot.Dictionary
import org.godotengine.plugin.firebase.fixtures.FirestoreFixtures
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

@DisplayName("FirestoreDocument")
class FirestoreDocumentTest {

    // -------------------------------------------------------------------------
    // Default (no-arg) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("default constructor")
    inner class DefaultConstructor {
        @Test
        @DisplayName("collection defaults to empty string")
        fun `collection defaults to empty string`() {
            assertEquals("", FirestoreDocument().collection)
        }

        @Test
        @DisplayName("documentId defaults to empty string")
        fun `documentId defaults to empty string`() {
            assertEquals("", FirestoreDocument().documentId)
        }

        @Test
        @DisplayName("documentData defaults to empty Dictionary")
        fun `documentData defaults to empty Dictionary`() {
            assertTrue(FirestoreDocument().documentData.isEmpty())
        }
    }

    // -------------------------------------------------------------------------
    // (collection, documentId, documentData) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("constructor(collection, documentId, documentData)")
    inner class CollectionDocumentDataConstructor {
        @Test
        @DisplayName("stores collection name")
        fun `stores collection`() {
            val doc = FirestoreDocument("users", "u-1")
            assertEquals("users", doc.collection)
        }

        @Test
        @DisplayName("stores document ID")
        fun `stores documentId`() {
            val doc = FirestoreDocument("users", "u-1")
            assertEquals("u-1", doc.documentId)
        }

        @Test
        @DisplayName("stores non-empty documentData")
        fun `stores non-empty documentData`() {
            val data = Dictionary()
            data["key"] = "value"
            val doc = FirestoreDocument("users", "u-1", data)
            assertEquals("value", doc.documentData["key"])
        }

        @Test
        @DisplayName("omits documentData entry when data is null")
        fun `omits documentData when null`() {
            val doc = FirestoreDocument("users", "u-1", null)
            // The key should not be present; the property getter returns an empty Dictionary
            assertTrue(doc.documentData.isEmpty())
        }

        @Test
        @DisplayName("omits documentData entry when data is an empty Dictionary")
        fun `omits documentData when empty dictionary`() {
            val doc = FirestoreDocument("users", "u-1", Dictionary())
            assertTrue(doc.documentData.isEmpty())
        }
    }

    // -------------------------------------------------------------------------
    // DocumentSnapshot constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("constructor(DocumentSnapshot)")
    inner class DocumentSnapshotConstructor {
        @Test
        @DisplayName("maps snapshot collection path to collection")
        fun `maps snapshot collection path`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot(
                collectionPath = "orders",
                id = "order-1",
            )
            val doc = FirestoreDocument(snapshot)
            assertEquals("orders", doc.collection)
        }

        @Test
        @DisplayName("maps snapshot document ID to documentId")
        fun `maps snapshot id to documentId`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot(id = "order-1")
            assertEquals("order-1", FirestoreDocument(snapshot).documentId)
        }

        @Test
        @DisplayName("populates documentData from snapshot data map")
        fun `populates documentData from snapshot`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot(
                data = mapOf("name" to "Alice", "score" to 99),
            )
            val doc = FirestoreDocument(snapshot)
            assertEquals("Alice", doc.documentData["name"])
            assertEquals(99, doc.documentData["score"])
        }

        @Test
        @DisplayName("produces an empty documentData Dictionary when snapshot data is null")
        fun `empty documentData when snapshot data is null`() {
            val snapshot = FirestoreFixtures.mockDocumentSnapshot(
                exists = false,
            )
            // snapshot.data returns null when document does not exist
            val doc = FirestoreDocument(snapshot)
            // The constructor iterates over null-safe, so dict stays empty
            assertTrue(doc.documentData.isEmpty())
        }
    }

    // -------------------------------------------------------------------------
    // Property setters
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("property setters")
    inner class PropertySetters {
        @Test
        @DisplayName("collection setter updates value")
        fun `collection setter`() {
            val doc = FirestoreDocument()
            doc.collection = "events"
            assertEquals("events", doc.collection)
        }

        @Test
        @DisplayName("documentId setter updates value")
        fun `documentId setter`() {
            val doc = FirestoreDocument()
            doc.documentId = "evt-42"
            assertEquals("evt-42", doc.documentId)
        }

        @Test
        @DisplayName("documentData setter updates value")
        fun `documentData setter`() {
            val doc = FirestoreDocument()
            val newData = Dictionary()
            newData["field"] = "updated"
            doc.documentData = newData
            assertEquals("updated", doc.documentData["field"])
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
            assertNotNull(FirestoreDocument().getRawData())
        }

        @Test
        @DisplayName("contains COLLECTION_PROPERTY key after construction")
        fun `contains collection key`() {
            val doc = FirestoreDocument("items", "item-1")
            assertEquals("items", doc.getRawData()[FirestoreDocument.COLLECTION_PROPERTY])
        }

        @Test
        @DisplayName("contains DOCUMENT_ID_PROPERTY key after construction")
        fun `contains documentId key`() {
            val doc = FirestoreDocument("items", "item-1")
            assertEquals("item-1", doc.getRawData()[FirestoreDocument.DOCUMENT_ID_PROPERTY])
        }

        @Test
        @DisplayName("getRawData returns the same Dictionary instance on successive calls")
        fun `getRawData returns same instance`() {
            val doc = FirestoreFixtures.firestoreDocument()
            assertSame(doc.getRawData(), doc.getRawData())
        }

        @Test
        @DisplayName("mutations via setters are visible in getRawData()")
        fun `setter mutations visible in raw data`() {
            val doc = FirestoreDocument()
            doc.collection = "mutated-collection"
            doc.documentId = "mutated-id"
            val raw = doc.getRawData()
            assertEquals("mutated-collection", raw[FirestoreDocument.COLLECTION_PROPERTY])
            assertEquals("mutated-id", raw[FirestoreDocument.DOCUMENT_ID_PROPERTY])
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
            assertEquals("collection", FirestoreDocument.COLLECTION_PROPERTY)
        }

        @Test
        @DisplayName("DOCUMENT_ID_PROPERTY has expected key string")
        fun `DOCUMENT_ID_PROPERTY value`() {
            assertEquals("document_id", FirestoreDocument.DOCUMENT_ID_PROPERTY)
        }

        @Test
        @DisplayName("DOCUMENT_DATA_PROPERTY has expected key string")
        fun `DOCUMENT_DATA_PROPERTY value`() {
            assertEquals("document_data", FirestoreDocument.DOCUMENT_DATA_PROPERTY)
        }
    }
}
