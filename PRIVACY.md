# VoxDraft privacy

VoxDraft records microphone audio only while dictation is active. It does not save audio files or send analytics.

Speech recognition uses Apple's Speech framework. If **Recognize on this Mac only** is enabled and supported for the selected language, the recognition request requires on-device processing. Otherwise, Apple may process speech using its network service. Apple's system permission prompt controls access.

Completed text is saved in a JSON file in this Mac's Application Support directory so it can appear in History. History can be deleted from Settings. Text is also placed on the clipboard when VoxDraft uses paste insertion or cannot insert directly.

The optional Hermes setting sends the transcript text to the configured local Ollama endpoint. VoxDraft accepts only localhost HTTP addresses for this endpoint. Hermes is off by default.
