# Testing: Content Ingestion + Local Retrieval

Manual test checklist for the `feature/content-ingestion-retrieval` branch
(PDF/text/photo upload -> local chunking + embeddings -> grounded chat).
This sandbox couldn't build for a real device (no Xcode, incomplete Android
SDK), so run this on your own machine and note anything that breaks.

## 0. Setup

```bash
flutter pub get
flutter devices          # find a target
flutter run -d macos     # or chrome / an android or ios device id
```

## 1. Model download (first run)

`isReady()` now requires **both** the chat model and the new ~25MB embedding
model, so even a device that already had the chat model downloaded will
resume onboarding to fetch the embedding model.

- [ ] Progress screen shows two phases: `Tutor model • X%` then
      `Retrieval model • X%`
- [ ] Download completes and app lands on profile setup / home
- [ ] Re-launching the app afterward skips straight to home (no re-download)

## 2. Ingest a sample chapter

Drawer (☰) -> **Study Materials** -> tap **Load** on "Photosynthesis" or
"Newton's Laws of Motion".

- [ ] "Reading and understanding your chapter…" overlay appears briefly
      (embedding generation) then a new chat opens
- [ ] Violet **"Grounded in ..."** banner shows at the top of chat

Ask a question only answerable from the chapter text, e.g. for Photosynthesis:
- "What are the two main stages of photosynthesis?"
- "What is the overall chemical equation?"

- [ ] Answer reflects the chapter's actual content, not a generic answer
- [ ] An unrelated question (e.g. "what's 12 x 8") still answers normally
      (grounding doesn't break general Q&A)

## 3. Upload your own file

Study Materials -> **Upload a Chapter** -> pick a `.pdf` or `.txt` file.

- [ ] Text extraction succeeds, no crash on a multi-page PDF
- [ ] New chapter appears under "My Chapters" afterward
- [ ] Asking a question grounded in that file's content works

## 4. OCR (Android / iOS only)

Same upload flow, pick a photo of a textbook page (`.jpg`/`.png`).

- [ ] OCR extracts readable text from the photo
- [ ] On desktop/web, image files are **not offered** in the file picker at
      all (extension list should exclude jpg/jpeg/png there)

## 5. Switch / clear chapters

- [ ] Tapping the **x** on the grounding banner mid-chat stops grounding for
      the next question
- [ ] Loading a second chapter, then reopening an earlier session from the
      drawer, restores that session's own banner/chapter correctly
- [ ] Swipe-delete a chapter in Study Materials removes it from the list

## 6. Offline check

Turn off Wi-Fi/data *after* both models and at least one chapter are already
downloaded/ingested, then repeat sections 2-5.

- [ ] Ingestion, chunking, embedding, and retrieval all work with no network
- [ ] No errors or hangs waiting on a network call

## 7. Web fallback

```bash
flutter run -d chrome
```

Web has no local embeddings - retrieval falls back to keyword overlap
scoring, which is less forgiving than semantic search.

- [ ] Load a sample chapter, ask a question using words that literally
      appear in the text
- [ ] Response is the extractive "📖 From Your Loaded Chapter" passage, not
      the generic rule-based fallback

## 8. Known risk areas to watch

- `google_mlkit_text_recognition` is a native Android/iOS plugin - first
  build after adding it can be slow or fail on Gradle/CocoaPods setup issues
  unrelated to this feature's logic.
- The embedding GGUF's pooling behavior (`ContextParams.poolingType =
  LlamaPoolingType.mean`) is analyzer-checked but not run-verified on real
  hardware yet - if retrieval quality on-device seems off (grounded answers
  never match the chapter), check embedding output isn't all-zero/NaN first.
- `lowSpec` tier only has 1024 tokens of context total - if you can test on
  a low-RAM device, confirm a grounded chat with a few turns of history
  doesn't hit a context-overflow error.

## Reporting back

For each failure, note: which section, what you expected vs. what happened,
and the platform/device. That's enough to reproduce and fix from here.
