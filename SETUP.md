# Auth setup guide

This app authenticates via Supabase, with Email/Password, Google (Android +
iOS), and Apple (iOS only) sign-in. Follow these steps in order.

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in / create an account.
2. Click **New project**. Pick an organization, name (e.g. `lexisnap`), a
   strong database password (save it somewhere safe), and a region close to
   your users.
3. Wait ~2 minutes for provisioning.
4. Go to **Project Settings > API**. Copy:
   - **Project URL**
   - **Publishable key** (this used to be called the "anon" key — some
     older projects still show it under that name; either works)
5. Open `.env` in the project root (copy it from `.env.example` if you
   haven't already) and fill in:
   ```
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```
   `.env` is gitignored — never commit it.

Email/password auth works immediately with no further Supabase config —
Supabase enables the Email provider by default. By default it also requires
email confirmation before a session is issued; you can toggle this under
**Authentication > Sign In / Providers > Email > Confirm email**. The app
already handles both cases (see `signup_controller.dart`).

## 2. Google Sign-In (Android + iOS)

Google Sign-In needs **three** OAuth client IDs in Google Cloud Console: a
Web client (used to verify the ID token, works for both platforms), an
Android client, and an iOS client.

### 2a. Google Cloud Console

1. Go to the [Google Cloud Console](https://console.cloud.google.com/),
   create a project (or reuse one).
2. **APIs & Services > OAuth consent screen**: configure it (app name,
   support email, etc.) and add your test users if the app is in "Testing"
   mode.
3. **APIs & Services > Credentials > Create Credentials > OAuth client ID**,
   create all three of these:

   - **Web application** — name it e.g. "LexiSnap Web (server verification)".
     No redirect URIs are required for this flow. Copy the **Client ID**.
   - **Android** — package name: `com.lexisnap.app`, and the **SHA-1** of
     your signing certificate. For a debug build, get it with:
     ```
     cd android && ./gradlew signingReport
     ```
     Look for the `SHA1` under the `debug` variant. Add a second Android
     client (or a second SHA-1 on the same one) later for your release
     keystore.
   - **iOS** — bundle ID: `com.lexisnap.app`. Copy the **Client ID** — this
     is your iOS client, and note the **iOS URL scheme** shown
     (`com.googleusercontent.apps.…`), you'll need it in step 2c.

4. Put the **Web client ID** and **iOS client ID** into `.env`:
   ```
   GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   GOOGLE_IOS_CLIENT_ID=your-ios-client-id.apps.googleusercontent.com
   ```
   (The Android client is never referenced in code or `.env` — Google Play
   Services validates your app against it automatically using the package
   name + SHA-1 you registered.)

### 2b. Supabase

1. In the Supabase dashboard: **Authentication > Sign In / Providers >
   Google**.
2. Enable it, and paste the **Web client ID** as the "Client ID" and its
   secret as "Client Secret" (found on the Web client's detail page in
   Google Cloud Console).
   - Note: this app signs in using the native Google SDK + `signInWithIdToken`
     (no browser redirect), so the Supabase "Authorized redirect URI" shown
     on this page isn't required for mobile — but enabling the provider
     itself is required for Supabase to accept the Google ID token.

### 2c. Xcode (iOS URL scheme)

Open [ios/Runner/Info.plist](ios/Runner/Info.plist) and replace the
placeholder scheme with the one from your iOS OAuth client (the
`REVERSED_CLIENT_ID`, e.g. `com.googleusercontent.apps.123-abc`):

```xml
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>com.googleusercontent.apps.REPLACE_WITH_YOUR_IOS_CLIENT_ID</string>
		</array>
	</dict>
</array>
```

## 3. Apple Sign-In (iOS only)

### 3a. Apple Developer portal

You need a paid Apple Developer account.

1. **Certificates, Identifiers & Profiles > Identifiers > App IDs**: select
   your app's App ID (matching the iOS bundle ID) and enable the **Sign In
   with Apple** capability. Save.
2. **Identifiers > Services IDs**: create a new Services ID (e.g.
   `com.lexisnap.app.signin`). Enable **Sign In with Apple**, and
   configure it: primary App ID = the one above; add a return URL — for
   Supabase this is:
   ```
   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
   ```
   and a domain of `YOUR_PROJECT_REF.supabase.co`.
   (This is used for Supabase's web/token-exchange verification, not the
   native flow itself, but Supabase requires it to be filled in.)
3. **Keys**: create a new key, enable **Sign In with Apple**, associate it
   with the App ID from step 1. Download the `.p8` key file (you can only
   download it once) and note the **Key ID**.
4. Note your **Team ID** (top right of the Apple Developer portal, or
   **Membership** page).

### 3b. Supabase

1. **Authentication > Sign In / Providers > Apple**.
2. Enable it and fill in:
   - **Services ID** (from step 3a.2) — this is what Supabase calls the
     "Client ID" for Apple.
   - **Team ID**, **Key ID**, and the contents of the `.p8` **private key**
     file (from step 3a.3–4).

### 3c. Xcode

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target > **Signing & Capabilities** > **+
   Capability** > **Sign In with Apple**. Xcode will link the
   `ios/Runner/Runner.entitlements` file already scaffolded in this project
   (it already contains the right entitlement — Xcode just needs to know
   about it via this step) and wire up your provisioning profile.

## 4. App identifier

The app ships with `com.lexisnap.app` as its bundle ID / applicationId
(Android: [android/app/build.gradle.kts](android/app/build.gradle.kts);
iOS: Xcode, Runner target > **General** > **Bundle Identifier**). If you own
a real domain and want to use it instead (e.g. `com.yourcompany.lexisnap`),
change it there before registering the OAuth clients above, since Google/Apple
credentials are tied to the exact identifier.

## 5. Run it

```
flutter pub get
flutter run
```

## Architecture notes (for future changes)

- **Everything auth-related is behind `AuthService`**
  ([lib/app/core/services/auth/auth_service.dart](lib/app/core/services/auth/auth_service.dart)).
  Controllers only ever call `Get.find<AuthService>()` — they never import
  Supabase directly.
- **`SupabaseAuthService`**
  ([lib/app/core/services/auth/supabase_auth_service.dart](lib/app/core/services/auth/supabase_auth_service.dart))
  is the only file that imports `supabase_flutter`, `google_sign_in`, and
  `sign_in_with_apple`. To swap Supabase for another backend later, write a
  new class implementing `AuthService` and change the single `Get.put` call
  in
  [lib/app/core/services/service_locator.dart](lib/app/core/services/service_locator.dart).
  Nothing else in the app needs to change.
- **Reusable UI** lives in
  [lib/app/core/widgets/](lib/app/core/widgets/): `AppButton`,
  `AppTextField`, `SocialSignInButton`, `OrDivider`.
- **MVC/GetX structure**: each screen is a `modules/<name>/` folder with a
  `Controller` (state + logic), `View` (UI, `GetView<Controller>`), and
  `Binding` (DI wiring), registered in
  [lib/app/routes/app_pages.dart](lib/app/routes/app_pages.dart).
  `AuthMiddleware` guards routes based on `AuthService.currentUser`.
