# Pocket Tutor — Offline AI-Powered Mobile Learning Assistant
### PRD (Hackathon Build) — PS 10

---

## 1. Problem statement
Students in areas with limited or no internet access can't use AI tutoring tools, since almost all of them require a live connection to a cloud LLM. There is no reliable way for these students to get personalized explanations, Q&A, summaries, and quizzes from their own study material without connectivity.

## 2. Solution
**Pocket Tutor** is a Flutter app that runs an AI model **entirely on-device**. A student loads a chapter (PDF/text) once, and from then on — with zero internet — the app can explain concepts, answer questions, summarize, generate quizzes, and manage spaced-repetition revision.

## 3. Target user
School/college students with intermittent or no internet access; also useful for exam revision on the go (flights, rural areas, low-data plans).

## 4. Core value proposition
"Your tutor lives on your phone, not in the cloud."
Real, verifiable offline AI — not a cached-response gimmick — is the differentiator.

## 5. MVP feature set

| # | Feature | Description |
|---|---------|-------------|
| 1 | Content ingestion | User picks a PDF/text file, or selects a pre-bundled sample chapter. Text is extracted and chunked locally. |
| 2 | On-device LLM | A quantized small model (Gemma 2B or similar) runs locally via `flutter_gemma`. All inference happens on-device after initial setup. |
| 3 | Ask & Explain | Chat-style Q&A grounded in the loaded content — relevant chunks are retrieved locally and fed to the model with the question. |
| 4 | Summarize | One-tap summary of a chapter/section. |
| 5 | Auto-quiz | Generates 5 MCQs from the loaded content; scores the user and shows correct answers. |
| 6 | Revision mode | Missed quiz questions resurface later using a simple spaced-repetition queue, stored locally. |
| 7 | Offline indicator | Visible "Offline ✓" badge so the demo proves there's no hidden network call. |

## 6. Stretch goals (only if ahead of schedule)
- Voice input/output (STT/TTS)
- Multi-language support
- Progress dashboard / streaks
- Multiple pre-bundled subjects

## 7. Non-functional requirements
- Model load time under 10 seconds on a mid-range device
- Model size ≤ 2B parameters, quantized (int4/int8)
- App must function fully with Wi-Fi and mobile data OFF
- Graceful loading state while the model initializes

## 8. Architecture

**Layers (device-only, no backend):**
1. **Presentation layer** — Flutter UI: upload, chat/Q&A, summary, quiz, revision screens
2. **Core services** — content chunking & retrieval, prompt builder (explain/summarize/quiz-gen), spaced-repetition scheduler
3. **Data/AI layer** — on-device LLM (quantized Gemma via `flutter_gemma`, MediaPipe LLM inference, no network calls) + local storage (Hive/Isar/SQLite) for notes, quiz history, and the revision queue

*(See architecture diagram shared above — same structure, in visual form.)*

## 9. Tech stack
- **Flutter** — UI, state management (Riverpod/Provider)
- **flutter_gemma** — on-device LLM inference (MediaPipe + Gemma)
- **Hive / Isar** — local storage
- **syncfusion_flutter_pdf** or `pdf_text` — PDF text extraction
- Simple keyword/embedding-based local retrieval (no vector DB needed for MVP)

## 10. Team split (4 people)
| Role | Owner | Responsibilities |
|------|-------|------------------|
| AI/Model integration | P1 | flutter_gemma setup, prompt engineering, latency tuning |
| Content pipeline | P2 | PDF/text ingestion, chunking, retrieval logic |
| UI/UX | P3 | All screens, navigation, visual polish |
| Storage & integration | P4 | Local DB, spaced repetition, wiring everything together, offline testing, demo prep |

## 11. Timeline (48 hours)
| Hours | Milestone |
|-------|-----------|
| 0–4 | Confirm flutter_gemma runs offline on a real device (highest-risk item, done first) |
| 4–16 | End-to-end basic Q&A working (UI can be rough) |
| 16–30 | Add summarize, quiz generation, revision queue |
| 30–40 | Full UI/UX pass, error handling |
| 40–46 | Polish, pre-load 2 demo chapters, rehearse in airplane mode |
| 46–48 | Buffer + pitch deck |

## 12. Demo plan
1. Show app with Wi-Fi/data already off
2. Load a pre-bundled chapter
3. Ask a question → get an explained answer, live, offline
4. Tap Summarize → instant summary
5. Take the auto-generated quiz → get scored
6. Show a missed question resurfacing in the revision queue

## 13. Why this wins
- Solves the actual PS (offline-first), not a cloud app with a "works offline" claim
- Live, verifiable demo (airplane mode on stage)
- Covers every required feature: explanations, Q&A, summaries, quizzes, revision
- Realistic 48-hour scope with clear risk de-risked in hour 1
