//
// © 2026-present Firebase Team https://github.com/firebase-team
//

import FirebaseAuth
import Foundation
import GoogleSignIn
import UIKit

// MARK: - Authentication

@objc public class Authentication: NSObject {

	// -----------------------------------------------------------------------
	// MARK: Constants
	// -----------------------------------------------------------------------

	private static let tag = "GodotFirebaseAuth"

	// -----------------------------------------------------------------------
	// MARK: State
	// -----------------------------------------------------------------------

	private let emitter: any AuthenticationEmitting

	/// Injected auth provider — FirebaseAuthWrapper in production,
	/// MockAuth in unit tests.
	private let auth: AuthProviding

	/// Injected Google Sign-In provider — GIDSignInWrapper in production,
	/// MockGoogleSignIn in unit tests.
	private let googleSignIn: GoogleSignInProviding

	/// Retained so it is available when the Google Sign-In completion fires.
	/// Strong — not weak — because in unit tests the view controller is owned
	/// only by this property; a weak reference deallocates it immediately,
	/// causing every Google sign-in path to hit the 'not initialized' guard.
	/// In production the view controller is independently owned by the window
	/// hierarchy, so there is no retain cycle in either context.
	private var viewController: UIViewController?

	/// Set to true before triggering Google Sign-In from linkAnonymousWithGoogle(),
	/// cleared in the completion handler regardless of success or failure.
	private var isLinkingAnonymous = false

	// -----------------------------------------------------------------------
	// MARK: Initialisers
	// -----------------------------------------------------------------------

	/// Production initialiser — called from FirebasePlugin.mm.
	/// Uses the real Firebase Auth and Google Sign-In singletons.
	@objc public init(emitter: any AuthenticationEmitting, viewController: UIViewController) {
		self.emitter = emitter
		self.auth = FirebaseAuthWrapper()
		self.googleSignIn = GIDSignInWrapper()
		self.viewController = viewController
	}

	/// Test-only initialiser.  `internal` visibility lets @testable imports
	/// reach it without exposing it as part of the public API.
	/// No Firebase singleton is touched.
	init(
		emitter: any AuthenticationEmitting,
		auth: AuthProviding,
		googleSignIn: GoogleSignInProviding,
		viewController: UIViewController? = nil
	) {
		self.emitter = emitter
		self.auth = auth
		self.googleSignIn = googleSignIn
		self.viewController = viewController
	}

	// -----------------------------------------------------------------------
	// MARK: Public API — mirrors every fun in Authentication.kt
	// -----------------------------------------------------------------------

	// MARK: createUser

