//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase

import android.app.Activity
import android.content.Intent
import android.util.Log
import android.view.View
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

import org.godotengine.plugin.firebase.model.FirestoreDocument


class FirebasePlugin(
    godot: Godot,
) : GodotPlugin(godot) {
    companion object {
        private const val TAG = "FirebasePlugin"
    }

    override fun getPluginName(): String = TAG

    private val auth = Authentication(this)
    private val firestore = Firestore(this)

    override fun onMainCreate(activity: Activity?): View? {
        val act = activity ?: getActivity()
        act?.let { auth.init(it) }
        return super.onMainCreate(activity)
    }

    override fun onMainActivityResult(
        requestCode: Int,
        resultCode: Int,
        intent: Intent?,
    ) {
        auth.handleActivityResult(requestCode, resultCode, intent)
    }

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        val signals: MutableSet<SignalInfo> = mutableSetOf()
        signals.addAll(auth.authSignals())
        signals.addAll(firestore.firestoreSignals())
        Log.d(TAG, "Registering ${signals.size} signals")
        return signals
    }

    fun emitGodotSignal(signalName: String, vararg args: Any?) {
        getGodot().runOnRenderThread {
            emitSignal(signalName, *args)
        }
    }


    /**
     * Authentication
     */

    @UsedByGodot
    fun create_user(email: String, password: String) = auth.createUser(email, password)

    @UsedByGodot
    fun link_anonymous_with_google() = auth.linkAnonymousWithGoogle()

    @UsedByGodot
    fun sign_in(
        email: String,
        password: String,
    ) = auth.signIn(email, password)

    @UsedByGodot
    fun sign_in_with_google() = auth.signInWithGoogle()

    @UsedByGodot
    fun sign_in_anonymously() = auth.signInAnonymously()

    @UsedByGodot
    fun is_signed_in() = auth.isSignedIn()

    @UsedByGodot
    fun sign_out() = auth.signOut()

    @UsedByGodot
    fun send_verification_email() = auth.sendVerificationEmail()

    @UsedByGodot
    fun send_password_reset_email(email: String) = auth.sendPasswordResetEmail(email)

    @UsedByGodot
    fun get_current_user() = auth.getCurrentUser()

    @UsedByGodot
    fun delete_current_user() = auth.deleteCurrentUser()


	/**
	 * Firestore
	 */

	@UsedByGodot
	fun add_document(document: Dictionary) = firestore.addDocument(FirestoreDocument(document))

	@UsedByGodot
	fun set_document(document: Dictionary, merge: Boolean = false) =
            firestore.setDocument(FirestoreDocument(document), merge)

	@UsedByGodot
	fun get_document(collection: String, documentId: String) = firestore.getDocument(collection, documentId)

	@UsedByGodot
	fun update_document(document: Dictionary) = firestore.updateDocument(FirestoreDocument(document))

	@UsedByGodot
	fun delete_document(collection: String, documentId: String) = firestore.deleteDocument(collection, documentId)

	@UsedByGodot
	fun get_collection(collection: String) = firestore.getCollection(collection)

	@UsedByGodot
	fun track_document(collection: String, documentId: String) = firestore.trackDocument(collection, documentId)

	@UsedByGodot
	fun stop_tracking_document(collection: String, documentId: String) =
            firestore.stopTrackingDocument(collection, documentId)
}
