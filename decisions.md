# decisions.md

A running log of the real calls made building **PicSearch**. Format per decision:
what I chose, what I seriously considered, why, and what I deliberately cut.

Newest decisions are appended at the bottom.

---

## 0. What PicSearch is (problem framing)

**The decision:** Interpret "turn messy documents into structured, queryable data"
(Problem 3) as: **your phone's screenshot pile is the messy document corpus.**
People screenshot IDs, cards, UPI QRs, receipts, tickets, wifi passwords — then
never find them again. PicSearch turns that write-only pile into a private,
searchable, structured wallet.

**Alternatives considered:**
- *Invoice/receipt parser* — the default everyone builds; commoditised, and the
  input (clean PDFs) isn't actually messy.
- *Bookmark graveyard* (dedupe + kill dead links) — clean input, so it fails the
  spirit of "messy"; less felt.
- *Generic "upload any PDF and query it" RAG app* — shallow; the hard part
  (retrieval) is a solved library call, so there's no depth to own.

**Reasoning:** Screenshots are genuinely unstructured (pixels, not text), the
data is something the user already owns, and correctness is *checkable* against
the source image — which is exactly where a "messy → structured" project can be
made rigorous instead of vibes. It also has a real, felt user problem.

**Deliberately cut:** Broad "any document type" ingestion. Scope is
screenshots/photos of a fixed, India-relevant taxonomy (see §5). Narrow and deep
beats broad and shallow — the brief says so explicitly.

---

## 1. Delivery: native Android app (APK), not a deployed web URL

**The decision:** Ship a native **Android app**, delivered as a signed release
**APK**, plus a short demo video and a one-shot README.

**Alternatives considered:**
- *Mobile-first web app on a deployed URL* — this is literally what the brief
  asks for ("a URL we can test (deployed)"), and I seriously considered it: a
  browser file-picker opens the gallery, Web Speech gives voice, and it deploys
  to Vercel in one click.

**Reasoning — and the tradeoff I'm accepting, honestly:** The brief asks for a
deployed URL, and a web app would score easier on "setup experience." I'm
*choosing against the grain* because the product is fundamentally about a private,
on-device wallet for your own gallery — Aadhaar, PAN, cards. Doing OCR and
ID-extraction truly on-device (nothing leaves the phone) is only credible as a
native app; a web app either ships images to a server (defeats the privacy
thesis) or fights the browser to do heavy on-device ML. The privacy story *is*
the product, so the platform has to serve it. **Mitigation for the setup-score
risk:** signed APK + a <60s demo video + a README a stranger can follow in one
shot, so "can the evaluator experience it" is still a solid yes.

**Deliberately cut:** iOS. APK-only. iOS sandboxing would also block the deeper
gallery/on-device work, and supporting two platforms in 5 days trades depth for
breadth — the wrong trade for this rubric.

---

## 2. Stack: Flutter over Kotlin/Compose and React Native

**The decision:** **Flutter (Dart).**

**Alternatives considered:**
- *Kotlin + Jetpack Compose* — best-in-class native ML integration and the
  strongest "real Android engineer" signal.
- *React Native (Expo)* — familiar JS/TS.

**Reasoning:** Solo, 5 days, AI-assisted. Flutter maximises velocity (one
language, one codebase, fast to a polished UI — and UX is graded), has
first-class on-device OCR via `google_mlkit_text_recognition`, ships a release
APK with one command, and has unit + widget testing built in (tests are graded).
Kotlin/Compose costs UI-building time I don't have; RN makes on-device OCR
awkward (native modules).

**Deliberately cut:** Nothing yet — this is a pure velocity/fit call.

---

## 3. Processing: on-device OCR + on-device validation, BYOK LLM for the long tail

**The decision:** A layered pipeline:
1. **On-device OCR** (ML Kit) — image → text, locally. Raw images never leave the
   phone.
2. **On-device extraction + validation** for structured IDs — verified by the
   *actual* algorithms (Luhn, Verhoeff, PAN/IFSC regex, UPI-QR decode). Offline,
   no key needed.