	@objc public func createUser(_ email: String, password: String) {
		auth.createUser(withEmail: email, password: password) { [weak self] _, error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] User creation failed: \(error.localizedDescription)")
				self.emitter.emitAuthFailure(error.localizedDescription)
				return
			}
			guard let godotUser = self.getCurrentUser() else {
				NSLog("[\(Self.tag)] User creation succeeded but user is nil.")
				self.emitter.emitAuthFailure("User creation succeeded but user is null.")
				return
			}
			NSLog("[\(Self.tag)] User created with email: \(email)")
			self.emitter.emitAuthSuccess(godotUser)
		}
	}

	// MARK: signIn

	@objc public func signIn(_ email: String, password: String) {
		auth.signIn(withEmail: email, password: password) { [weak self] _, error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] Sign-in with email failed: \(error.localizedDescription)")
				self.emitter.emitAuthFailure(error.localizedDescription)
				return
			}
			guard let godotUser = self.getCurrentUser() else {
				NSLog("[\(Self.tag)] Authentication succeeded but user is nil.")
				self.emitter.emitAuthFailure("Authentication succeeded but user is null.")
				return
			}
			NSLog("[\(Self.tag)] Signed in with email: \(email)")
			self.emitter.emitAuthSuccess(godotUser)
		}
	}

	// MARK: signInAnonymously

	@objc public func signInAnonymously() {
		if let currentUser = auth.currentUser {
			NSLog(
				"[\(Self.tag)] User already signed in (uid=\(currentUser.uid), " +
					"isAnonymous=\(currentUser.isAnonymous)). Skipping anonymous sign-in."
			)
			emitter.emitAuthFailure("User is already signed in.")
			return
		}
		auth.signInAnonymously { [weak self] _, error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] Anonymous sign-in failed: \(error.localizedDescription)")
				self.emitter.emitAuthFailure(error.localizedDescription)
				return
			}
			guard let godotUser = self.getCurrentUser() else {
				NSLog("[\(Self.tag)] Anonymous sign-in succeeded but user is nil.")
				self.emitter.emitAuthFailure("Anonymous sign-in succeeded but user is null.")
				return
			}
			let uid = self.auth.currentUser?.uid ?? "unknown"
			NSLog("[\(Self.tag)] Signed in anonymously as \(uid)")
			self.emitter.emitAuthSuccess(godotUser)
		}
	}

	// MARK: signInWithGoogle

	@objc public func signInWithGoogle() {
		guard let viewController else {
			NSLog("[\(Self.tag)] ViewController not set.")
			emitter.emitAuthFailure("Google Sign-In not initialized.")
			return
		}
		googleSignIn.signIn(withPresenting: viewController) { [weak self] idToken, accessToken, error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] Google sign-in failed: \(error.localizedDescription)")
				self.emitter.emitAuthFailure(error.localizedDescription)
				return
			}
			guard let idToken else {
				NSLog("[\(Self.tag)] Google sign-in: missing ID token.")
				self.emitter.emitAuthFailure("Google Sign-In: missing ID token.")
				return
			}
			self.authWithGoogle(idToken: idToken, accessToken: accessToken)
		}
	}

	// MARK: linkAnonymousWithGoogle

	@objc public func linkAnonymousWithGoogle() {
		guard let currentUser = auth.currentUser else {
			NSLog("[\(Self.tag)] No user signed in.")
			emitter.emitLinkFailure("No user signed in.")
			return
		}
		guard currentUser.isAnonymous else {
			NSLog("[\(Self.tag)] Current user is not anonymous (uid=\(currentUser.uid)). Cannot link.")
			emitter.emitLinkFailure("Current user is not anonymous.")
			return
		}
		NSLog("[\(Self.tag)] Linking anonymous user (uid=\(currentUser.uid)) with Google.")
		isLinkingAnonymous = true
		presentGoogleSignInForLinking()
	}

	// MARK: isSignedIn

	@objc public func isSignedIn() -> Bool {
		return auth.currentUser != nil
	}

	// MARK: signOut

	@objc public func signOut() {
		do {
			try auth.signOut()
			googleSignIn.signOut()
			NSLog("[\(Self.tag)] Signed out successfully.")
			emitter.emitSignOutSuccess(true)
		} catch {
			NSLog("[\(Self.tag)] Sign-out failed: \(error.localizedDescription)")
			emitter.emitSignOutSuccess(false)
			emitter.emitAuthFailure("Failed to sign out: \(error.localizedDescription)")
		}
	}

	// MARK: sendVerificationEmail

	@objc public func sendVerificationEmail() {
		guard let currentUser = auth.currentUser else { return }
		currentUser.sendEmailVerification { [weak self] error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] Failed to send verification email: \(error.localizedDescription)")
				self.emitter.emitEmailVerificationSent(false)
				self.emitter.emitAuthFailure(
					"Failed to send verification email: \(error.localizedDescription)"
				)
				return
			}
			NSLog("[\(Self.tag)] Verification email sent.")
			self.emitter.emitEmailVerificationSent(true)
		}
	}

	// MARK: sendPasswordResetEmail

	@objc public func sendPasswordResetEmail(_ email: String) {
		auth.sendPasswordReset(withEmail: email) { [weak self] error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] Password reset failed: \(error.localizedDescription)")
				self.emitter.emitPasswordResetSent(false)
				self.emitter.emitAuthFailure(
					"Failed to send password reset email: \(error.localizedDescription)"
				)
				return
			}
			NSLog("[\(Self.tag)] Password reset email sent to \(email).")
			self.emitter.emitPasswordResetSent(true)
		}
	}

	// MARK: getCurrentUser

	@objc public func getCurrentUser() -> GodotFirebaseUser? {
		guard let user = auth.currentUser else { return nil }
		return GodotFirebaseUser(
			userId: user.uid,
			name: user.displayName,
			email: user.email,
			photoUrl: user.photoURL?.absoluteString,
			isEmailVerified: user.isEmailVerified,
			isAnonymous: user.isAnonymous
		)
	}

	// MARK: deleteCurrentUser

	@objc public func deleteCurrentUser() {
		guard let currentUser = auth.currentUser else { return }
		currentUser.delete { [weak self] error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] Failed to delete user: \(error.localizedDescription)")
				self.emitter.emitUserDeleted(false)
				self.emitter.emitAuthFailure("Delete failed: \(error.localizedDescription)")
				return
			}
			NSLog("[\(Self.tag)] User deleted.")
			self.emitter.emitUserDeleted(true)
		}
	}

	// -----------------------------------------------------------------------
	// MARK: Private helpers
	// -----------------------------------------------------------------------

	private func authWithGoogle(idToken: String, accessToken: String) {
		let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
		auth.signIn(with: credential) { [weak self] result, error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] signInWithCredential:failure: \(error.localizedDescription)")
				self.emitter.emitAuthFailure(error.localizedDescription)
				return
			}
			guard let godotUser = self.getCurrentUser() else {
				NSLog("[\(Self.tag)] Authentication with Google succeeded but user is nil.")
				self.emitter.emitAuthFailure("Authentication with Google succeeded but user is null.")
				return
			}
			let uid = result?.user.uid ?? "unknown"
			NSLog("[\(Self.tag)] signInWithCredential:success -> \(uid)")
			self.emitter.emitAuthSuccess(godotUser)
		}
	}

	private func linkWithGoogle(idToken: String, accessToken: String) {
		guard let currentUser = auth.currentUser else {
			NSLog("[\(Self.tag)] No user signed in during linkWithGoogle.")
			emitter.emitLinkFailure("No user signed in.")
			return
		}
		let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
		currentUser.link(with: credential) { [weak self] result, error in
			guard let self else { return }
			if let error {
				NSLog("[\(Self.tag)] linkWithCredential:failure: \(error.localizedDescription)")
				self.emitter.emitLinkFailure(error.localizedDescription)
				return
			}
			guard let godotUser = self.getCurrentUser() else {
				NSLog("[\(Self.tag)] linkWithCredential succeeded but user is nil.")
				self.emitter.emitLinkFailure("Link succeeded but user is null.")
				return
			}
			let uid = result?.user.uid ?? "unknown"
			NSLog("[\(Self.tag)] linkWithCredential:success -> \(uid)")
			self.emitter.emitLinkSuccess(godotUser)
		}
	}

	private func presentGoogleSignInForLinking() {
		guard let viewController else {
			NSLog("[\(Self.tag)] ViewController not set.")
			isLinkingAnonymous = false
			emitter.emitLinkFailure("Google Sign-In not initialized.")
			return
		}
		googleSignIn.signIn(
			withPresenting: viewController
		) { [weak self] idToken, accessToken, error in
			guard let self else { return }
			let wasLinking = self.isLinkingAnonymous
			self.isLinkingAnonymous = false

			if let error {
				NSLog(
					"[\(Self.tag)] Google sign-in failed during link: \(error.localizedDescription)"
				)
				if wasLinking {
					self.emitter.emitLinkFailure(error.localizedDescription)
				} else {
					self.emitter.emitAuthFailure(error.localizedDescription)
				}
				return
			}
			guard let idToken else {
				NSLog("[\(Self.tag)] Google sign-in (link): missing ID token.")
				self.emitter.emitLinkFailure("Google Sign-In: missing ID token.")
				return
			}
			if wasLinking {
				self.linkWithGoogle(idToken: idToken, accessToken: accessToken)
			} else {
				self.authWithGoogle(idToken: idToken, accessToken: accessToken)
			}
		}
	}
}
