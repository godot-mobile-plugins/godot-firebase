//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.Firebase
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.auth
import org.godotengine.godot.Dictionary
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.plugin.firebase.model.GodotFirebaseUser

class Authentication(
    private val plugin: FirebasePlugin,
) {
    companion object {
        private const val GOOGLE_SIGN_IN = 9001
        private const val TAG = "GodotFirebaseAuth"

        private const val SIGNAL_AUTH_SUCCESS = "auth_success"
        private const val SIGNAL_AUTH_FAILURE = "auth_failure"
        private const val SIGNAL_LINK_SUCCESS = "link_with_google_success"
        private const val SIGNAL_LINK_FAILURE = "link_with_google_failure"
        private const val SIGNAL_SIGN_OUT_SUCCESS = "sign_out_success"
        private const val SIGNAL_PASSWORD_RESET_SENT = "password_reset_sent"
        private const val SIGNAL_EMAIL_VERIFICATION_SENT = "email_verification_sent"
        private const val SIGNAL_USER_DELETED = "user_deleted"
    }

    private lateinit var activity: android.app.Activity
    private val auth: FirebaseAuth = Firebase.auth
    private lateinit var googleSignInClient: GoogleSignInClient
    private var isLinkingAnonymous = false

    fun authSignals(): MutableSet<SignalInfo> {
        val signals: MutableSet<SignalInfo> = mutableSetOf()
        signals.add(SignalInfo(SIGNAL_AUTH_SUCCESS, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_AUTH_FAILURE, String::class.java))
        signals.add(SignalInfo(SIGNAL_LINK_SUCCESS, Dictionary::class.java))
        signals.add(SignalInfo(SIGNAL_LINK_FAILURE, String::class.java))
        signals.add(SignalInfo(SIGNAL_SIGN_OUT_SUCCESS, Boolean::class.javaObjectType))
        signals.add(SignalInfo(SIGNAL_PASSWORD_RESET_SENT, Boolean::class.javaObjectType))
        signals.add(SignalInfo(SIGNAL_EMAIL_VERIFICATION_SENT, Boolean::class.javaObjectType))
        signals.add(SignalInfo(SIGNAL_USER_DELETED, Boolean::class.javaObjectType))
        return signals
    }

    fun init(activity: Activity) {
        this.activity = activity
        val resId = activity.resources.getIdentifier("default_web_client_id", "string", activity.packageName)

        if (resId == 0) {
            Log.e(TAG, "default_web_client_id not found in app resources.")
            return
        }

        val webClientId = activity.getString(resId)

        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(webClientId)
            .requestEmail()
            .build()

        googleSignInClient = GoogleSignIn.getClient(activity, gso)
    }

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        intent: Intent?,
    ) {
        if (requestCode == GOOGLE_SIGN_IN) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(intent)
            try {
                val account = task.getResult(ApiException::class.java)!!
                Log.d(TAG, "authWithGoogle:" + account.id)
                if (isLinkingAnonymous) {
                    isLinkingAnonymous = false
                    linkWithGoogle(account.idToken!!)
                } else {
                    authWithGoogle(account.idToken!!)
                }
            } catch (e: ApiException) {
                val wasLinking = isLinkingAnonymous
                isLinkingAnonymous = false
                Log.w(TAG, "Google sign in failed", e)
                if (wasLinking) {
                    plugin.emitGodotSignal(SIGNAL_LINK_FAILURE, e.message ?: "Unknown error")
                } else {
                    plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, e.message ?: "Unknown error")
                }
            }
        }
    }

    fun createUser(
        email: String,
        password: String,
    ) {
        Log.d(TAG, "Creating user with email: $email")
        auth
            .createUserWithEmailAndPassword(email, password)
            .addOnSuccessListener {
                val godotUser = getCurrentFirebaseUser()
                if (godotUser == null) {
                    Log.e(TAG, "User creation succeeded but user is null.")
                    plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "User creation succeeded but user is null.")
                    return@addOnSuccessListener
                }
                Log.d(TAG, "User created with email: $email")
                plugin.emitGodotSignal(SIGNAL_AUTH_SUCCESS, godotUser.getRawData())
            }.addOnFailureListener { e ->
                Log.d(TAG, "User creation failed", e)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, e.message ?: "Unknown error")
            }
    }

    fun linkAnonymousWithGoogle() {
        Log.d(TAG, "Linking anonymous user with Google.")
        val currentUser = auth.currentUser
        if (currentUser == null) {
            Log.e(TAG, "No user signed in.")
            plugin.emitGodotSignal(SIGNAL_LINK_FAILURE, "No user signed in.")
            return
        }
        if (!currentUser.isAnonymous) {
            Log.d(TAG, "Current user is not anonymous (uid=${currentUser.uid}). Cannot link.")
            plugin.emitGodotSignal(SIGNAL_LINK_FAILURE, "Current user is not anonymous.")
            return
        }
        Log.d(TAG, "Linking anonymous user (uid=${currentUser.uid}) with Google.")
        isLinkingAnonymous = true
        signInWithGoogle()
    }

    fun signIn(
        email: String,
        password: String,
    ) {
        Log.d(TAG, "Signing in with email: $email")
        auth
            .signInWithEmailAndPassword(email, password)
            .addOnSuccessListener {
                val godotUser = getCurrentFirebaseUser()
                if (godotUser == null) {
                    Log.e(TAG, "Authentication succeeded but user is null.")
                    plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "Authentication succeeded but user is null.")
                    return@addOnSuccessListener
                }
                Log.d(TAG, "Signed in with email: $email")
                plugin.emitGodotSignal(SIGNAL_AUTH_SUCCESS, godotUser.getRawData())
            }.addOnFailureListener { e ->
                Log.d(TAG, "Sign-in with email failed", e)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, e.message ?: "Unknown error")
            }
    }

    fun signInWithGoogle() {
        Log.d(TAG, "Signing in with Google.")
        try {
            val signInIntent = googleSignInClient.signInIntent  // lazy init fires here
            activity.startActivityForResult(signInIntent, GOOGLE_SIGN_IN)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "Google Sign-In config error: ${e.message}")
            plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, e.message ?: "Google Sign-In not configured.")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting Google Sign-In", e)
            plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "Error starting Google Sign-In: ${e.message}")
        }
    }

    fun signInAnonymously() {
        Log.d(TAG, "Signing in anonymously.")
        val currentUser = auth.currentUser
        if (currentUser != null) {
            Log.d(
                TAG,
                "User already signed in (uid=${currentUser.uid}, " +
                    "isAnonymous=${currentUser.isAnonymous}). Skipping anonymous sign-in.",
            )
            plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "User is already signed in.")
            return
        }
        auth
            .signInAnonymously()
            .addOnSuccessListener {
                val godotUser = getCurrentFirebaseUser()
                if (godotUser == null) {
                    Log.e(TAG, "Anonymous sign-in succeeded but user is null.")
                    plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "Anonymous sign-in succeeded but user is null.")
                    return@addOnSuccessListener
                }
                val uid = it.user?.uid
                Log.d(TAG, "Signed in anonymously as $uid")
                plugin.emitGodotSignal(SIGNAL_AUTH_SUCCESS, godotUser.getRawData())
            }.addOnFailureListener { e ->
                Log.d(TAG, "Anonymous sign-in failed", e)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, e.message ?: "Unknown error")
            }
    }

    fun isSignedIn(): Boolean = auth.currentUser != null

    fun signOut() {
        Log.d(TAG, "Signing out.")
        auth.signOut()
        googleSignInClient
            .signOut()
            .addOnCompleteListener(activity) {
                plugin.emitGodotSignal(SIGNAL_SIGN_OUT_SUCCESS, true)
            }.addOnFailureListener { e ->
                Log.d(TAG, "Sign out failed", e)
                plugin.emitGodotSignal(SIGNAL_SIGN_OUT_SUCCESS, false)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "Failed to sign out: ${e.message}")
            }
    }

    fun sendVerificationEmail() {
        Log.d(TAG, "Sending verification email to user.")
        auth.currentUser
            ?.sendEmailVerification()
            ?.addOnSuccessListener {
                Log.d(TAG, "Verification email sent.")
                plugin.emitGodotSignal(SIGNAL_EMAIL_VERIFICATION_SENT, true)
            }?.addOnFailureListener { e ->
                Log.e(TAG, "Failed to send verification email", e)
                plugin.emitGodotSignal(SIGNAL_EMAIL_VERIFICATION_SENT, false)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "Failed to send verification email: ${e.message}")
            }
    }

    fun sendPasswordResetEmail(email: String) {
        Log.d(TAG, "Sending password reset email to: $email.")
        auth
            .sendPasswordResetEmail(email)
            .addOnSuccessListener {
                Log.d(TAG, "Password reset email sent to $email.")
                plugin.emitGodotSignal(SIGNAL_PASSWORD_RESET_SENT, true)
            }.addOnFailureListener { e ->
                Log.e(TAG, "Password reset failed", e)
                plugin.emitGodotSignal(SIGNAL_PASSWORD_RESET_SENT, false)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "Failed to send password reset email: ${e.message}")
            }
    }

    fun getCurrentUser(): Dictionary {
        Log.d(TAG, "Getting current user.")
        val user = getCurrentFirebaseUser()
        return user?.getRawData() ?: Dictionary()
    }

    fun deleteCurrentUser() {
        Log.d(TAG, "Deleting current user.")
        auth.currentUser
            ?.delete()
            ?.addOnSuccessListener {
                Log.d(TAG, "User deleted.")
                plugin.emitGodotSignal(SIGNAL_USER_DELETED, true)
            }?.addOnFailureListener { e ->
                Log.e(TAG, "Failed to delete user", e)
                plugin.emitGodotSignal(SIGNAL_USER_DELETED, false)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, "Delete failed: ${e.message}")
            }
    }

    private fun getCurrentFirebaseUser(): GodotFirebaseUser? {
        val user = auth.currentUser ?: return null
        return GodotFirebaseUser(user)
    }

    private fun authWithGoogle(idToken: String) {
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        auth
            .signInWithCredential(credential)
            .addOnSuccessListener { authResult ->
                val godotUser = getCurrentFirebaseUser()
                if (godotUser == null) {
                    Log.e(TAG, "Authentication with Google succeeded but user is null.")
                    plugin.emitGodotSignal(
                        SIGNAL_AUTH_FAILURE,
                        "Authentication with Google succeeded but user is null.",
                    )
                    return@addOnSuccessListener
                }
                val uid = authResult.user?.uid
                Log.d(TAG, "signInWithCredential:success -> $uid")
                plugin.emitGodotSignal(SIGNAL_AUTH_SUCCESS, godotUser.getRawData())
            }.addOnFailureListener { e ->
                Log.w(TAG, "signInWithCredential:failure", e)
                plugin.emitGodotSignal(SIGNAL_AUTH_FAILURE, e.message ?: "Unknown error")
            }
    }

    private fun linkWithGoogle(idToken: String) {
        val currentUser = auth.currentUser
        if (currentUser == null) {
            Log.e(TAG, "No user signed in during linkWithGoogle.")
            plugin.emitGodotSignal(SIGNAL_LINK_FAILURE, "No user signed in.")
            return
        }
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        currentUser
            .linkWithCredential(credential)
            .addOnSuccessListener { authResult ->
                val godotUser = getCurrentFirebaseUser()
                if (godotUser == null) {
                    Log.e(TAG, "linkWithCredential succeeded but user is null.")
                    plugin.emitGodotSignal(SIGNAL_LINK_FAILURE, "Link succeeded but user is null.")
                    return@addOnSuccessListener
                }
                val uid = authResult.user?.uid
                Log.d(TAG, "linkWithCredential:success -> $uid")
                plugin.emitGodotSignal(SIGNAL_LINK_SUCCESS, godotUser.getRawData())
            }.addOnFailureListener { e ->
                Log.w(TAG, "linkWithCredential:failure", e)
                plugin.emitGodotSignal(SIGNAL_LINK_FAILURE, e.message ?: "Unknown error")
            }
    }
}
