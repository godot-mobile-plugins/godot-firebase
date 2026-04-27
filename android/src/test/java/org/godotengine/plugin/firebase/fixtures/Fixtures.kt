//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.fixtures

import android.app.Activity
import android.net.Uri
import com.google.android.gms.tasks.OnCompleteListener
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
import com.google.android.gms.tasks.Task
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseUser
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import org.godotengine.plugin.firebase.model.GodotFirebaseUser

/**
 * Central factory for test fixtures used across the Firebase plugin test suite.
 *
 * Provides:
 *  - Pre-configured [FirebaseUser] mocks (verified, anonymous, minimal)
 *  - Pre-configured [GodotFirebaseUser] instances built from those mocks
 *  - [AuthResult] mocks wrapping a given user
 *  - Synchronous [Task] helpers that invoke listeners immediately, so tests
 *    do not need to spin event loops or use real async infrastructure
 *
 * All Task helpers are `inline reified` so MockK can materialise a correctly
 * typed `Task<T>` without unchecked casts, and so that MockK's answer DSL can
 * resolve the concrete listener type at the call site.
 */
object Fixtures {
    // -------------------------------------------------------------------------
    // FirebaseUser
    // -------------------------------------------------------------------------

    /**
     * Returns a mocked [FirebaseUser] with fully-populated, sensible defaults.
     * Every field can be overridden for targeted tests.
     */
    fun mockFirebaseUser(
        uid: String = "uid-default-123",
        displayName: String? = "Jane Doe",
        email: String? = "jane@example.com",
        photoUrl: Uri? = null,
        isEmailVerified: Boolean = true,
        isAnonymous: Boolean = false,
    ): FirebaseUser =
        mockk<FirebaseUser>().also { user ->
            every { user.uid } returns uid
            every { user.displayName } returns displayName
            every { user.email } returns email
            every { user.photoUrl } returns photoUrl
            every { user.isEmailVerified } returns isEmailVerified
            every { user.isAnonymous } returns isAnonymous
        }

    /**
     * Returns a mocked anonymous [FirebaseUser] (no email, no display name).
     */
    fun mockAnonymousFirebaseUser(uid: String = "uid-anon-456"): FirebaseUser =
        mockFirebaseUser(
            uid = uid,
            displayName = null,
            email = null,
            isEmailVerified = false,
            isAnonymous = true,
        )

    /**
     * Returns a mocked [FirebaseUser] whose email has NOT yet been verified.
     */
    fun mockUnverifiedFirebaseUser(
        uid: String = "uid-unverified-789",
        email: String = "unverified@example.com",
    ): FirebaseUser = mockFirebaseUser(uid = uid, email = email, isEmailVerified = false)

    /**
     * Returns a mocked [FirebaseUser] with a photo URL set.
     */
    fun mockFirebaseUserWithPhoto(
        uid: String = "uid-photo-000",
        photoUri: Uri = mockk<Uri>().also { every { it.toString() } returns "https://example.com/photo.jpg" },
    ): FirebaseUser = mockFirebaseUser(uid = uid, photoUrl = photoUri)

    // -------------------------------------------------------------------------
    // GodotFirebaseUser
    // -------------------------------------------------------------------------

    /**
     * Convenience wrapper that builds a [GodotFirebaseUser] directly from a
     * [FirebaseUser] mock. All parameters mirror those of [mockFirebaseUser].
     */
    fun godotFirebaseUser(
        uid: String = "uid-default-123",
        displayName: String? = "Jane Doe",
        email: String? = "jane@example.com",
        photoUrl: Uri? = null,
        isEmailVerified: Boolean = true,
        isAnonymous: Boolean = false,
    ): GodotFirebaseUser =
        GodotFirebaseUser(
            mockFirebaseUser(uid, displayName, email, photoUrl, isEmailVerified, isAnonymous),
        )

    fun godotAnonymousUser(): GodotFirebaseUser = GodotFirebaseUser(mockAnonymousFirebaseUser())

    // -------------------------------------------------------------------------
    // AuthResult
    // -------------------------------------------------------------------------

    /**
     * Returns a mocked [AuthResult] whose [AuthResult.getUser] returns [user].
     * Pass `null` to simulate the (unusual) case where auth succeeded but the
     * user object is missing.
     */
    fun mockAuthResult(user: FirebaseUser? = null): AuthResult =
        mockk<AuthResult>().also { every { it.user } returns user }

    // -------------------------------------------------------------------------
    // Task helpers
    // -------------------------------------------------------------------------

