# VoxDraft Mac App Store submission

The App Store build uses `VoxDraftAppStore.entitlements` and the `APP_STORE` compilation condition. It is separate from the Developer ID release on GitHub. App Sandbox forbids the assistive Accessibility APIs used by the direct build, so the App Store build copies the transcript to the pasteboard and asks for Core Graphics event-posting consent to paste into the target app. If consent is denied, the text remains on the pasteboard and in local history.

## Store information

- App name: VoxDraft AI Dictation
- App Store Connect app ID: `6822166099`
- Platform: macOS
- Bundle ID: `com.albertomontagnese.VoxDraft`
- SKU: `voxdraft-macos-001`
- Primary language: English (U.S.)
- Category: Productivity
- Price: Free
- Version: 1.0
- Subtitle: Dictation anywhere on your Mac
- Promotional text: Speak into any text field with a keyboard shortcut. Review, tidy, and reuse your words from the menu bar.
- Keywords: dictation,speech to text,voice typing,transcription,writing
- Support URL: https://github.com/albertomontagnese/VoxDraft/issues
- Privacy policy URL: https://github.com/albertomontagnese/VoxDraft/blob/main/PRIVACY.md
- Required Mac screenshot: `assets/app-store/voxdraft-settings-2560x1600.png`

## Description

VoxDraft turns short spoken thoughts into text wherever you write on your Mac. Press Control + Option + D to start speaking, then press the shortcut again to finish and insert your words.

See a live transcript while you speak. Choose a recognition language, remove filler sounds and tidy punctuation, then revisit recent dictations in local history. Where supported, you can require on-device recognition. You can optionally polish a transcript with a local Hermes model through Ollama; this feature is off by default and Ollama is installed separately.

VoxDraft needs microphone and Speech Recognition permission. Automatic insertion asks for permission to post a paste command to another app; if unavailable, your transcript is ready on the clipboard. History is stored on your Mac and can be deleted in Settings. No account is required.

Apple's Speech framework may use Apple's speech service unless on-device recognition is selected and available for the chosen language. VoxDraft does not save audio recordings or send analytics.

## App Review notes

No account or purchase is needed. Launch VoxDraft to find its microphone icon in the menu bar. Open TextEdit and focus a document. Press Control + Option + D, speak a short sentence, and press the shortcut again. Allow Microphone and Speech Recognition when prompted. To test automatic insertion, allow the event-posting request in System Settings → Privacy & Security → Accessibility. If that permission is not granted, the transcript is copied to the clipboard and saved in History.

The optional Hermes feature requires a separately installed local Ollama service. It is not required to test dictation. The “Recognize on this Mac only” option requires a language supported by Apple's on-device recognizer.

## Privacy and export declarations

The developer does not collect app data. Completed text and history stay on the user's Mac, except that Apple's Speech framework may process speech through Apple's service and the user may explicitly enable an on-device Ollama endpoint. Apple states that developers do not need to disclose data collected by Apple in the App Privacy label. VoxDraft includes no third-party SDK or analytics.

The app uses no custom cryptography; `ITSAppUsesNonExemptEncryption` is false. The only network calls in app code are URLSession calls to a user-selected local Ollama endpoint. Speech framework networking is managed by Apple.

## Build

Set `APP_STORE_TEAM_ID`, `ASC_PRIVATE_KEY`, `ASC_KEY_ID`, and `ASC_ISSUER_ID`, then run `tools/package-appstore.sh`. It creates an App Store Connect installer package under `build-appstore/<timestamp>/export/VoxDraft.pkg` using automatic distribution signing.

The 1.0 (5) package was validated and uploaded to App Store Connect on October 13, 2026 with zero warnings. Delivery UUID: `18134884-34f0-4e35-8c85-f1673692d728`.
