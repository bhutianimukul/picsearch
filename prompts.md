# prompts.md

A running log of the human-authored prompts that drove SnapVault's build
(AI-assisted, per the round's encouragement to use AI tools). Paired with
`decisions.md`: that file records the *choices*, this one records the *asks*.
As the app's LLM prompt templates are written, they're captured here too.

---

## 2026-07-26 — Round brief & problem selection

Given three open-ended problems (1: learn-a-process-by-watching, 2: conversational
agent, 3: messy documents → structured data). After exploring ideas across all
three, chose **Problem 3**, scoped to: *a phone's screenshot pile is the messy
corpus* → a private, on-device, searchable document wallet.

Platform: native **Android**, APK delivery. Stack: **Flutter**. Processing:
on-device OCR + checksum-verified extraction; optional BYOK Gemini for the fuzzy
tail. (Rationale in `decisions.md` §0–§7.)

---

## 2026-07-26 — SnapVault product spec (canonical)

> **Problem.** A screenshot is a "save it now, deal with it later" reflex —
> recipe, wifi password, tweet, address, error, product. The photo library is a
> visual, chronological pile with zero structure: no text search, no categories,
> no way to ask "what was that pasta recipe?" 800 screenshots become a
> write-only black hole.
>
> **Objective.** Help a user find the exact image they're referring to —
> "my HDFC credit card image", "every photo of this person", etc. Existing tools
> fail because photo apps search by date/location/face, not by the text/meaning
> *inside* a screenshot; note apps require the manual transcription you skipped;
> the info is trapped as pixels, not data.
>
> **Solved =** the pile becomes a structured, searchable library: every
> screenshot OCR'd, classified (recipe / receipt / credential / address /
> quote / error…), key fields extracted, retrievable by meaning.
>
> **Scope (Android app):**
> - [core] Natural-language + voice query ("my HDFC credit card")
> - [core] Suggested questions
> - ★ [core] Extract the *value*, not just the image (card no / account / IFSC /
>   wifi / UPI id) as tap-to-copy fields
> - [core] India-aware taxonomy: Aadhaar / PAN / DL / voter ID / debit-credit
>   card / bank (passbook, cheque, IFSC) / UPI QR / tickets / receipts / social /
>   recipes / other
> - [core] Auto-albums per category
> - [core] Deletable detection (expired tickets, OTP shots, expired offers,
>   memes, blurry)
> - [core] Near-duplicate detection
> - [core] Storage-reclaim estimate
> - ★ [core] Move-to-vault-then-delete (extract → vault → delete raw from camera roll)
> - [core] Safe-delete with trash/undo; never auto-delete sensitive docs unconfirmed
> - ★ [must have] On-device processing only — nothing leaves the phone
> - [core] Biometric lock (whole app, or Cards/IDs only)
> - ★ [core] Auto-masking (•••• 4242 / Aadhaar hidden), reveal on biometric
> - [core] Local encryption of the vault DB
> - [TBD] User provides their Gemini API key
>
> **Standing rules:** log decisions in `decisions.md`; log prompts in
> `prompts.md`; ask clarifications; TDD.
>
> **Done when:** a usable APK testable end-to-end on device, plus a feature-list
> md (how-to-use + end goal).

---

## App LLM prompt templates

_(added as they are written — the classification/extraction prompts sent to the
BYOK model.)_
