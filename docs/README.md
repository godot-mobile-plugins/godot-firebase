<div align="center">

![](https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/demo/assets/firebase-android.png) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ![](https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/demo/assets/firebase-ios.png)

</div>

<div align="center">
	<a href="https://github.com/godot-mobile-plugins/godot-firebase"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-firebase?label=Stars&style=plastic" height="40"/></a>
	<img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-firebase?label=Latest%20Release&style=plastic" height="40"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/latest/total?label=Downloads&style=plastic" height="40"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/total?label=Total%20Downloads&style=plastic" height="40"/>
</div>

<br>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="24"> Godot Firebase Plugin

A Godot plugin that provides a unified GDScript interface for **Firebase** services on **Android** and **iOS**, with a modular node-based architecture that makes it easy to add and manage Firebase features directly in your scene tree.

**Key Features:**
- **Firebase Authentication** — email/password, Google Sign-In, and anonymous sign-in
- **User Management** — create accounts, sign in/out, delete users, send verification and password-reset emails
- **Account Linking** — link anonymous accounts to Google credentials
- **Modular Architecture** — each Firebase service is a self-contained child node of the `Firebase` root node (e.g. `FirebaseAuth`), making it easy to add only the modules you need
- **Signal-Based API** — all async operations emit typed GDScript signals for clean, decoupled code
- **Cross-Platform** — single GDScript interface for both Android and iOS native SDKs

