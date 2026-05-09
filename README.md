# Story Parse 📚

A Flutter language learning app for Desktop and Mobile. Study foreign-language texts paragraph by paragraph, build vocabulary, and practice with flashcards.

---

## Features

- **Multi-language support** — Spanish, Japanese, French, German, Italian, Portuguese, Chinese, Korean, Russian, Arabic (and custom additions)
- **Text import** — `.txt` file, `.csv` file (1- or 2-column), or download from a webpage URL
- **Side-by-side translation** — CSV can include English alongside the target language; toggle with one tap
- **Paragraph reader** — navigate one paragraph at a time; tap any word to add/track it
- **Vocabulary database** — per-language SQLite database of words you've encountered
- **Flashcards** — flip cards with definitions; mark words as "Still learning" or "Got it!"; one-tap "Mark as Learned" to graduate a word
- **Progress tracking** — accuracy stats (times seen / times correct) per word

---

## Requirements

- Flutter SDK ≥ 3.0 — https://docs.flutter.dev/get-started/install
- Dart SDK ≥ 3.0 (included with Flutter)

---

## Setup

```bash
cd story_parse
flutter pub get
```

### Run on Desktop (macOS / Windows / Linux)
```bash
flutter run -d macos     # macOS
flutter run -d windows   # Windows
flutter run -d linux     # Linux
```

### Run on Mobile
```bash
flutter run -d ios       # iOS (requires Xcode)
flutter run -d android   # Android (requires Android Studio / emulator)
```

### Run on Chrome (web — limited file access)
```bash
flutter run -d chrome
```

---

## CSV Format

Two supported formats:

**1-column (target language only):**
```
Hola, ¿cómo estás?
Me llamo Carlos.
Tengo veinte años.
```

**2-column (target + English translation):**
```
Hola, ¿cómo estás?,"Hello, how are you?"
Me llamo Carlos.,My name is Carlos.
Tengo veinte años.,I am twenty years old.
```

Each row becomes one paragraph in the reader.

---

## App Structure

```
lib/
├── main.dart                   # Entry point
├── theme.dart                  # Dark theme (DM Sans + Playfair Display)
├── models/
│   ├── language.dart
│   ├── study_text.dart
│   └── word_entry.dart
├── services/
│   ├── database_service.dart   # SQLite (sqflite + sqflite_common_ffi for desktop)
│   └── text_import_service.dart # .txt / .csv / URL import
├── providers/
│   └── app_provider.dart       # ChangeNotifier state
└── screens/
    ├── home_screen.dart        # Language selection grid
    ├── texts_screen.dart       # Text list + import sheet
    ├── reader_screen.dart      # Paragraph reader + word tap
    ├── flashcard_screen.dart   # Flip card practice
    └── vocabulary_screen.dart  # Word list with tabs
```

---

## How to Use

1. **Launch** the app → you'll see the language grid (10 pre-seeded languages)
2. **Tap a language** to open its Texts screen
3. **Tap "Add Text"** → choose `.txt`, `.csv`, or paste a URL
4. **Tap a text** to open the Reader
5. **Tap a word** in the paragraph → a panel appears to add reading/definition and track it
6. **Navigate paragraphs** with the arrows or the numbered tabs
7. **Tap the flashcard icon** (🃏) in the AppBar to practice unlearned words from the current paragraph — or from the Texts screen to practice all
8. In the Flashcard screen, flip the card, then tap **"Got it!"** / **"Still learning"** or **"Mark as Learned"** to graduate the word
9. **Vocabulary screen** (book icon in AppBar) shows all words split into Studying / Learned tabs

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `sqflite` + `sqflite_common_ffi` | SQLite (mobile + desktop) |
| `file_picker` | .txt / .csv file import |
| `http` | URL download |
| `html` | HTML parsing for URL import |
| `csv` | CSV parsing |
| `google_fonts` | DM Sans + Playfair Display + Noto Sans |
| `flip_card` | Flashcard flip animation |
| `path_provider` | App documents directory |

---

## Notes

- Data is stored locally using SQLite in your app documents folder — no internet required after text import
- For Japanese / Chinese words, Noto Sans is used for correct CJK rendering
- The "Reading" field in the word panel is ideal for furigana, IPA, or romanization
- URL import strips navigation/footer/header elements and extracts `<p>` paragraphs where possible
