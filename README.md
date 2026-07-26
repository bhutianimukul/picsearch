# PicSearch

**Turn your screenshot pile into a private, searchable vault — entirely on-device.**

You screenshot a card, a wifi password, an Aadhaar, a receipt… then never find
it again. PicSearch reads every screenshot on your phone, works out *what it is*,
pulls out the useful bits, and makes them searchable — without a single image
ever leaving the device.

> Engineering-round submission. Problem 3 — *turn messy documents into
> structured, queryable data* — interpreted as: **your screenshot gallery is the
> messy corpus.** Full reasoning in [`decisions.md`](decisions.md); the prompts
> that drove the build are in [`prompts.md`](prompts.md).

---

## What it does

- **Scan** your gallery → each screenshot is OCR'd **on-device** (ML Kit).
- **Classify** into an India-aware taxonomy: Cards, Aadhaar, PAN, Bank/IFSC,
  UPI QR, Wifi & codes, Receipts, Tickets, Recipes, OTPs, Other.
- **Extract & verify** the values — a card only files as a card if it passes the
  **Luhn** checksum; an Aadhaar only if it passes **Verhoeff**; PAN/IFSC by
  structural format; UPI by decoding the `upi://` payload.
- **Vault** — auto-albums by category, sensitive values **masked** (`••••6467`)
  and revealed only on tap, one-tap **copy**.
- **Search** — ask in your words ("my hdfc card", "airbnb wifi"); on-device,
  with suggested questions.
- **Private by default** — encrypted at rest; optional **bring-your-own Gemini
  key** for natural-language questions sends *masked text only*, never images.

---

## How it works

```
 screenshot ──▶ on-device OCR ──▶ detect + VERIFY ──▶ classify ──▶ encrypted vault ──▶ search
   (pixels)      (ML Kit)          Luhn / Verhoeff       category      AES-256           keyword +
                                   PAN / IFSC / UPI      + fields      (Keystore key)     fields
```

The design is layered so the hard logic is provable without a device:

| Layer | Files | Depends on |
|---|---|---|
| **Pure core** (messy→structured) | `lib/src/validators.dart`, `analyzer.dart`, `classifier.dart`, `masking.dart`, `search.dart`, `vault_codec.dart` | nothing — plain Dart, unit-tested |
| **Device services** | `ocr_mlkit.dart` (ML Kit), `vault_store.dart` (Keystore + file) | platform plugins |
| **UI** | `lib/ui/*`, `lib/theme.dart` | Flutter |

The entire "messy → structured" transform is pure and synchronous, so it runs
under `dart test` in milliseconds with no OCR, UI, or network.

---

## The hard part we went deep on — *verify, don't guess*

Most extractors classify by "does this text *look* like an Aadhaar?" and stop —
which produces false positives on the messy, partial, ambiguous input the brief
stresses. PicSearch instead **verifies with the real algorithms** (Luhn's
checksum, Aadhaar's Verhoeff checksum, PAN/IFSC structure). A running eval proves
the payoff:

```
$ dart run tool/eval.dart
┌─ PicSearch · extraction & classification eval ───────────
│ Samples                 : 18
│ Classification accuracy : 100.0%  (18/18)
│ Extraction precision    : 100.0%  (TP=10, FP=0)
│ Extraction recall       : 100.0%  (FN=0)
└──────────────────────────────────────────────────────────
```

The 18 samples include **adversarial negatives** — a tampered card, a
bad-checksum Aadhaar, a malformed PAN, a phone number, a non-Luhn 16-digit
string — all correctly **rejected**. Zero false positives, by construction.
(This is a curated logic-correctness set; real-world OCR accuracy would be lower.)

---

## Privacy

- **Images never leave the phone.** OCR + ID extraction run entirely on-device.
- **Encrypted at rest.** Records are AES-256 encrypted with a key held in the
  Android Keystore; only the ciphertext hits app-private storage.
- **Gemini is opt-in.** With no key, everything is on-device. If you add a key,
  only *masked* OCR text is sent (full card/Aadhaar numbers are stripped first) —
  never images.

---

## Setup & run

**Prerequisites:** Flutter (stable) and the Android SDK (`flutter doctor` should
show the Android toolchain ✓).

```bash
flutter pub get
flutter test                  # 46 tests
dart run tool/eval.dart       # prints the accuracy report

# run on a connected device / emulator:
flutter run

# or build the installable APK:
flutter build apk --release   # → build/app/outputs/flutter-apk/app-release.apk
```

Install the APK on any Android phone (`adb install app-release.apk`, or copy it
across). Open **PicSearch → Scan**, pick some screenshots, and they'll sort into
the Vault.

---

## Tests

- `flutter test` — 46 tests: checksum validators (Luhn/Verhoeff/PAN/IFSC/UPI),
  masking, classification, the scan pipeline, encryption round-trip, the search
  ranker, a `MaskedField` widget test, and the eval gate.
- `dart run tool/eval.dart` — the accuracy report above.

---

## Project layout

```
lib/
  src/         pure core: validators, analyzer, classifier, masking, search,
               models, vault_codec, ocr_service (+ ml kit impl), scan_pipeline
  state/       AppState (records, scan, persistence) + AppScope
  ui/          splash, home, vault, record detail, search, settings, theme
eval/          labelled samples + scorer for the accuracy report
tool/eval.dart runnable eval report
test/          unit + widget + eval tests
decisions.md   every real call, with alternatives and trade-offs
prompts.md     the human prompts that drove the build
```

See **[`FEATURES.md`](FEATURES.md)** for the full feature list, a how-to-use
walkthrough, and the end goal.

---

*Note: the Flutter package / repo folder is `snapvault` (the project's original
name); the product was renamed to **PicSearch** — see `decisions.md` §10. The
Android application id is `com.mukul.snapvault`.*