<br>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Signals](#signals)
- [Methods](#methods)
- [Classes](#classes)
- [Nodes](#nodes)
- [Platform-Specific Notes](#platform-specific-notes)
- [Links](#links)
- [All Plugins](#all-plugins)
- [Credits](#credits)
- [Contributing](#contributing)

<br>

<a name="installation"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Installation
_Before installing this plugin, make sure to uninstall any previous versions of the same plugin._

_If installing both Android and iOS versions of the plugin in the same project, then make sure that both versions use the same addon interface version._

There are 2 ways to install the `Firebase` plugin into your project:
- Through the Godot Editor's AssetLib
- Manually by downloading archives from Github

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="18"> Installing via AssetLib
Steps:
- search for and select the `Firebase` plugin in Godot Editor
- click `Download` button
- on the installation dialog...
	- keep `Change Install Folder` setting pointing to your project's root directory
	- keep `Ignore asset root` checkbox checked
	- click `Install` button
- enable the plugin via the `Plugins` tab of `Project->Project Settings...` menu, in the Godot Editor

#### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="16"> Installing both Android and iOS versions of the plugin in the same project
When installing via AssetLib, the installer may display a warning that states "_[x number of]_ files conflict with your project and won't be installed." You can ignore this warning since both versions use the same addon code.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="18"> Installing manually
Steps:
- download release archive from Github
- unzip the release archive
- copy to your Godot project's root directory
- enable the plugin via the `Plugins` tab of `Project->Project Settings...` menu, in the Godot Editor

<a name="usage"></a>


## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Usage

Add a `Firebase` node to your main scene (or an autoload global scene), then add a `FirebaseAuth` node as a child of `Firebase` to enable authentication features. Each Firebase module is a separate child node — only add the ones your project needs.

- Connect to signals on the `FirebaseAuth` node before calling any methods
- Call authentication methods directly on the `FirebaseAuth` node
- Use the returned `FirebaseUser` object to access the signed-in user's profile data

Example usage:
```gdscript
@onready var firebase: Firebase = $Firebase
@onready var auth: FirebaseAuth = $Firebase/FirebaseAuth

func _ready() -> void:
	auth.auth_success.connect(_on_auth_success)
	auth.auth_failure.connect(_on_auth_failure)
	auth.sign_out_success.connect(_on_sign_out_success)

	# Check if a user is already signed in
	if auth.is_signed_in():
		var user: FirebaseUser = auth.get_current_user()
		print("Already signed in as: %s (%s)" % [user.get_name(), user.get_email()])
	else:
		auth.sign_in("user@example.com", "password123")

func _on_auth_success(user: FirebaseUser) -> void:
	print("Signed in: %s (verified: %s)" % [user.get_email(), user.get_is_email_verified()])

func _on_auth_failure(error_message: String) -> void:
	print("Auth failed: %s" % error_message)

func _on_sign_out_success(success: bool) -> void:
	print("Signed out successfully: %s" % success)
```

<a name="signals"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Signals

### FirebaseAuth Signals

| Signal | Parameters | Description |
| :--- | :--- | :--- |
| `auth_success` | `user: FirebaseUser` | Emitted when a sign-in or account creation succeeds. The resulting `FirebaseUser` object contains the authenticated user's profile. |
| `auth_failure` | `error_message: String` | Emitted when a sign-in or account creation attempt fails. |
| `link_with_google_success` | `user: FirebaseUser` | Emitted when an anonymous account is successfully linked to a Google credential. |
| `link_with_google_failure` | `error_message: String` | Emitted when linking an anonymous account to Google fails. |
| `sign_out_success` | `success: bool` | Emitted after a sign-out attempt, indicating whether it succeeded. |
| `password_reset_sent` | `success: bool` | Emitted after attempting to send a password-reset email, indicating whether it was sent successfully. |
| `email_verification_sent` | `success: bool` | Emitted after attempting to send a verification email to the current user, indicating whether it was sent successfully. |
| `user_deleted` | `success: bool` | Emitted after attempting to delete the current user's account, indicating whether the deletion succeeded. |

<a name="methods"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Methods

### FirebaseAuth Methods

| Method | Returns | Description |
| :--- | :---: | :--- |
| `create_user(email: String, password: String)` | `void` | Creates a new Firebase user account with the given email and password. Emits `auth_success` or `auth_failure`. |
| `sign_in(email: String, password: String)` | `void` | Signs in an existing user with email and password. Emits `auth_success` or `auth_failure`. |
| `sign_in_with_google()` | `void` | Starts the Google Sign-In flow. Emits `auth_success` or `auth_failure`. |
| `sign_in_anonymously()` | `void` | Signs in the user anonymously. Emits `auth_success` or `auth_failure`. |
| `link_anonymous_with_google()` | `void` | Links the currently signed-in anonymous account to a Google credential. Emits `link_with_google_success` or `link_with_google_failure`. |
| `is_signed_in()` | `bool` | Returns `true` if a user is currently signed in, `false` otherwise. |
| `get_current_user()` | `FirebaseUser` | Returns a `FirebaseUser` for the currently signed-in user, or `null` if no user is signed in. |
| `sign_out()` | `void` | Signs out the current user. Emits `sign_out_success`. |
| `send_password_reset_email(email: String)` | `void` | Sends a password-reset email to the given address. Emits `password_reset_sent`. |
| `send_verification_email()` | `void` | Sends an email-verification message to the current user's email address. Emits `email_verification_sent`. |
| `delete_current_user()` | `void` | Permanently deletes the currently signed-in user's account. Emits `user_deleted`. |

<a name="classes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Classes

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="16"> FirebaseUser
Extends `RefCounted`. Encapsulates the profile data of an authenticated Firebase user. Instances are returned by `FirebaseAuth.get_current_user()` and carried by the `auth_success` and `link_with_google_success` signals.

| Method | Returns | Description |
| :--- | :---: | :--- |
| `get_user_id()` | `String` | The unique Firebase UID for this user. |
| `set_user_id(a_user_id: String)` | `void` | Sets the user's UID. |
| `get_name()` | `String` | The user's display name. |
| `set_name(a_name: String)` | `void` | Sets the user's display name. |
| `get_email()` | `String` | The user's email address. |
| `set_email(a_email: String)` | `void` | Sets the user's email address. |
| `get_photo_url()` | `String` | URL of the user's profile photo. |
| `set_photo_url(a_photo_url: String)` | `void` | Sets the user's profile photo URL. |
| `get_is_email_verified()` | `bool` | Returns `true` if the user's email address has been verified. |
| `set_is_email_verified(a_is_email_verified: bool)` | `void` | Sets the email-verified flag. |
| `get_is_anonymous()` | `bool` | Returns `true` if the user is signed in anonymously. |
| `set_is_anonymous(a_is_anonymous: bool)` | `void` | Sets the anonymous flag. |

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="16"> FirebaseModule
Extends `Node`. Abstract base class for all Firebase feature module nodes (e.g. `FirebaseAuth`). Handles locating and caching the native plugin singleton, and automatically re-acquires it when the app resumes from the background. All module nodes must be direct children of a `Firebase` node — the editor will display a configuration warning if this requirement is not met.

<a name="nodes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Nodes

The plugin exposes its functionality through a tree of custom Godot nodes. Add the `Firebase` root node to your scene and attach only the module child nodes for the Firebase services your project uses.

> **Note:** Additional module nodes (extending `FirebaseModule`) will be added here as support for more Firebase services is introduced.

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="16"> Firebase
**Extends:** `Node`

The root node for the entire plugin. Add this node to your main scene or an autoload scene. It automatically tracks all `FirebaseModule` child nodes as they enter and leave the scene tree, and surfaces editor configuration warnings when the node tree is set up incorrectly.

**Properties:**

| Property | Type | Description |
| :--- | :---: | :--- |
| `auth` | `FirebaseAuth` | Reference to the `FirebaseAuth` child node, or `null` if none is present. Updated automatically as children are added or removed. |

**Configuration warnings (shown in the Godot editor):**
- Shown when no `FirebaseAuth` child node is present (authentication features will be unavailable).
- Shown when more than one `FirebaseAuth` child node is detected (only one is supported at a time).

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="16"> FirebaseAuth
**Extends:** `FirebaseModule` → `Node`

Add this node as a direct child of `Firebase` to enable Firebase Authentication. It bridges GDScript signals and method calls to the underlying native Android/iOS Firebase Auth SDK via the plugin singleton.

**Signals:** see [Signals](#signals) section above.

**Methods:** see [Methods](#methods) section above.

**Scene tree example:**
```
Main (Node)
└── Firebase (Firebase)
    └── FirebaseAuth (FirebaseAuth)
```

<a name="platform-specific-notes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> Platform-Specific Notes

### Android
- Download Android export template and enable gradle build from export settings
- **Troubleshooting:**
- Logs: `adb logcat | grep 'godot'` (Linux), `adb.exe logcat | select-string "godot"` (Windows)
- You may find the following resources helpful:
	- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
	- https://developer.android.com/tools/adb
	- https://developer.android.com/studio/debug
	- https://developer.android.com/courses

### iOS
- Follow instructions on [Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- View XCode logs while running the game for troubleshooting.
- See [Godot iOS Export Troubleshooting](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html#troubleshooting).

<br>

<a name="links"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="24"> Links

- [AssetLib Entry Android](https://godotengine.org/asset-library/asset/9999)
- [AssetLib Entry iOS](https://godotengine.org/asset-library/asset/8888)

<br>

<a name="all-plugins"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="24"> All Plugins

| ✦ | Plugin | Android | iOS | Latest Release | Downloads | Stars |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/godot-sdk-integrations/godot-admob/main/addon/src/main/icon.png" width="20"> | [Admob](https://github.com/godot-sdk-integrations/godot-admob) | ✅ | ✅ | <a href="https://github.com/godot-sdk-integrations/godot-admob/releases"><img src="https://img.shields.io/github/release-date/godot-sdk-integrations/godot-admob?label=%20" /><img src="https://img.shields.io/github/v/release/godot-sdk-integrations/godot-admob?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-sdk-integrations/godot-admob/stargazers"><img src="https://img.shields.io/github/stars/godot-sdk-integrations/godot-admob?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-connection-state/main/addon/src/icon.png" width="20"> | [Connection State](https://github.com/godot-mobile-plugins/godot-connection-state) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-connection-state/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-connection-state?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-connection-state?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-connection-state/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-connection-state?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-deeplink/main/addon/src/icon.png" width="20"> | [Deeplink](https://github.com/godot-mobile-plugins/godot-deeplink) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-deeplink/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-deeplink?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-deeplink?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-deeplink/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-deeplink?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="20"> | [Firebase](https://github.com/godot-mobile-plugins/godot-firebase) | ✅ | ✅ | 🔜 <!-- <a href="https://github.com/godot-mobile-plugins/godot-firebase/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-firebase?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-firebase?label=%20" hspace="4" /></a> --> | - <!-- <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/total?label=total" hspace="4" /></a> --> | <a href="https://github.com/godot-mobile-plugins/godot-firebase/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-firebase?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-inapp-review/main/addon/src/icon.png" width="20"> | [In-App Review](https://github.com/godot-mobile-plugins/godot-inapp-review) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-inapp-review/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-inapp-review?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-inapp-review?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-inapp-review/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-inapp-review?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/main/icon.png" width="20"> | [Native Camera](https://github.com/godot-mobile-plugins/godot-native-camera) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-native-camera/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-native-camera?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-native-camera?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-native-camera/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-native-camera?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> | [Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-notification-scheduler?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-notification-scheduler?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-notification-scheduler?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> | [OAuth 2.0](https://github.com/godot-mobile-plugins/godot-oauth2) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-oauth2/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-oauth2?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-oauth2?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-oauth2/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-oauth2?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-qr/main/addon/src/icon.png" width="20"> | [QR](https://github.com/godot-mobile-plugins/godot-qr) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-qr/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-qr?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-qr?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-qr/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-qr?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-share/main/addon/src/icon.png" width="20"> | [Share](https://github.com/godot-mobile-plugins/godot-share) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-share/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-share?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-share?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-share/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-share?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> | [Vision](https://github.com/godot-mobile-plugins/godot-vision) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-vision/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-vision?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-vision?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-vision/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-vision/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-vision/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-vision?style=plastic&label=%20" /></a> |

<br>

<a name="credits"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="24"> Credits

Developed by [Godot Firebase Team](https://github.com/orgs/godot-mobile-plugins/teams/firebase-team)

Based on [Godot Mobile Plugin Template v7](https://github.com/godot-mobile-plugins/godot-plugin-template/tree/v7)

Original repository: [Godot Firebase Plugin](https://github.com/godot-mobile-plugins/godot-firebase)

<br>

<a name="contributing"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/main/icon.png" width="24"> Contributing

Contributions are welcome. Please see the [contributing guide](https://github.com/godot-mobile-plugins/godot-firebase?tab=contributing-ov-file) in the repository for details.

<br>

# 💖 Support the Project

If this plugin has helped you, consider supporting its development! Every bit of support helps keep the plugin updated and bug-free.

| ✦ | Ways to Help | How to do it |
| :--- | :--- | :--- |
|✨⭐| **Spread the Word** | [Star this repo](https://github.com/godot-mobile-plugins/godot-firebase/stargazers) to help others find it. |
|💡✨| **Give Feedback** | [Open an issue](https://github.com/godot-mobile-plugins/godot-firebase/issues) or [suggest a feature](https://github.com/godot-mobile-plugins/godot-firebase/issues/new). |
|🧩| **Contribute** | [Submit a PR](https://github.com/godot-mobile-plugins/godot-firebase?tab=contributing-ov-file) to help improve the codebase. |
|❤️| **Buy a Coffee** | Support the maintainers on GitHub Sponsors or other platforms. |

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=godot-mobile-plugins/godot-firebase&type=date&theme=dark&legend=top-left)](https://www.star-history.com/?repos=godot-mobile-plugins%2Fgodot-firebase&type=date&theme=dark&legend=top-left)
