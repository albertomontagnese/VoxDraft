# VoxDraft

VoxDraft is a native macOS menu bar dictation app. Press **Control + Option + D** in a text field, speak, then press the shortcut again. It transcribes with Apple's Speech framework and inserts the result into the app you were using.

## Features

- Global push-to-toggle shortcut across Mac apps
- Live transcript preview in a non-activating floating panel
- Language selection from the recognizer's supported locales
- Optional on-device-only recognition (where Apple supports it)
- Basic filler-sound removal and punctuation cleanup
- Optional local Hermes 3 cleanup through Ollama
- Local, deletable history of the most recent 100 dictations

## Install

Download `VoxDraft-mac.zip` from the [latest release](https://github.com/albertomontagnese/VoxDraft/releases/latest), unzip it, and move VoxDraft.app to Applications. The app appears as a microphone icon in the menu bar.

The release is ad hoc signed and is not Apple notarized. macOS may require you to open it through Finder's **Open** command the first time. A notarized release requires a Developer ID Application certificate.

## Build and run

Requires macOS 14+ and Xcode. `xcodegen` is needed only if you change `project.yml` and regenerate the checked-in project.

```sh
xcodebuild -project VoxDraft.xcodeproj -scheme VoxDraft -configuration Debug -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
open build/Build/Products/Debug/VoxDraft.app
```

The first dictation prompts for Microphone and Speech Recognition. To insert into another app, grant VoxDraft **Accessibility** in System Settings → Privacy & Security → Accessibility. If access is missing, the transcription is copied to the clipboard instead.

For Hermes cleanup, install Ollama, run `ollama pull hermes3`, and enable Hermes in VoxDraft's settings. Ollama is optional. Dictation works without it.

Dictations are stored locally. See [Privacy](PRIVACY.md) for the speech recognition and Hermes data flows.

## Limits

Apple's Speech framework may use a network service unless **Recognize on this Mac only** is enabled. That setting requires support for the selected language. Long dictations can hit Speech framework duration limits; this first version is best for short messages and paragraphs. Some secure or unusual editors block automated insertion; the result remains in the clipboard and history.
