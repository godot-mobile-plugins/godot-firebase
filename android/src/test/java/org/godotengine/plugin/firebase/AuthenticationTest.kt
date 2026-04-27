//
// © 2026-present Firebase Team https://github.com/firebase-team
//

package org.godotengine.plugin.firebase

import android.app.Activity
import android.content.Intent
import android.content.res.Resources
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.Status
import com.google.android.gms.tasks.Task
import com.google.firebase.FirebaseApp
import com.google.firebase.Firebase
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import io.mockk.Runs
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.spyk
import io.mockk.unmockkAll
import io.mockk.verify
import org.godotengine.godot.Godot
import org.godotengine.plugin.firebase.fixtures.Fixtures
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit-tests for [Authentication].
 *
 * Firebase and Google Play Services statics ([FirebaseAuth.getInstance],
 * [GoogleSignIn.getClient], etc.) are intercepted with MockK's [mockkStatic]
 * so no real Android runtime is required.  Every [Task] returned by the stubbed
 * auth calls invokes its listener synchronously via the helpers in [Fixtures],
 * keeping tests entirely single-threaded.
 *
 * [mockkStatic] registrations are torn down in [tearDown] via [unmockkAll] so
 * each test starts from a clean slate.
 */
@DisplayName("Authentication")
class AuthenticationTest {

    // -------------------------------------------------------------------------
    // Shared mocks
    // -------------------------------------------------------------------------

