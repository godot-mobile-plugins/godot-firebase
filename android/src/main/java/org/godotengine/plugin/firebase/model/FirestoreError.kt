//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import org.godotengine.godot.Dictionary

class FirestoreError(
    private val rawData: Dictionary = Dictionary(),
) {
    companion object {
        const val COLLECTION_PROPERTY = "collection"
        const val DOCUMENT_ID_PROPERTY = "document_id"
        const val ERROR_PROPERTY = "error"
    }

    constructor(
		collection: String? = null,
		documentId: String? = null,
		error: String,
    )
     : this() {
        if (collection != null) this.rawData[COLLECTION_PROPERTY] = collection
        if (documentId != null) this.rawData[DOCUMENT_ID_PROPERTY] = documentId
        this.rawData[ERROR_PROPERTY] = error
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

    // Error message, if any
    var error: String
        get() = rawData[ERROR_PROPERTY] as? String ?: ""
        set(value) {
            rawData[ERROR_PROPERTY] = value
        }

    fun getRawData(): Dictionary = rawData
}
