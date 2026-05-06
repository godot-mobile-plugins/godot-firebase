//
// © 2026-present Firebase Team https://github.com/firebase-team
//
package org.godotengine.plugin.firebase.model

import android.net.Uri
import io.mockk.every
import io.mockk.mockk
import org.godotengine.plugin.firebase.fixtures.Fixtures
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

@DisplayName("GodotFirebaseUser")
class GodotFirebaseUserTest {
    // -------------------------------------------------------------------------
    // Construction from FirebaseUser
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("constructor(FirebaseUser)")
    inner class FromFirebaseUser {
        @Test
        @DisplayName("populates userId from uid")
        fun `maps uid to userId`() {
            val user = Fixtures.mockFirebaseUser(uid = "abc-123")
            assertEquals("abc-123", GodotFirebaseUser(user).userId)
        }

        @Test
        @DisplayName("populates displayName")
        fun `maps displayName to name`() {
            val user = Fixtures.mockFirebaseUser(displayName = "Alice")
            assertEquals("Alice", GodotFirebaseUser(user).name)
        }

        @Test
        @DisplayName("populates email")
        fun `maps email`() {
            val user = Fixtures.mockFirebaseUser(email = "alice@example.com")
            assertEquals("alice@example.com", GodotFirebaseUser(user).email)
        }

        @Test
        @DisplayName("stores photoUrl as a string when present")
        fun `maps photoUrl toString`() {
            val uri = mockk<Uri>()
            every { uri.toString() } returns "https://example.com/avatar.png"
            val user = Fixtures.mockFirebaseUserWithPhoto(photoUri = uri)
            assertEquals("https://example.com/avatar.png", GodotFirebaseUser(user).photoUrl)
        }

        @Test
        @DisplayName("stores empty string for photoUrl when FirebaseUser.photoUrl is null")
        fun `null photoUrl becomes empty string`() {
            val user = Fixtures.mockFirebaseUser(photoUrl = null)
            // The raw dict value will be null; the getter returns "" via safe cast
            assertEquals("", GodotFirebaseUser(user).photoUrl)
        }

        @Test
        @DisplayName("reflects isEmailVerified = true")
        fun `isEmailVerified true`() {
            val user = Fixtures.mockFirebaseUser(isEmailVerified = true)
            assertTrue(GodotFirebaseUser(user).isEmailVerified)
        }

        @Test
        @DisplayName("reflects isEmailVerified = false")
        fun `isEmailVerified false`() {
            val user = Fixtures.mockUnverifiedFirebaseUser()
            assertFalse(GodotFirebaseUser(user).isEmailVerified)
        }

        @Test
        @DisplayName("reflects isAnonymous = true for anonymous users")
        fun `isAnonymous true`() {
            val user = Fixtures.mockAnonymousFirebaseUser()
            assertTrue(GodotFirebaseUser(user).isAnonymous)
        }

        @Test
        @DisplayName("reflects isAnonymous = false for authenticated users")
        fun `isAnonymous false`() {
            val user = Fixtures.mockFirebaseUser(isAnonymous = false)
            assertFalse(GodotFirebaseUser(user).isAnonymous)
        }

        @Test
        @DisplayName("handles null displayName from FirebaseUser")
        fun `null displayName becomes empty string`() {
            val user = Fixtures.mockAnonymousFirebaseUser() // displayName = null
            assertEquals("", GodotFirebaseUser(user).name)
        }

        @Test
        @DisplayName("handles null email from FirebaseUser")
        fun `null email becomes empty string`() {
            val user = Fixtures.mockAnonymousFirebaseUser() // email = null
            assertEquals("", GodotFirebaseUser(user).email)
        }
    }

    // -------------------------------------------------------------------------
    // Default (no-arg) constructor
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("default constructor")
    inner class DefaultConstructor {
        @Test
        @DisplayName("userId defaults to empty string")
        fun `userId is empty by default`() {
            assertEquals("", GodotFirebaseUser().userId)
        }

        @Test
        @DisplayName("name defaults to empty string")
        fun `name is empty by default`() {
            assertEquals("", GodotFirebaseUser().name)
        }

        @Test
        @DisplayName("email defaults to empty string")
        fun `email is empty by default`() {
            assertEquals("", GodotFirebaseUser().email)
        }

        @Test
        @DisplayName("photoUrl defaults to empty string")
        fun `photoUrl is empty by default`() {
            assertEquals("", GodotFirebaseUser().photoUrl)
        }

        @Test
        @DisplayName("isEmailVerified defaults to false")
        fun `isEmailVerified is false by default`() {
            assertFalse(GodotFirebaseUser().isEmailVerified)
        }

        @Test
        @DisplayName("isAnonymous defaults to false")
        fun `isAnonymous is false by default`() {
            assertFalse(GodotFirebaseUser().isAnonymous)
        }
    }