    private lateinit var mockPlugin: FirebasePlugin
    private lateinit var mockFirebaseAuth: FirebaseAuth
    private lateinit var mockActivity: Activity
    private lateinit var mockResources: Resources
    private lateinit var mockGoogleSignInClient: GoogleSignInClient
    private lateinit var mockGodot: Godot
    private lateinit var authentication: Authentication

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    @BeforeEach
    fun setUp() {
        // 1. INITIALIZE MOCKS FIRST
        mockFirebaseAuth = mockk(relaxed = true)

        // Mock Firebase early — BEFORE creating FirebasePlugin or Authentication
        mockkStatic(FirebaseApp::class)
        mockkStatic(FirebaseAuth::class)        // ← Important: mock FirebaseAuth companion

        every { FirebaseApp.getInstance() } returns mockk(relaxed = true)

        // 2. NOW IT IS SAFE TO RETURN mockFirebaseAuth
        // This is the correct way to mock Firebase.auth (Kotlin extension)
        every { FirebaseAuth.getInstance() } returns mockFirebaseAuth

        mockGodot = mockk(relaxed = true)
        mockPlugin = spyk(FirebasePlugin(mockGodot), recordPrivateCalls = true)

        mockActivity = mockk(relaxed = true)
        mockResources = mockk(relaxed = true)
        mockGoogleSignInClient = mockk(relaxed = true)

        mockkStatic(GoogleSignIn::class)
        every { GoogleSignIn.getClient(any(), any()) } returns mockGoogleSignInClient

        // 3. Instantiate the class under test
        authentication = Authentication(mockPlugin)

        // Wire Activity helpers for init()
        every { mockActivity.resources } returns mockResources
        every { mockResources.getIdentifier(any(), any(), any()) } returns 1
        every { mockActivity.getString(any()) } returns "fake-web-client-id"
        every { mockActivity.packageName } returns "org.godotengine.demo"

        authentication.init(mockActivity)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /** Stub a signed-in user on the mock FirebaseAuth instance. */
    private fun signInAs(user: FirebaseUser) {
        every { mockFirebaseAuth.currentUser } returns user
    }

    /** Stub FirebaseAuth so no user is currently signed in. */
    private fun signOutState() {
        every { mockFirebaseAuth.currentUser } returns null
    }

    // =========================================================================
    // init()
    // =========================================================================

    @Nested
    @DisplayName("init()")
    inner class Init {

        @Test
        @DisplayName("skips GoogleSignInClient creation when resource ID is not found")
        fun `missing resource id aborts silently`() {
            // Simulate resource not found
            every { mockResources.getIdentifier(any(), any(), any()) } returns 0

            val freshAuth = Authentication(mockPlugin)
            freshAuth.init(mockActivity) // must not throw

            // signInWithGoogle should fail gracefully because the client was never initialised
            freshAuth.signInWithGoogle()

            verify { mockPlugin.emitGodotSignal("auth_failure", "Google Sign-In not initialized.") }
        }
    }

    // =========================================================================
    // isSignedIn()
    // =========================================================================

    @Nested
    @DisplayName("isSignedIn()")
    inner class IsSignedIn {

        @Test
        @DisplayName("returns true when FirebaseAuth has a current user")
        fun `returns true when user is present`() {
            signInAs(Fixtures.mockFirebaseUser())
            assertTrue(authentication.isSignedIn())
        }

        @Test
        @DisplayName("returns false when FirebaseAuth has no current user")
        fun `returns false when no user`() {
            signOutState()
            assertFalse(authentication.isSignedIn())
        }
    }

    // =========================================================================
    // getCurrentUser()
    // =========================================================================

    @Nested
    @DisplayName("getCurrentUser()")
    inner class GetCurrentUser {

        @Test
        @DisplayName("returns a GodotFirebaseUser wrapping the current FirebaseUser")
        fun `wraps current user`() {
            signInAs(Fixtures.mockFirebaseUser(uid = "curr-uid"))
            val godotUser = authentication.getCurrentUser()
            assertNotNull(godotUser)
            assertTrue(godotUser!!.userId == "curr-uid")
        }

        @Test
        @DisplayName("returns null when no user is signed in")
        fun `returns null when signed out`() {
            signOutState()
            assertNull(authentication.getCurrentUser())
        }
    }

    // =========================================================================
    // createUser()
    // =========================================================================

    @Nested
    @DisplayName("createUser()")
    inner class CreateUser {

        @Test
        @DisplayName("emits auth_success with user data on success")
        fun `emits auth_success on success`() {
            val user = Fixtures.mockFirebaseUser(uid = "new-uid")
            signInAs(user)
            every {
                mockFirebaseAuth.createUserWithEmailAndPassword(any(), any())
            } returns Fixtures.successTask(Fixtures.mockAuthResult(user))

            authentication.createUser("new@example.com", "password")

            verify { mockPlugin.emitGodotSignal("auth_success", any()) }
        }

        @Test
        @DisplayName("emits auth_failure with error message on failure")
        fun `emits auth_failure on failure`() {
            every {
                mockFirebaseAuth.createUserWithEmailAndPassword(any(), any())
            } returns Fixtures.failureTask(RuntimeException("Email already in use"))

            authentication.createUser("taken@example.com", "password")

            verify { mockPlugin.emitGodotSignal("auth_failure", "Email already in use") }
        }

        @Test
        @DisplayName("emits auth_failure when auth succeeds but currentUser is null")
        fun `emits auth_failure when user is null post-creation`() {
            signOutState() // currentUser returns null after creation
            every {
                mockFirebaseAuth.createUserWithEmailAndPassword(any(), any())
            } returns Fixtures.successTask(Fixtures.mockAuthResult(null))

            authentication.createUser("ghost@example.com", "password")

            verify {
                mockPlugin.emitGodotSignal(
                    "auth_failure",
                    "User creation succeeded but user is null.",
                )
            }
        }
    }

    // =========================================================================
    // signIn()
    // =========================================================================

    @Nested
    @DisplayName("signIn()")
    inner class SignIn {

        @Test
        @DisplayName("emits auth_success with user data on success")
        fun `emits auth_success on success`() {
            val user = Fixtures.mockFirebaseUser(uid = "signed-in-uid")
            signInAs(user)
            every {
                mockFirebaseAuth.signInWithEmailAndPassword(any(), any())
            } returns Fixtures.successTask(Fixtures.mockAuthResult(user))

            authentication.signIn("user@example.com", "password")

            verify { mockPlugin.emitGodotSignal("auth_success", any()) }
        }

        @Test
        @DisplayName("emits auth_failure on failure")
        fun `emits auth_failure on failure`() {
            every {
                mockFirebaseAuth.signInWithEmailAndPassword(any(), any())
            } returns Fixtures.failureTask(RuntimeException("Wrong password"))

            authentication.signIn("user@example.com", "wrong")

            verify { mockPlugin.emitGodotSignal("auth_failure", "Wrong password") }
        }

        @Test
        @DisplayName("emits auth_failure when sign-in succeeds but currentUser is null")
        fun `emits auth_failure when user is null post-signin`() {
            signOutState()
            every {
                mockFirebaseAuth.signInWithEmailAndPassword(any(), any())
            } returns Fixtures.successTask(Fixtures.mockAuthResult(null))

            authentication.signIn("user@example.com", "password")

            verify {
                mockPlugin.emitGodotSignal(
                    "auth_failure",
                    "Authentication succeeded but user is null.",
                )
            }
        }
    }

    // =========================================================================
    // signInAnonymously()
    // =========================================================================

    @Nested
    @DisplayName("signInAnonymously()")
    inner class SignInAnonymously {

        @Test
        @DisplayName("emits auth_success when sign-in succeeds")
        fun `emits auth_success on success`() {
            val anonUser = Fixtures.mockAnonymousFirebaseUser()
            // First call returns null (pre-check), second returns the user (post-sign-in)
            every { mockFirebaseAuth.currentUser } returnsMany listOf(null, anonUser)
            every {
                mockFirebaseAuth.signInAnonymously()
            } returns Fixtures.successTask(Fixtures.mockAuthResult(anonUser))

            authentication.signInAnonymously()

            verify { mockPlugin.emitGodotSignal("auth_success", any()) }
        }

        @Test
        @DisplayName("emits auth_failure when a user is already signed in")
        fun `emits auth_failure when already signed in`() {
            signInAs(Fixtures.mockFirebaseUser())

            authentication.signInAnonymously()

            verify { mockPlugin.emitGodotSignal("auth_failure", "User is already signed in.") }
            verify(exactly = 0) { mockFirebaseAuth.signInAnonymously() }
        }

        @Test
        @DisplayName("emits auth_failure on Firebase error")
        fun `emits auth_failure on failure`() {
            signOutState()
            every {
                mockFirebaseAuth.signInAnonymously()
            } returns Fixtures.failureTask(RuntimeException("Network error"))

            authentication.signInAnonymously()

            verify { mockPlugin.emitGodotSignal("auth_failure", "Network error") }
        }

        @Test
        @DisplayName("emits auth_failure when anon sign-in succeeds but currentUser is null")
        fun `emits auth_failure when user is null post-anon-signin`() {
            every { mockFirebaseAuth.currentUser } returns null
            every {
                mockFirebaseAuth.signInAnonymously()
            } returns Fixtures.successTask(Fixtures.mockAuthResult(null))

            authentication.signInAnonymously()

            verify {
                mockPlugin.emitGodotSignal(
                    "auth_failure",
                    "Anonymous sign-in succeeded but user is null.",
                )
            }
        }
    }

    // =========================================================================
    // signOut()
    // =========================================================================

    @Nested
    @DisplayName("signOut()")
    inner class SignOut {

        @Test
        @DisplayName("emits sign_out_success = true when Google sign-out completes")
        fun `emits sign_out_success true on complete`() {
            every { mockGoogleSignInClient.signOut() } returns Fixtures.completeSuccessTask()

            authentication.signOut()

            verify { mockFirebaseAuth.signOut() }
            verify { mockPlugin.emitGodotSignal("sign_out_success", true) }
        }

        @Test
        @DisplayName("emits sign_out_success = false and auth_failure when Google sign-out fails")
        fun `emits sign_out_success false and auth_failure on failure`() {
            every {
                mockGoogleSignInClient.signOut()
            } returns Fixtures.completeFailureTask(RuntimeException("Sign-out failed"))

            authentication.signOut()

            verify { mockPlugin.emitGodotSignal("sign_out_success", false) }
            verify {
                mockPlugin.emitGodotSignal(
                    "auth_failure",
                    "Failed to sign out: Sign-out failed",
                )
            }
        }
    }

    // =========================================================================
    // sendVerificationEmail()
    // =========================================================================

    @Nested
    @DisplayName("sendVerificationEmail()")
    inner class SendVerificationEmail {

        @Test
        @DisplayName("emits email_verification_sent = true on success")
        fun `emits email_verification_sent true on success`() {
            val user = mockk<FirebaseUser>()
            every { user.sendEmailVerification() } returns Fixtures.successTask<Void?>(null)
            signInAs(user)

            authentication.sendVerificationEmail()

            verify { mockPlugin.emitGodotSignal("email_verification_sent", true) }
        }

        @Test
        @DisplayName("emits email_verification_sent = false and auth_failure on failure")
        fun `emits email_verification_sent false and auth_failure on failure`() {
            val user = mockk<FirebaseUser>()
            every {
                user.sendEmailVerification()
            } returns Fixtures.failureTask(RuntimeException("Rate limit exceeded"))
            signInAs(user)

            authentication.sendVerificationEmail()

            verify { mockPlugin.emitGodotSignal("email_verification_sent", false) }
            verify {
                mockPlugin.emitGodotSignal(
                    "auth_failure",
                    "Failed to send verification email: Rate limit exceeded"
                )
            }
        }

        @Test
        @DisplayName("does nothing when no user is signed in")
        fun `no-op when signed out`() {
            signOutState()

            authentication.sendVerificationEmail()

            verify(exactly = 0) { mockPlugin.emitGodotSignal(any(), any()) }
        }
    }

    // =========================================================================
    // sendPasswordResetEmail()
    // =========================================================================

    @Nested
    @DisplayName("sendPasswordResetEmail()")
    inner class SendPasswordResetEmail {

        @Test
        @DisplayName("emits password_reset_sent = true on success")
        fun `emits password_reset_sent true on success`() {
            every {
                mockFirebaseAuth.sendPasswordResetEmail(any())
            } returns Fixtures.successTask<Void?>(null)

            authentication.sendPasswordResetEmail("user@example.com")

            verify { mockPlugin.emitGodotSignal("password_reset_sent", true) }
        }

        @Test
        @DisplayName("emits password_reset_sent = false and auth_failure on failure")
        fun `emits password_reset_sent false and auth_failure on failure`() {
            every {
                mockFirebaseAuth.sendPasswordResetEmail(any())
            } returns Fixtures.failureTask(RuntimeException("Invalid email"))

            authentication.sendPasswordResetEmail("bad@example.com")

            verify { mockPlugin.emitGodotSignal("password_reset_sent", false) }
            verify {
                mockPlugin.emitGodotSignal(
                    "auth_failure",
                    "Failed to send password reset email: Invalid email"
                )
            }
        }
    }

    // =========================================================================
    // deleteCurrentUser()
    // =========================================================================

    @Nested
    @DisplayName("deleteCurrentUser()")
    inner class DeleteCurrentUser {

        @Test
        @DisplayName("emits user_deleted = true on success")
        fun `emits user_deleted true on success`() {
            val user = mockk<FirebaseUser>()
            every { user.delete() } returns Fixtures.successTask<Void?>(null)
            signInAs(user)

            authentication.deleteCurrentUser()

            verify { mockPlugin.emitGodotSignal("user_deleted", true) }
        }

        @Test
        @DisplayName("emits user_deleted = false and auth_failure on failure")
        fun `emits user_deleted false and auth_failure on failure`() {
            val user = mockk<FirebaseUser>()
            every {
                user.delete()
            } returns Fixtures.failureTask(RuntimeException("Requires recent login"))
            signInAs(user)

            authentication.deleteCurrentUser()

            verify { mockPlugin.emitGodotSignal("user_deleted", false) }
            verify {
                mockPlugin.emitGodotSignal(
                    "auth_failure",
                    "Delete failed: Requires recent login",
                )
            }
        }

        @Test
        @DisplayName("does nothing when no user is signed in")
        fun `no-op when signed out`() {
            signOutState()

            authentication.deleteCurrentUser()

            verify(exactly = 0) { mockPlugin.emitGodotSignal(any(), any()) }
        }
    }

    // =========================================================================
    // linkAnonymousWithGoogle()
    // =========================================================================

    @Nested
    @DisplayName("linkAnonymousWithGoogle()")
    inner class LinkAnonymousWithGoogle {

        @Test
        @DisplayName("emits link_with_google_failure when no user is signed in")
        fun `emits link_failure when no user`() {
            signOutState()

            authentication.linkAnonymousWithGoogle()

            verify { mockPlugin.emitGodotSignal("link_with_google_failure", "No user signed in.") }
        }

        @Test
        @DisplayName("emits link_with_google_failure when current user is not anonymous")
        fun `emits link_failure when user is not anonymous`() {
            signInAs(Fixtures.mockFirebaseUser(isAnonymous = false))

            authentication.linkAnonymousWithGoogle()

            verify {
                mockPlugin.emitGodotSignal(
                    "link_with_google_failure",
                    "Current user is not anonymous.",
                )
            }
        }

        @Test
        @DisplayName("starts Google sign-in flow when current user is anonymous")
        fun `starts google sign-in when user is anonymous`() {
            signInAs(Fixtures.mockAnonymousFirebaseUser())
            val signInIntent = mockk<Intent>()
            every { mockGoogleSignInClient.signInIntent } returns signInIntent
            every { mockActivity.startActivityForResult(any(), any()) } just Runs

            authentication.linkAnonymousWithGoogle()

            verify { mockActivity.startActivityForResult(signInIntent, 9001) }
        }
    }

    // =========================================================================
    // signInWithGoogle()
    // =========================================================================

    @Nested
    @DisplayName("signInWithGoogle()")
    inner class SignInWithGoogle {

        @Test
        @DisplayName("launches the Google sign-in intent")
        fun `launches sign-in intent`() {
            val signInIntent = mockk<Intent>()
            every { mockGoogleSignInClient.signInIntent } returns signInIntent
            every { mockActivity.startActivityForResult(any(), any()) } just Runs

            authentication.signInWithGoogle()

            verify { mockActivity.startActivityForResult(signInIntent, 9001) }
        }
    }

    // =========================================================================
    // handleActivityResult()
    // =========================================================================

    @Nested
    @DisplayName("handleActivityResult()")
    inner class HandleActivityResult {

        @Test
        @DisplayName("ignores results for unrelated request codes")
        fun `ignores unrelated request code`() {
            authentication.handleActivityResult(
                requestCode = 1234,
                resultCode = Activity.RESULT_OK,
                data = null,
            )

            verify(exactly = 0) { mockPlugin.emitGodotSignal(any(), any()) }
        }

        @Test
        @DisplayName("emits auth_failure when Google account task throws ApiException")
        fun `emits auth_failure on ApiException`() {
            val data = mockk<Intent>()

            @Suppress("UNCHECKED_CAST")
            val failedTask = mockk<Task<GoogleSignInAccount>>()
            every {
                failedTask.getResult(ApiException::class.java)
            } throws ApiException(Status(7, "Network error"))

            every { GoogleSignIn.getSignedInAccountFromIntent(data) } returns failedTask

            authentication.handleActivityResult(
                requestCode = 9001,
                resultCode = Activity.RESULT_OK,
                data = data,
            )

            verify { mockPlugin.emitGodotSignal("auth_failure", any()) }
        }

        @Test
        @DisplayName("emits link_with_google_failure when ApiException occurs during linking flow")
        fun `emits link_failure on ApiException during linking`() {
            // Prime the authentication into linking mode
            signInAs(Fixtures.mockAnonymousFirebaseUser())
            val signInIntent = mockk<Intent>()
            every { mockGoogleSignInClient.signInIntent } returns signInIntent
            every { mockActivity.startActivityForResult(any(), any()) } just Runs
            authentication.linkAnonymousWithGoogle() // sets isLinkingAnonymous = true

            val data = mockk<Intent>()

            @Suppress("UNCHECKED_CAST")
            val failedTask = mockk<Task<GoogleSignInAccount>>()
            every {
                failedTask.getResult(ApiException::class.java)
            } throws ApiException(Status(7, "Network error"))
            every { GoogleSignIn.getSignedInAccountFromIntent(data) } returns failedTask

            authentication.handleActivityResult(
                requestCode = 9001,
                resultCode = Activity.RESULT_OK,
                data = data,
            )

            verify { mockPlugin.emitGodotSignal("link_with_google_failure", any()) }
        }
    }

    // =========================================================================
    // authSignals()
    // =========================================================================

    @Nested
    @DisplayName("authSignals()")
    inner class AuthSignals {

        @Test
        @DisplayName("returns eight signals")
        fun `returns 8 signals`() {
            assertTrue(authentication.authSignals().size == 8)
        }

        @Test
        @DisplayName("includes all expected signal names")
        fun `includes all expected signal names`() {
            val names = authentication.authSignals().map { it.name }.toSet()
            val expected = setOf(
                "auth_success",
                "auth_failure",
                "link_with_google_success",
                "link_with_google_failure",
                "sign_out_success",
                "password_reset_sent",
                "email_verification_sent",
                "user_deleted",
            )
            assertTrue(names.containsAll(expected)) {
                "Missing signals: ${expected - names}"
            }
        }
    }
}