    /**
     * Returns a [Task] that synchronously invokes [OnSuccessListener.onSuccess]
     * with [result] as soon as [Task.addOnSuccessListener] is called.
     * [Task.addOnFailureListener] and the two-arg [Task.addOnCompleteListener]
     * are both no-ops.
     *
     * Use this to simulate a Firebase operation that succeeds.
     */
    inline fun <reified T> successTask(result: T): Task<T> {
        // relaxed=true silently handles addOnFailureListener and addOnCompleteListener
        // so we only need to stub the one path that must actually fire.
        val task = mockk<Task<T>>(relaxed = true)

        every { task.addOnSuccessListener(any()) } answers {
            firstArg<OnSuccessListener<T>>().onSuccess(result)
            task
        }

        // IMPORTANT: Return 'task' so subsequent chained listeners don't attach to a dummy mock
        every { task.addOnFailureListener(any()) } returns task

        return task
    }

    /**
     * Returns a [Task] that synchronously invokes [OnFailureListener.onFailure]
     * with [exception] as soon as [Task.addOnFailureListener] is called.
     * [Task.addOnSuccessListener] and the two-arg [Task.addOnCompleteListener]
     * are both no-ops.
     *
     * Use this to simulate a Firebase operation that fails.
     */
    inline fun <reified T> failureTask(exception: Exception): Task<T> {
        val task = mockk<Task<T>>(relaxed = true)

        every { task.addOnFailureListener(any()) } answers {
            firstArg<OnFailureListener>().onFailure(exception)
            task
        }

        // IMPORTANT: Return 'task' so subsequent chained listeners don't attach to a dummy mock
        every { task.addOnSuccessListener(any()) } returns task

        return task
    }

    /**
     * Returns a [Task] that synchronously invokes success or completion listeners.
     * Crucially, it returns 'task' for all listeners to support method chaining.
     */
    inline fun <reified T> completeSuccessTask(result: T? = null): Task<T> {
        val task = mockk<Task<T>>(relaxed = true)
        every { task.isSuccessful } returns true
        if (result != null) {
            every { task.result } returns result
        }

        // 1. Success Listeners (Trigger these)
        every { task.addOnSuccessListener(any<OnSuccessListener<T>>()) } answers {
            (firstArg() as OnSuccessListener<T>).onSuccess(result as T)
            task
        }
        every { task.addOnSuccessListener(any<Activity>(), any<OnSuccessListener<T>>()) } answers {
            (secondArg() as OnSuccessListener<T>).onSuccess(result as T)
            task
        }

        // 2. Failure Listeners (No-op, but MUST return task to continue chain)
        every { task.addOnFailureListener(any()) } returns task
        every { task.addOnFailureListener(any<Activity>(), any()) } returns task

        // 3. Complete Listeners (Trigger these)
        every { task.addOnCompleteListener(any<OnCompleteListener<T>>()) } answers {
            (firstArg() as OnCompleteListener<T>).onComplete(task)
            task
        }
        every { task.addOnCompleteListener(any<Activity>(), any<OnCompleteListener<T>>()) } answers {
            (secondArg() as OnCompleteListener<T>).onComplete(task)
            task
        }

        return task
    }

    /**
     * Returns a [Task] that synchronously invokes failure or completion listeners.
     * All calls return 'task' to ensure subsequent listeners in a chain are registered.
     */
    inline fun <reified T> completeFailureTask(exception: Exception): Task<T> {
        val task = mockk<Task<T>>(relaxed = true)
        every { task.isSuccessful } returns false
        every { task.exception } returns exception

        // 1. Failure Listeners (Trigger these)
        every { task.addOnFailureListener(any<OnFailureListener>()) } answers {
            (firstArg() as OnFailureListener).onFailure(exception)
            task
        }
        every { task.addOnFailureListener(any<Activity>(), any<OnFailureListener>()) } answers {
            (secondArg() as OnFailureListener).onFailure(exception)
            task
        }

        // 2. Success Listeners (No-op, but MUST return task to continue chain)
        every { task.addOnSuccessListener(any()) } returns task
        every { task.addOnSuccessListener(any<Activity>(), any()) } returns task

        // 3. Complete Listeners (Trigger these)
        every { task.addOnCompleteListener(any<OnCompleteListener<T>>()) } answers {
            (firstArg() as OnCompleteListener<T>).onComplete(task)
            task
        }
        every { task.addOnCompleteListener(any<Activity>(), any<OnCompleteListener<T>>()) } answers {
            (secondArg() as OnCompleteListener<T>).onComplete(task)
            task
        }

        return task
    }
}