    // -------------------------------------------------------------------------
    // Property setters
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("property setters")
    inner class PropertySetters {
        @Test
        @DisplayName("userId setter updates value")
        fun `userId setter`() {
            val user = GodotFirebaseUser()
            user.userId = "new-uid"
            assertEquals("new-uid", user.userId)
        }

        @Test
        @DisplayName("name setter updates value")
        fun `name setter`() {
            val user = GodotFirebaseUser()
            user.name = "Bob"
            assertEquals("Bob", user.name)
        }

        @Test
        @DisplayName("email setter updates value")
        fun `email setter`() {
            val user = GodotFirebaseUser()
            user.email = "bob@example.com"
            assertEquals("bob@example.com", user.email)
        }

        @Test
        @DisplayName("photoUrl setter updates value")
        fun `photoUrl setter`() {
            val user = GodotFirebaseUser()
            user.photoUrl = "https://cdn.example.com/pic.png"
            assertEquals("https://cdn.example.com/pic.png", user.photoUrl)
        }

        @Test
        @DisplayName("isEmailVerified setter updates value")
        fun `isEmailVerified setter`() {
            val user = GodotFirebaseUser()
            user.isEmailVerified = true
            assertTrue(user.isEmailVerified)
        }

        @Test
        @DisplayName("isAnonymous setter updates value")
        fun `isAnonymous setter`() {
            val user = GodotFirebaseUser()
            user.isAnonymous = true
            assertTrue(user.isAnonymous)
        }
    }

    // -------------------------------------------------------------------------
    // getRawData()
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("getRawData()")
    inner class GetRawData {
        @Test
        @DisplayName("returns a non-null Dictionary")
        fun `returns non-null dictionary`() {
            assertNotNull(Fixtures.godotFirebaseUser().getRawData())
        }

        @Test
        @DisplayName("dictionary contains the user_id key")
        fun `dictionary contains user_id`() {
            val rawData = Fixtures.godotFirebaseUser(uid = "xyz-789").getRawData()
            assertEquals("xyz-789", rawData[GodotFirebaseUser.USER_ID_PROPERTY])
        }

        @Test
        @DisplayName("dictionary contains the name key")
        fun `dictionary contains name`() {
            val rawData = Fixtures.godotFirebaseUser(displayName = "Carol").getRawData()
            assertEquals("Carol", rawData[GodotFirebaseUser.NAME_PROPERTY])
        }

        @Test
        @DisplayName("dictionary contains the email key")
        fun `dictionary contains email`() {
            val rawData = Fixtures.godotFirebaseUser(email = "carol@example.com").getRawData()
            assertEquals("carol@example.com", rawData[GodotFirebaseUser.EMAIL_PROPERTY])
        }

        @Test
        @DisplayName("dictionary contains the is_email_verified key")
        fun `dictionary contains is_email_verified`() {
            val rawData = Fixtures.godotFirebaseUser(isEmailVerified = true).getRawData()
            assertEquals(true, rawData[GodotFirebaseUser.IS_EMAIL_VERIFIED_PROPERTY])
        }

        @Test
        @DisplayName("dictionary contains the is_anonymous key")
        fun `dictionary contains is_anonymous`() {
            val rawData = Fixtures.godotAnonymousUser().getRawData()
            assertEquals(true, rawData[GodotFirebaseUser.IS_ANONYMOUS_PROPERTY])
        }

        @Test
        @DisplayName("getRawData returns the same Dictionary instance on successive calls")
        fun `getRawData returns same instance`() {
            val user = Fixtures.godotFirebaseUser()
            assertSame(user.getRawData(), user.getRawData())
        }

        @Test
        @DisplayName("mutations via setters are visible in getRawData()")
        fun `setter mutations visible in dictionary`() {
            val user = GodotFirebaseUser()
            user.userId = "mutated-uid"
            user.email = "mutated@example.com"
            val rawData = user.getRawData()
            assertEquals("mutated-uid", rawData[GodotFirebaseUser.USER_ID_PROPERTY])
            assertEquals("mutated@example.com", rawData[GodotFirebaseUser.EMAIL_PROPERTY])
        }
    }

    // -------------------------------------------------------------------------
    // Companion object constants
    // -------------------------------------------------------------------------

    @Nested
    @DisplayName("companion object constants")
    inner class CompanionConstants {
        @Test
        @DisplayName("USER_ID_PROPERTY has expected key string")
        fun `USER_ID_PROPERTY value`() {
            assertEquals("user_id", GodotFirebaseUser.USER_ID_PROPERTY)
        }

        @Test
        @DisplayName("NAME_PROPERTY has expected key string")
        fun `NAME_PROPERTY value`() {
            assertEquals("name", GodotFirebaseUser.NAME_PROPERTY)
        }

        @Test
        @DisplayName("EMAIL_PROPERTY has expected key string")
        fun `EMAIL_PROPERTY value`() {
            assertEquals("email", GodotFirebaseUser.EMAIL_PROPERTY)
        }

        @Test
        @DisplayName("PHOTO_URL_PROPERTY has expected key string")
        fun `PHOTO_URL_PROPERTY value`() {
            assertEquals("photo_url", GodotFirebaseUser.PHOTO_URL_PROPERTY)
        }

        @Test
        @DisplayName("IS_EMAIL_VERIFIED_PROPERTY has expected key string")
        fun `IS_EMAIL_VERIFIED_PROPERTY value`() {
            assertEquals("is_email_verified", GodotFirebaseUser.IS_EMAIL_VERIFIED_PROPERTY)
        }

        @Test
        @DisplayName("IS_ANONYMOUS_PROPERTY has expected key string")
        fun `IS_ANONYMOUS_PROPERTY value`() {
            assertEquals("is_anonymous", GodotFirebaseUser.IS_ANONYMOUS_PROPERTY)
        }
    }
}
