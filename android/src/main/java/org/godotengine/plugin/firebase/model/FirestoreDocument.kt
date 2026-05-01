//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import com.google.firebase.firestore.DocumentSnapshot

import org.godotengine.godot.Dictionary

class FirestoreDocument(
    private val rawData: Dictionary = Dictionary(),
) {
    companion object {
        const val COLLECTION_PROPERTY = "collection"
        const val DOCUMENT_ID_PROPERTY = "document_id"
        const val DOCUMENT_DATA_PROPERTY = "document_data"
    }

    constructor(
        collection: String,
		documentId: String,
		documentData: Dictionary? = Dictionary(),)
     : this() {
        this.rawData[COLLECTION_PROPERTY] = collection
        this.rawData[DOCUMENT_ID_PROPERTY] = documentId
        if (documentData != null && !documentData.isEmpty()) {
            this.rawData[DOCUMENT_DATA_PROPERTY] = documentData
        }
    }

    constructor(documentSnapshot: DocumentSnapshot)
     : this() {
        this.rawData[COLLECTION_PROPERTY] = documentSnapshot.reference.parent.path
        this.rawData[DOCUMENT_ID_PROPERTY] = documentSnapshot.id
        val dict = Dictionary()
        documentSnapshot.data?.forEach { (key, value) -> dict[key] = value }
        this.rawData[DOCUMENT_DATA_PROPERTY] = dict
    }

    // Collection name
    var collection: String
        get() = rawData[COLLECTION_PROPERTY] as? String ?: ""
        set(value) {
            rawData[COLLECTION_PROPERTY] = value
        }

    // Document identifier
    var documentId: String
        get() = rawData[DOCUMENT_ID_PROPERTY] as? String ?: ""
        set(value) {
            rawData[DOCUMENT_ID_PROPERTY] = value
        }

    // Document data
    var documentData: Dictionary
        get() = rawData[DOCUMENT_DATA_PROPERTY] as? Dictionary ?: Dictionary()
        set(value) {
            rawData[DOCUMENT_DATA_PROPERTY] = value
        }

    fun getRawData(): Dictionary = rawData
}
