//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import org.godotengine.godot.Dictionary
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

@DisplayName("FirestoreError")
class FirestoreErrorTest {
    // -------------------------------------------------------------------------
    // Default (no-arg) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("default constructor")
    inner class DefaultConstructor {
        @Test
        @DisplayName("collection defaults to empty string")
        fun `collection defaults to empty string`() {
            assertEquals("", FirestoreError().collection)
        }

        @Test
        @DisplayName("documentId defaults to empty string")
        fun `documentId defaults to empty string`() {
            assertEquals("", FirestoreError().documentId)
        }

        @Test
        @DisplayName("error defaults to empty string")
        fun `error defaults to empty string`() {
            assertEquals("", FirestoreError().error)
        }
    }

    // -------------------------------------------------------------------------
    // (collection, documentId, error) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("constructor(collection, documentId, error)")
    inner class PrimaryConstructor {
        @Test
        @DisplayName("stores collection name when non-null")
        fun `stores collection`() {
            val err = FirestoreError("users", "u-1", "Not found")
            assertEquals("users", err.collection)
        }

        @Test
        @DisplayName("stores documentId when non-null")
        fun `stores documentId`() {
            val err = FirestoreError("users", "u-1", "Not found")
            assertEquals("u-1", err.documentId)
        }

        @Test
        @DisplayName("stores error message")
        fun `stores error message`() {
            val err = FirestoreError("users", "u-1", "Not found")
            assertEquals("Not found", err.error)
        }

        @Test
        @DisplayName("omits COLLECTION_PROPERTY key when collection is null")
        fun `omits collection key when null`() {
            val err = FirestoreError(null, "u-1", "Missing collection")
            val raw = err.getRawData()
            // Key should be absent; getter returns "" via safe cast
            assertFalse(raw.containsKey(FirestoreError.COLLECTION_PROPERTY))
        }

        @Test
        @DisplayName("omits DOCUMENT_ID_PROPERTY key when documentId is null")
        fun `omits documentId key when null`() {
            val err = FirestoreError("users", null, "Collection-level error")
            val raw = err.getRawData()
            assertFalse(raw.containsKey(FirestoreError.DOCUMENT_ID_PROPERTY))
        }

        @Test
        @DisplayName("collection getter returns empty string when key is absent")
        fun `collection getter is empty string when key absent`() {
            val err = FirestoreError(null, null, "Error")
            assertEquals("", err.collection)
        }

        @Test
        @DisplayName("documentId getter returns empty string when key is absent")
        fun `documentId getter is empty string when key absent`() {
            val err = FirestoreError(null, null, "Error")
            assertEquals("", err.documentId)
        }

        @Test
        @DisplayName("stores all three fields when all are non-null")
        fun `stores all fields when all non-null`() {
            val err = FirestoreError("orders", "o-99", "Permission denied")
            assertEquals("orders", err.collection)
            assertEquals("o-99", err.documentId)
            assertEquals("Permission denied", err.error)
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
            val err = FirestoreError()
            err.collection = "events"
            assertEquals("events", err.collection)
        }

        @Test
        @DisplayName("documentId setter updates the value")
        fun `documentId setter`() {
            val err = FirestoreError()
            err.documentId = "evt-7"
            assertEquals("evt-7", err.documentId)
        }

        @Test
        @DisplayName("error setter updates the value")
        fun `error setter`() {
            val err = FirestoreError()
            err.error = "Updated error message"
            assertEquals("Updated error message", err.error)
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
            assertNotNull(FirestoreError("col", "doc", "Error").getRawData())
        }

        @Test
        @DisplayName("contains COLLECTION_PROPERTY when collection is set")
        fun `contains collection key`() {
            val raw = FirestoreError("items", "item-1", "Error").getRawData()
            assertEquals("items", raw[FirestoreError.COLLECTION_PROPERTY])
        }

        @Test
        @DisplayName("contains DOCUMENT_ID_PROPERTY when documentId is set")
        fun `contains documentId key`() {
            val raw = FirestoreError("items", "item-1", "Error").getRawData()
            assertEquals("item-1", raw[FirestoreError.DOCUMENT_ID_PROPERTY])
        }

        @Test
        @DisplayName("contains ERROR_PROPERTY")
        fun `contains error key`() {
            val raw = FirestoreError("items", "item-1", "Something went wrong").getRawData()
            assertEquals("Something went wrong", raw[FirestoreError.ERROR_PROPERTY])
        }

        @Test
        @DisplayName("getRawData returns the same Dictionary instance on successive calls")
        fun `getRawData returns same instance`() {
            val err = FirestoreError("col", "doc", "Error")
            assertSame(err.getRawData(), err.getRawData())
        }

        @Test
        @DisplayName("mutations via setters are visible in getRawData()")
        fun `setter mutations visible in raw data`() {
            val err = FirestoreError()
            err.collection = "mutated-col"
            err.error = "mutated error"
            val raw = err.getRawData()
            assertEquals("mutated-col", raw[FirestoreError.COLLECTION_PROPERTY])
            assertEquals("mutated error", raw[FirestoreError.ERROR_PROPERTY])
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
            assertEquals("collection", FirestoreError.COLLECTION_PROPERTY)
        }

        @Test
        @DisplayName("DOCUMENT_ID_PROPERTY has expected key string")
        fun `DOCUMENT_ID_PROPERTY value`() {
            assertEquals("document_id", FirestoreError.DOCUMENT_ID_PROPERTY)
        }

        @Test
        @DisplayName("ERROR_PROPERTY has expected key string")
        fun `ERROR_PROPERTY value`() {
            assertEquals("error", FirestoreError.ERROR_PROPERTY)
        }
    }
}
