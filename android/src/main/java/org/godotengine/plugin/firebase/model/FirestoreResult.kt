//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.QuerySnapshot

import org.godotengine.godot.Dictionary

class FirestoreResult(
    private val rawData: Dictionary = Dictionary(),
) {
    companion object {
        const val COLLECTION_PROPERTY = "collection"
        const val DOCUMENTS_PROPERTY = "documents"
    }

    constructor(
		collection: String,
		documents: Dictionary? = null,)
     : this() {
        this.rawData[COLLECTION_PROPERTY] = collection
        if (documents != null) this.rawData[DOCUMENTS_PROPERTY] = documents
    }

    constructor(collection: String, querySnapshot: QuerySnapshot)
     : this() {
        val resultData = Dictionary()
        for (doc in querySnapshot.documents) {
            resultData[doc.id] = FirestoreDocument(doc).getRawData()
        }
        this.rawData[COLLECTION_PROPERTY] = collection
        this.rawData[DOCUMENTS_PROPERTY] = resultData
    }

    // Collection name
    var collection: String
        get() = rawData[COLLECTION_PROPERTY] as? String ?: ""
        set(value) {
            rawData[COLLECTION_PROPERTY] = value
        }

    // Document data
    var documents: Dictionary
        get() = rawData[DOCUMENTS_PROPERTY] as? Dictionary ?: Dictionary()
        set(value) {
            rawData[DOCUMENTS_PROPERTY] = value
        }

    fun getRawData(): Dictionary = rawData
}
