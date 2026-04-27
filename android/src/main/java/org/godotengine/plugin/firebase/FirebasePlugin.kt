//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase

import android.app.Activity
import android.content.Intent
import android.view.View
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class FirebasePlugin(
    godot: Godot,
) : GodotPlugin(godot) {
    override fun getPluginName(): String = FirebasePlugin::class.simpleName ?: ""

    private val auth = Authentication(this)

    override fun onMainCreate(activity: Activity?): View? {
        activity?.let { auth.init(it) }
                return super.onMainCreate(activity)
    }

    override fun onMainActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        auth.handleActivityResult(requestCode, resultCode, data)
    }

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        val signals: MutableSet<SignalInfo> = mutableSetOf()
        signals.addAll(auth.authSignals())
                return signals
    }

    fun emitGodotSignal(
        signalName: String,
        arg1: Any?,
        arg2: Any? = null,
    ) {
        if (arg2 != null) {
            emitSignal(signalName, arg1, arg2)
        } else {
            emitSignal(signalName, arg1)
        }
    }

    /**
     * Authentication
     */

    @UsedByGodot
            fun create_user(
        email: String,
        password: String,
    ) = auth.createUser(email, password)

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
}