3. **BYOK LLM** (user's own key) only for the fuzzy long tail (e.g. "what is this
   screenshot", receipts, free-text search intent) — sending **masked OCR text,
   never the raw image**.

**Alternatives considered:**
- *Raw image → multimodal LLM for everything* — simplest to build; highest
  accuracy. Rejected: it exfiltrates government IDs to a third party and needs the
  network for core function.
- *Everything on-device incl. an on-device LLM (Gemini Nano / MediaPipe)* — most
  private, but heavy and immature for a 5-day build; poor accuracy on open-ended
  classification.
- *Developer-hosted backend with my keys* — I'd pay for usage and have to ship
  secrets; worse setup experience for the evaluator.

**Reasoning:** The sensitive stuff (Aadhaar/PAN/cards) is handled entirely
on-device and offline; the LLM is an optional enhancer, not a dependency, and
only ever sees masked text. BYOK means zero secrets to ship and the evaluator
runs it with a free key in ~2 minutes.

**Deliberately cut:** Sending raw images anywhere. Non-negotiable given the data.

---

## 4. BYOK provider default: Gemini (Google AI Studio)

**The decision:** Default the BYOK provider to **Gemini** (AI Studio key), kept
swappable behind a thin provider interface.

**Alternatives considered:** OpenAI, Anthropic. Both fine; more friction to get a
free key quickly.

**Reasoning:** Generous free tier → evaluators get a working key fast (helps the
setup score), and it's the natural sibling to ML Kit. Key stored in Android
Keystore / EncryptedSharedPreferences, never in plaintext, only ever sent to the
provider directly.

**Deliberately cut:** A provider marketplace / multi-key management. One provider,
one field, swappable in code.

---

## 5. The depth axis: verify, don't guess

**The decision:** The "above and beyond" bet is **extraction that is verified by
real checksums**, plus graceful degradation on messy input, plus an eval harness
that proves accuracy.

- Card number → **Luhn** check
- Aadhaar → **Verhoeff** checksum (Aadhaar's actual algorithm)
- PAN → structural regex (`[A-Z]{5}[0-9]{4}[A-Z]`)
- IFSC → structural regex (`[A-Z]{4}0[A-Z0-9]{6}`)
- UPI QR → decode the `upi://` payload for payee + VPA

**Reasoning:** Most submissions will classify by "does this text look like an
Aadhaar?" and stop — which fails on the messy, partial, ambiguous inputs the brief
keeps stressing. Verifying with the real checksums (a) kills false positives and
(b) is trivially unit-testable with known valid/invalid values. One choice that
scores on *tests*, *real-world handling*, and *above-and-beyond* at once.

**Deliberately cut (taxonomy scope):** Fixed set — Aadhaar, PAN, debit/credit
card, bank (IFSC/account), UPI QR, receipt, ticket, wifi/credential, other.
Everything else falls to "other" rather than being guessed wrong.

---

## 6. Not building (for now), and why

- **Background auto-ingest** of new screenshots — cool, but a foreground
  "scan my gallery" flow proves the thesis without the battery/permission
  complexity.
- **Expiry reminders / notifications** — depends on reliable extraction first;
  ordering matters.
- **KYC autofill, cloud sync, multi-user** — out of scope for a single-user,
  on-device, 5-day build. Each would trade depth for surface area.

---

## 7. LLM model: Gemini Flash tier (default), swappable

**The decision:** Default the BYOK model to the **Gemini Flash tier**
(`gemini-2.5-flash`), held in a single config constant with a settings override.

**Alternatives considered:**
- *Gemini Pro tier* — stronger reasoning, but slower, burns the free quota
  faster, and the accuracy gain is marginal on this task.
- *On-device LLM* — already rejected in §3 (heavy, immature for 5 days).

**Reasoning:** The LLM only ever sees **short, masked OCR text** for the fuzzy
long tail (open-ended "what is this", receipts, search intent). That's a light
classify/extract job where Flash is fast, cheap, and — critically for BYOK — has
the friendliest free tier, so an evaluator's free key survives a full demo. Pro
buys little here and costs latency + quota. One constant → swapping to a newer
Flash model or another provider is a one-line change.

**Deliberately cut:** Multi-model routing / auto-escalating to Pro on low
confidence. Nice, but premature — ship one good default first.

---

## 8. Person / face search — deferred (TBD), not in the MVP

**The decision:** Keep "find every photo of a person" **out of the MVP**; revisit
once the screenshot core works.

**Alternatives considered:** Build it now with an on-device face-embedding model
(TFLite) + identity clustering.

**Reasoning:** It silently changes the app from a *screenshot wallet* into
*whole-gallery photo search*, and needs a separate engine — ML Kit *detects*
faces but doesn't *identify* them, so it's a new model + clustering (~1–1.5 of 5
days). Screenshots (the actual problem) rarely contain the faces you'd search
for. Depth-over-breadth: finish the checksum-verified screenshot core first. Kept
**TBD, not killed** — the architecture (per-image records + a pluggable signal
extractor) leaves room to add a face-embedding signal later.

**Deliberately cut for now:** Face recognition; whole-gallery (non-screenshot)
ingestion.

---

## 9. On-device by default; Gemini strictly opt-in (resolving the must-have conflict)

**The decision:** Default is **100% on-device** — checksum extraction now, plus
keyword + structured-field search (on-device text embeddings as a later
enhancement). Gemini BYOK is **opt-in, OFF by default**; enabling it shows an
explicit *"masked text will leave your device and go to Google"* consent notice.

**Alternatives considered:** (a) drop Gemini entirely for an absolute promise;
(b) Gemini on by default for best accuracy.

**Reasoning:** "On-device only" (a stated must-have) and "uses a cloud LLM" can't
both be unqualified-true. Private-by-default with explicit consent keeps the
headline literally true for the default user, while still offering an accuracy
booster on the fuzzy long tail to anyone who opts in. Noticing and resolving that
contradiction deliberately is itself the product call — not a detail to paper over.

**Deliberately cut:** Gemini-on-by-default; any silent network use.

**Update (clarified with user):** The promise is narrowed to **"images never
leave the phone"** (not "nothing leaves"). Text-based querying/classification via
the user's own Gemini key is **acceptable** — only OCR'd text is sent, images
stay local, and full card/Aadhaar/PAN numbers are masked before sending. No key
→ fully on-device keyword + structured-field search. This anchors the guarantee
where users actually care (the image of the document), while letting text power
natural-language search. Gemini is therefore a first-class (BYOK-gated) part of
querying, not an off-by-default afterthought.

---

## 10. Renamed: SnapVault → PicSearch

**The decision:** Renamed the product to **PicSearch**.

**Reasoning:** "PicSearch" names the actual job — *find the screenshot you mean* —
better than the vault metaphor. Privacy/vault stays a core feature, not the name;
and the search-first framing matches the new home design (ask/voice-first).

**What changed:** app display name (`android:label`) and the Dart package
(`snapvault` → `picsearch`, all imports updated, 37 tests still green).

**Kept for now (cosmetic, not user-visible):** the Android `applicationId`
(`com.mukul.snapvault`) and the repo folder name — will align when the public
repo is created (Ship task). Not worth the churn mid-build.

---

## 11. UI direction: minimal, ask-first, motion-led (CRED-inspired)

**The decision:** Home is a near-empty, ask-first screen — search + voice docked
low over ambient motion (drifting aurora, screenshots orbiting a vault mark). The
category/album grid moved off the home into a **Vault tab**. An animated splash
performs the pitch (scan → tag → sort → seal). Near-monochrome on true-black with
**one vivid gradient accent** (Iris default; Lime/Aqua alternates) and glow for
depth.

**Alternatives considered & rejected along the way:** a dense home with album grid
+ chips + banner (too cluttered); an 8-colour category palette (read as noisy /
"AI-built"); flat monochrome brass (read as dull — fixed with luminosity depth,
not more hues).

**Reasoning:** Each screen gets one job — home *asks*, Vault *browses* — so
"minimal" reads as intentional, not empty. Motion carries the personality (and the
splash front-loads comprehension) so the layout can stay sparse. One saturated
accent over depth = premium energy without clutter.

**Deliberately cut:** Multi-hue category coding *on whole cards*.

**Locked with user:** Home **A** (ask-first), **Iris** accent, and **both light +
dark** themes via an in-app toggle (dark is the default / hero). Colours moved
into a `PicColors` theme extension so the swap is clean rather than find-and-replace.

**Refinement (user: "make the icons colourful"):** each category gets a distinct
muted hue, applied *only to the type icon* (glyph + subtle tint) — card surfaces
and borders stay monochrome. Earlier full-colour cards read as cluttered; pure
monochrome read as dull. Colour on the icon alone is a glanceable category cue —
signal, not decoration.

**Verified end-to-end on an Android emulator:** pick 4 screenshots → on-device
ML Kit OCR → detect/verify → classify → sort. The card was read, **Luhn-verified**
(badge shown), and masked to `••••6467`; PAN / wifi / receipt each categorised
correctly. The whole pipeline runs on-device, no network.

---

## 12. Persistence: encrypted local vault

**The decision:** Serialize records to JSON, **AES-256 encrypt** them with a key
held in the **Android Keystore** (`flutter_secure_storage`), and write the
ciphertext to app-private storage. Loaded on startup, saved after each scan.

**Alternatives considered:**
- *Plaintext JSON file* — simplest, rejected: it would store full card/Aadhaar
  numbers in the clear, against the whole privacy thesis.
- *SQLite / Hive / Isar* — a DB engine is overkill for a flat, append-mostly
  record list; more deps and setup for no query benefit we need yet.
- *Store the whole blob in flutter_secure_storage* — it's for small secrets, not
  a growing JSON blob; so it holds only the 32-byte key.

**Reasoning:** Encryption at rest matches the product's promise for the sensitive
extracted values. Splitting the work — a **pure `VaultCodec`** (serialize +
AES) plus a thin device-only `VaultStore` (Keystore + file) — means the
encrypt/decrypt round-trip is **unit-tested without a device** (and a test
asserts the plaintext card number is absent from the ciphertext).

**Deliberately cut:** Cloud sync; per-record encryption; a DB engine. CBC gives
confidentiality (the threat is another app / file access); GCM is the noted
hardening upgrade if tamper-detection is wanted.

---

## 13. Eval harness: proving "verify, don't guess" (the depth axis)

**The decision:** A hand-labelled set (18 messy samples, incl. adversarial
negatives) + a scorer that runs the *real* pipeline (`analyzeText`) and reports
classification accuracy + extraction precision/recall. Wired both as a **test
(quality gate)** and a `dart run tool/eval.dart` **report** for the README.

**Result on this set:** 100% classification (18/18), **100% extraction precision
(0 false positives)**, 100% recall. The negatives — tampered card, bad-checksum
Aadhaar, malformed PAN, a phone number, a non-Luhn 16-digit string — are all
correctly rejected.

**Reasoning:** This is the above-and-beyond move — it turns "seems to work" into a
number, and specifically demonstrates the checksum design's payoff: **zero false
positives by construction.** Framed honestly as a curated *logic-correctness* set
(real-world OCR accuracy would be lower); the claim is that the extraction logic
is correct and false-positive-free, which is exactly what the checksums buy.

**Deliberately cut:** A large real-OCR corpus — would need real labelled
screenshots (PII), out of scope for a 5-day build.

---

## 14. Ship polish: custom icon + finished the PicSearch rename

**The decision:** Gave the app a real launcher icon and finished aligning every
`snapvault` leftover to `picsearch` (closing the loose end flagged in §10).

**Icon:** An Iris-gradient magnifying glass on the app's dark ground — search is
the product's verb, and it reads more clearly at 48px than the in-app lock motif
(privacy is carried elsewhere). The 1024px source + adaptive foreground are
generated by a stdlib-only (`zlib`) PNG encoder — no image-library dependency for
two one-off assets — then `flutter_launcher_icons` emits the densities and the
Android adaptive icon.

**Rename:** `applicationId`/`namespace` `com.mukul.snapvault → com.mukul.picsearch`,
the Kotlin package moved to match, and the repo folder `snapvault → picsearch`.
The Dart package and `android:label` were already PicSearch (§10). New
`applicationId` = fresh install identity, which is fine pre-launch.

---

## 15. UI audit pass: type identity + honest actions

**The decision:** A design-audit sweep against the "Gen-Z / minimal" bar. The
system was already disciplined (one accent, monochrome surfaces, colour
quarantined to small chips); these were the refinements that moved it from
"clean" to "considered".

**Typography:** Bundled **Sora** (variable, OFL) as the app face. The whole UI
was stock Roboto — the single biggest "default" tell. Sora is a geometric
grotesk originally commissioned for a fintech identity, so it fits a private
money-vault; monospace stays for extracted values (the data/prose contrast is
deliberate).

**Brand identity:** Unified on **search**, not the padlock. The launcher icon is
a magnifying glass, so the home hero became one too; the decorative Vault
app-bar lock was dropped. The padlock now appears only where it's *functional*
(reveal gates, blurred preview) — not as decoration.

**Honesty fixes:** The "Move to Vault & delete original" button was a no-op
whose label also over-promised (the app deliberately never touches the gallery
original). Wired it to `removeRecords` and relabelled **"Remove from
PicSearch."** Greeting is now time-aware instead of hardcoded "Good evening".

**Consistency:** One `categoryChip()` helper now backs every list row (Vault,
search, cleanup) so they share a single icon language.

---

## 16. Live E2E test surfaced real bugs — and shipped AI grouping

Testing with a real Gemini key on the emulator (dummy card/PAN/Aadhaar/UPI/OTP
images pushed to the gallery) turned up four things:

**Corrupted Verhoeff table (Aadhaar checksum).** `_p` row 2 was
`[5,8,0,3,7,9,6,1,4,2]` — indices 3–7 scrambled vs. the canonical
`[5,8,0,9,1,6,7,3,4,2]`. It hid because our tests build the "valid" Aadhaar with
our *own* `verhoeffCheckDigit`, so the wrong table stayed self-consistent (and a
genuinely-valid Aadhaar was silently rejected). Fixed the row and added a guard
test with an external anchor (`verhoeffCheckDigit('236') == 6`,
`isValidVerhoeff('2366')`) that a self-consistent corruption can't pass.

**Deprecated Gemini model.** Default was `gemini-2.5-flash`, which 404s for new
API keys ("no longer available to new users"). Switched to the rolling
`gemini-flash-latest` alias so it never deprecates from under a user again.

**No key verification.** Settings stored any pasted string and said "saved". Now
`GeminiClient.verifyKey()` does a tiny live request on Save — bad keys fail at
entry, not at the first question. Settings also names the key source + model.

**UPI missed without the scheme.** Detection required `upi://`; OCR often drops
it. Added a bare-VPA fallback (`name@bank`), excluding emails by the no-TLD rule.

**AI-based grouping (new feature, user request).** When a Gemini key is set, the
Vault replaces the hard-coded type categories with AI-named smart folders. Only
redacted text is sent (never images, never full numbers) — a `groupRecords` call
returns one folder label per record, stored on the record (`aiGroup`), cached,
and recomputed automatically after each scan or when a key is added. Falls back
to the on-device type grouping when no key is set.

**AI cleanup (same pass).** The one `analyzeRecords` call also flags each item as
clearable junk or not, with a short reason (`aiClearable`/`aiClearReason`) — so
when a key is on, the "you can clear" list is AI-judged (safe defaults: never
IDs/cards/passwords/receipts) instead of the hard-coded OTP+duplicate heuristic.
One call does both grouping and cleanup, kept cheap.

---

## 17. Ship: a real signed release APK

**The decision:** Generated a proper RSA release keystore and wired
`android/app/build.gradle.kts` to sign release builds from a git-ignored
`android/key.properties` (falls back to debug keys if it's absent, so the build
never breaks for someone without the secret). The APK verifies under a real
`CN=PicSearch` cert, not the shared Android debug key.

**Disabled R8 minify for release.** ML Kit's R8 pass references optional
recognizers (Chinese, Devanagari, …) we don't bundle, which fails the build.
A sideloaded demo APK gains nothing from obfuscation, so minify is off (the
upgrade path — add the generated keep rules — is noted in the gradle file). Cost:
a fat ~89 MB APK (the on-device OCR models dominate anyway).

---

## 18. Pluggable AI engine: cloud Gemini ↔ on-device Gemma

**The decision:** Made the AI a pluggable `AiEngine` (`lib/src/ai_engine.dart`)
with two implementations — `GeminiEngine` (cloud, BYOK) and `LocalGemmaEngine`
(on-device Gemma via MediaPipe / `flutter_gemma`) — so users can run search,
smart folders and cleanup **with no key and no network at all**. Settings gains a
"Download Gemma" flow + a Cloud/On-device switch. The prompt-building and JSON
parsing were extracted into engine-agnostic helpers (`buildAnalyzePrompt`,
`parseAnalyze`, `firstJsonObject`) shared by both; the parser is lenient because
local models don't guarantee clean JSON.

**Why on-device, not a cloud vision LLM:** a cloud vision LLM was considered and
rejected — it would upload the actual images (breaking the core promise) and
*guess* digits instead of checksum-verifying them. The privacy-preserving way to
add vision is the on-device path (Gemma is multimodal), which never sends a pixel.

**Verification honesty:** analyze clean, 62 tests, and both APKs *build* with the
MediaPipe native dependency — but Gemma **inference can't run on the emulator**
(needs a real phone + a downloaded model). Built on `feature/local-model`, then —
per the user's call — merged via **PR #1** and shipped in **v1.1.0**. On-device
inference is a device-only test; the cloud path works everywhere.

---

## 19. On-device model access: an HF token, not a file picker

**The decision:** The default Gemma `.task` is gated on Hugging Face, so the
in-app download 401s without auth. Instead of a "download in the browser, then
load the file" flow, Settings takes a **Hugging Face token** (with a link to the
model page to accept the licence) and passes it to the existing download. Shipped
in v1.1.1.

**Why not `file_picker`:** it was tried first. Its build-compatible versions either
use the removed `jcenter()` (ancient releases) or demand a newer `compileSdk` than
the project targets — I wasn't going to destabilise a shipped build for a second
download path when a token is dependency-free and fixes the same gating.
(`AppState.loadLocalModelFile` stays, ready for a picker later.)

---

## 20. Read the QR, not just the text — on-device barcode decoding

**The decision:** `MlKitOcrService` now also runs **ML Kit Barcode Scanning** and
appends any decoded payload (e.g. a UPI QR's `upi://pay?pa=…&pn=…&am=…`) to the OCR
text. The pure `analyzeText` pipeline then extracts it with no idea barcodes exist
— so a UPI QR is read even when nothing is printed, and the whole transform stays
unit-testable (the fake `OcrService` just returns text). Shipped in v1.1.2.

**Payee name.** `analyzeText` adds a **"Payee name"** field for UPI: the `pn=`
param (url-decoded, deterministic) if present, else a Title-Case name line adjacent
to the VPA (a heuristic, for screenshots that print only the handle). It's a
`DocType.unknown` field, so the eval is untouched (still 100%). Verified on-device
— the UPI record shows UPI ID + Payee name.

**Why decode the QR at all** (vs. the earlier text-only reading): OCR misreads the
`upi://` glyphs and can't see data that's *only* inside the QR pixels. Decoding the
barcode is the reliable source — and it feeds the exact same parser + name
extraction, so it was additive, not a rewrite.
