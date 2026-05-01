//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import com.google.firebase.auth.FirebaseUser
import org.godotengine.godot.Dictionary

class GodotFirebaseUser(
    private val rawData: Dictionary = Dictionary(),
) {
    companion object {
        const val USER_ID_PROPERTY = "user_id"
        const val NAME_PROPERTY = "name"
        const val EMAIL_PROPERTY = "email"
        const val PHOTO_URL_PROPERTY = "photo_url"
        const val IS_EMAIL_VERIFIED_PROPERTY = "is_email_verified"
        const val IS_ANONYMOUS_PROPERTY = "is_anonymous"
    }

    constructor(user: FirebaseUser) : this() {
        this.rawData[USER_ID_PROPERTY] = user.uid
        this.rawData[NAME_PROPERTY] = user.displayName
        this.rawData[EMAIL_PROPERTY] = user.email
        this.rawData[PHOTO_URL_PROPERTY] = user.photoUrl?.toString()
        this.rawData[IS_EMAIL_VERIFIED_PROPERTY] = user.isEmailVerified
        this.rawData[IS_ANONYMOUS_PROPERTY] = user.isAnonymous
    }

    // User ID
    var userId: String
        get() = rawData[USER_ID_PROPERTY] as? String ?: ""
        set(value) {
            rawData[USER_ID_PROPERTY] = value
        }

    // Name
    var name: String
        get() = rawData[NAME_PROPERTY] as? String ?: ""
        set(value) {
            rawData[NAME_PROPERTY] = value
        }

    // Email
    var email: String
        get() = rawData[EMAIL_PROPERTY] as? String ?: ""
        set(value) {
            rawData[EMAIL_PROPERTY] = value
        }

    // Photo URL
    var photoUrl: String
        get() = rawData[PHOTO_URL_PROPERTY] as? String ?: ""
        set(value) {
            rawData[PHOTO_URL_PROPERTY] = value
        }

    // Is Email Verified
    var isEmailVerified: Boolean
        get() = rawData[IS_EMAIL_VERIFIED_PROPERTY] as? Boolean ?: false
        set(value) {
            rawData[IS_EMAIL_VERIFIED_PROPERTY] = value
        }

    // Is Anonymous
    var isAnonymous: Boolean
        get() = rawData[IS_ANONYMOUS_PROPERTY] as? Boolean ?: false
        set(value) {
            rawData[IS_ANONYMOUS_PROPERTY] = value
        }

    /**
     * Returns the underlying Dictionary containing the user data.
     */
    fun getRawData(): Dictionary = rawData
}
