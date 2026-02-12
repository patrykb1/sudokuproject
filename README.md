# yeah

A new Flutter project.

## Google Sign-In Setup

- The app uses `google_sign_in` for authentication. To enable it for users you must configure OAuth clients in Google Cloud / Firebase for each platform you target:
	- Android: create an OAuth client for Android (package name + SHA-1) and configure the app accordingly.
	- iOS: create an iOS OAuth client and add the required URL types / reversed client ID to `Info.plist`.
	- Web: configure a Web OAuth client and set the client ID in `web/index.html` or use `google_identity_services` as appropriate.

- See the `google_sign_in` package documentation for precise steps and platform-specific manifest/Info.plist changes.

If you want, I can add the exact AndroidManifest/Info.plist snippets and `web/index.html` changes for your project — tell me which platforms you target.
