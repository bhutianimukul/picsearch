# PicSearch — Features & How to use

## End goal

Make the one thing your phone is worst at — **finding the screenshot you
half-remember** — instant, private, and structured. You should be able to open
PicSearch and, in one gesture, ask *"my HDFC card"* or *"the airbnb wifi"* and
get the exact value, extracted and ready to copy — knowing that none of your
screenshots ever left the device.

---

## Features

### Built & working
- ✅ **On-device OCR** of picked screenshots (Google ML Kit) — no network.
- ✅ **India-aware classification** — Cards, Aadhaar, PAN, Bank/IFSC, UPI QR,
  Wifi & codes, Receipts, Tickets, Recipes, OTPs, Other.
- ✅ **Checksum-verified extraction** — Luhn (cards), Verhoeff (Aadhaar),
  PAN/IFSC format, UPI VPA decode. Verified, not guessed → **zero false
  positives** (see the eval in the README).
- ✅ **Vault** with auto-albums, **colour-coded type icons**, per-category drill-in.
- ✅ **Masking + reveal** — card/Aadhaar/PAN shown as `••••6467`, revealed on tap;
  a "Verified" badge when the checksum passes.
- ✅ **Tap-to-copy** the extracted value.
- ✅ **Search** — natural-language-ish query over category + fields + OCR text,
  with suggested questions; field matches rank above loose text mentions.
- ✅ **Encrypted persistence** — records survive restart, AES-256 with a
  Keystore-held key; the raw card number is never present in the stored bytes.
- ✅ **Light / dark theme** toggle (dark "Vault" is the default).
- ✅ **Animated splash** that performs the pitch: scan → tag → sort → seal.
- ✅ **Settings** — privacy statement + a bring-your-own **Gemini** key field.

### Deliberately out of scope for this build (see decisions.md)
- ⏸ **Gemini natural-language answers** — the key field + consent copy are in;
  wiring the live call is a documented next step (opt-in, masked-text-only).
- ⏸ **Biometric-gated reveal** — reveal works; gating it behind fingerprint is next.
- ⏸ **Cleanup actions** (dedup / deletable / move-to-vault-then-delete) — the
  detail screen has the *Move to Vault & delete original* affordance; the actual
  OS gallery delete (permission-gated) is deferred.
- ⏸ **iOS**, background auto-ingest, cloud sync — out of scope for a 5-day,
  single-platform, privacy-first build.

---

## How to use

1. **Install & open.** Install the APK (`adb install app-release.apk`) and open
   **PicSearch**. You'll see the animated splash, then the ask-first home.
2. **Scan.** Tap **Scan** in the bottom bar → the system photo picker opens →
   select some screenshots → **Add**. They're read on-device and sorted; you land
   in the **Vault** with a "Sorted N screenshots" confirmation.
3. **Browse.** In the **Vault**, tap a category (e.g. *Cards*) → tap a record to
   open its detail. Sensitive numbers are masked; tap the **lock** to reveal, tap
   **copy** to grab the value. A **Verified** badge means the checksum passed.
4. **Search.** From **Home**, tap the search bar (or a suggested chip) and type
   *"hdfc card"*, *"airbnb wifi"*, *"pan"*… results rank verified fields first.
5. **Theme & privacy.** **Settings** → toggle **Dark theme**; read the privacy
   statement; optionally paste a **Gemini** API key (kept in the Keystore) for
   future natural-language questions.

> **Try it fast:** if your gallery is empty (e.g. a fresh emulator), any image
> containing a card number, PAN, IFSC, or a wifi/receipt note will do — the card
> number just needs to be Luhn-valid to show as "Verified".
