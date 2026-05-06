//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase

import android.util.Log
import com.google.firebase.Firebase
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.firestore
import org.godotengine.godot.Dictionary
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.plugin.firebase.model.FirestoreDocument
import org.godotengine.plugin.firebase.model.FirestoreError
import org.godotengine.plugin.firebase.model.FirestoreResult

class Firestore(
    private val plugin: FirebasePlugin,
) {
    companion object {
        private const val TAG = "GodotFirestore"

        private const val SIGNAL_DOCUMENT_WRITTEN = "document_written"
        private const val SIGNAL_DOCUMENT_WRITE_FAILED = "document_write_failed"
        private const val SIGNAL_DOCUMENT_UPDATED = "document_updated"
        private const val SIGNAL_DOCUMENT_UPDATE_FAILED = "document_update_failed"
        private const val SIGNAL_DOCUMENT_DELETED = "document_deleted"
        private const val SIGNAL_DOCUMENT_DELETE_FAILED = "document_delete_failed"
        private const val SIGNAL_DOCUMENT_CHANGED = "document_changed"
        private const val SIGNAL_DOCUMENT_QUERY_COMPLETED = "document_query_completed"
        private const val SIGNAL_DOCUMENT_QUERY_FAILED = "document_query_failed"
        private const val SIGNAL_COLLECTION_QUERY_COMPLETED = "collection_query_completed"
        private const val SIGNAL_COLLECTION_QUERY_FAILED = "collection_query_failed"
    }

    private val firestore by lazy { Firebase.firestore }
    private val documentListeners: MutableMap<String, ListenerRegistration> = mutableMapOf()

    fun firestoreSignals(): MutableSet<SignalInfo> {
        val signals: MutableSet<SignalInfo> = mutableSetOf()
        signals.add(SignalInfo(SIGNAL_DOCUMENT_WRITTEN, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_WRITE_FAILED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_QUERY_COMPLETED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_QUERY_FAILED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_UPDATED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_UPDATE_FAILED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_DELETED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_DELETE_FAILED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_DOCUMENT_CHANGED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_COLLECTION_QUERY_COMPLETED, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_COLLECTION_QUERY_FAILED, Dictionary::class.java))
        return signals
    }

    fun addDocument(document: FirestoreDocument) {
        val collection = document.collection ?: ""
        val map = document.documentData.toMap()
        Log.d(TAG, "Adding document to collection: $collection with data: $map")

        firestore
            .collection(collection)
            .add(map)
            .addOnSuccessListener { doc ->
                document.documentId = doc.id
                Log.d(TAG, "Document added with ID: ${document.documentId}")
                plugin.emitGodotSignal(SIGNAL_DOCUMENT_WRITTEN, document.getRawData())
            }.addOnFailureListener { e ->
                Log.e(TAG, "Error adding document:", e)
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_WRITE_FAILED,
                    FirestoreError(collection, null, e.message ?: "Unknown error").getRawData(),
                )
            }
    }

    fun setDocument(
        document: FirestoreDocument,
        merge: Boolean = false,
    ) {
        Log.d(TAG, "Setting document in collection: ${document.collection}")
        val collection = document.collection ?: ""
        val documentId = document.documentId ?: ""
        val map = document.documentData.toMap()
        val doc = firestore.collection(collection).document(documentId)
        val task = if (merge) doc.set(map, SetOptions.merge()) else doc.set(map)

        task
            .addOnSuccessListener {
                Log.d(TAG, "Document $documentId set successfully (merge=$merge)")
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_WRITTEN,
                    FirestoreDocument(collection, documentId).getRawData(),
                )
            }.addOnFailureListener { e ->
                Log.e(TAG, "Error setting document:", e)
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_WRITE_FAILED,
                    FirestoreError(collection, documentId, e.message ?: "Unknown error").getRawData(),
                )
            }
    }

    fun getCollection(collection: String) {
        Log.d(TAG, "Getting documents from collection: $collection")
        firestore
            .collection(collection)
            .get()
            .addOnSuccessListener { querySnapshot ->
                Log.d(TAG, "Documents retrieved successfully from $collection")
                plugin.emitGodotSignal(
                    SIGNAL_COLLECTION_QUERY_COMPLETED,
                    FirestoreResult(collection, querySnapshot).getRawData(),
                )
            }.addOnFailureListener { e ->
                Log.e(TAG, "Error getting documents from collection:", e)
                plugin.emitGodotSignal(
                    SIGNAL_COLLECTION_QUERY_FAILED,
                    FirestoreError(collection, null, e.message ?: "Unknown error").getRawData(),
                )
            }
    }

    fun getDocument(
        collection: String,
        documentId: String,
    ) {
        Log.d(TAG, "Getting document from collection: $collection")
        firestore
            .collection(collection)
            .document(documentId)
            .get()
            .addOnSuccessListener { documentSnapshot ->
                if (documentSnapshot.exists()) {
                    Log.d(TAG, "Document $documentId retrieved successfully")
                    plugin.emitGodotSignal(
                        SIGNAL_DOCUMENT_QUERY_COMPLETED,
                        FirestoreDocument(documentSnapshot).getRawData(),
                    )
                } else {
                    Log.e(TAG, "Document $documentId does not exist")
                    plugin.emitGodotSignal(
                        SIGNAL_DOCUMENT_QUERY_FAILED,
                        FirestoreError(collection, documentId, "Document does not exist").getRawData(),
                    )
                }
            }.addOnFailureListener { e ->
                Log.e(TAG, "Error getting document:", e)
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_QUERY_FAILED,
                    FirestoreError(collection, documentId, e.message ?: "Unknown error").getRawData(),
                )
            }
    }

    fun updateDocument(document: FirestoreDocument) {
        Log.d(TAG, "Updating document in collection: ${document.collection}")
        val collection = document.collection ?: ""
        val documentId = document.documentId ?: ""
        val map = document.documentData.toMap()

        firestore
            .collection(collection)
            .document(documentId)
            .update(map)
            .addOnSuccessListener {
                Log.d(TAG, "Document $documentId updated successfully")
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_UPDATED,
                    FirestoreDocument(collection, documentId).getRawData(),
                )
            }.addOnFailureListener { e ->
                Log.e(TAG, "Error updating document:", e)
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_UPDATE_FAILED,
                    FirestoreError(collection, documentId, e.message ?: "Unknown error").getRawData(),
                )
            }
    }

    fun deleteDocument(
        collection: String,
        documentId: String,
    ) {
        Log.d(TAG, "Deleting document from collection: $collection")
        firestore
            .collection(collection)
            .document(documentId)
            .delete()
            .addOnSuccessListener {
                Log.d(TAG, "Document $documentId deleted successfully")
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_DELETED,
                    FirestoreDocument(collection, documentId).getRawData(),
                )
            }.addOnFailureListener { e ->
                Log.e(TAG, "Error deleting document:", e)
                plugin.emitGodotSignal(
                    SIGNAL_DOCUMENT_DELETE_FAILED,
                    FirestoreError(collection, documentId, e.message ?: "Unknown error").getRawData(),
                )
            }
    }

    fun trackDocument(
        collection: String,
        documentId: String,
    ) {
        Log.d(TAG, "Tracking document in collection: $collection")
        val documentPath = "$collection/$documentId"
        val document = firestore.document(documentPath)
        val listener =
            document.addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e(TAG, "Could not add listener for document $documentPath", error)
                    return@addSnapshotListener
                }
                if (snapshot != null && snapshot.exists()) {
                    val dict = snapshotToDictionary(snapshot)
                    Log.d(TAG, "Document '$documentPath' changed")
                    plugin.emitGodotSignal(
                        SIGNAL_DOCUMENT_CHANGED,
                        FirestoreDocument(collection, documentId, dict).getRawData(),
                    )
                }
            }
        documentListeners[documentPath] = listener
    }

    fun stopTrackingDocument(
        collection: String,
        documentId: String,
    ) {
        Log.d(TAG, "Stopping tracking of document in collection: $collection")
        val documentPath = "$collection/$documentId"
        documentListeners[documentPath]?.remove()
        documentListeners.remove(documentPath)
        Log.d(TAG, "Stopped tracking $documentPath")
    }

    private fun snapshotToDictionary(snapshot: DocumentSnapshot): Dictionary {
        val dict = Dictionary()
        if (snapshot.exists()) {
            val dataMap = snapshot.data
            if (dataMap != null) {
                val converted = convertValueToGodotType(dataMap)
                if (converted is Dictionary) {
                    return converted
                }
            }
        }
        return dict
    }

    private fun convertValueToGodotType(value: Any?): Any? =
        when (value) {
            is Map<*, *> -> {
                val newDict = Dictionary()
                value.forEach { (k, v) ->
                    if (k != null) {
                        newDict[k.toString()] = convertValueToGodotType(v)
                    }
                }
                newDict
            }

            is List<*> -> {
                value.map { convertValueToGodotType(it) }.toTypedArray()
            }

            else -> {
                value
            }
        }
}
