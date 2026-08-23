# StoryParse Project Overview

StoryParse is a Flutter-based application designed to help language learners master new vocabulary by engaging with authentic content such as stories and articles. The application provides a structured path from selecting a target language to actively studying cards through an integrated flashcard system.

## Core Functionality
- **Language Management**: Allows users to add, manage, and select various target languages.
- **Content Ingestion**: Support for importing study materials from local files (TXT, CSV) or remote URLs.
- **Interactive Reading**: A dedicated reader mode providing translation toggles and context-aware navigation.
- **Vocabulary Tracking**: Automatically identifies words within texts and tracks user progress (e.g., "learned" status).
- **Flashcard System**: A gamified flashcard experience with progress tracking, review cycles, and "Practice Again" functionality.
- **Dictionary Integration**: A built-in dictionary for immediate lookups of definitions and usage notes.

## Navigation and Pages
- **Home Screen**: The entry point where users select their current target language from a grid of available cards.
- **Texts Screen**: A dashboard for a specific language, listing all imported content and displaying study statistics (total words, learned words, etc.).
- **Reader Screen**: An immersive reading environment for a chosen text, featuring a translation toggle and paragraph-level navigation.
- **Flashcard Screen**: A focused study session where users can review a generated queue of cards.
- **Vocabulary Screen**: A gallery of all unique words found in the user's selected texts, allowing for bulk review.
- **Dictionary Screen**: A dedicated space to search for words and view multi-sense definitions.
- **Settings Screen**: General application configurations.

## User Workflow: From Selection to Study
The typical user path from initial selection to active study follows these steps:

### 1. Language Selection (Home Screen)
The user begins on the **Home Screen**, which displays a grid of available languages. The user selects their target language (e.g., "French"). If no languages are present, they can add a new one via a prompt.

### 2. Content Selection (Texts Screen)
Upon selecting a language, the user is directed to the **Texts Screen**.
- Here, they can browse a list of available stories or articles.
- New material can be added via the **Add Text** floating action button, which supports TXT files, CSV files, and web URLs.

### 3. Interactive Reading (Reader Screen)
When a user selects a specific text, they enter the **Reader Screen**:
- They can read the content and toggle between the original language and the translation.
- They can quickly jump between paragraphs.
- They can view specific context details (like notes or definitions) for any word encountered.

### 4. Focused Study (Flashcard Screen)
To transition into active study, the user can access flashcards from two points:
- **Global Study**: From the **Texts Screen**, the user can tap the **Flashcards** icon in the top bar to study all unlearned words in the current language.
- **Contextual Study**: From the **Reader Screen**, the user can tap the **Flashcard** icon in the action bar to study only the words found in the *current paragraph*.

Once on the **Flashcard Screen**, the user enters a focused review mode with a progress bar and the ability to mark words as "learned" or request a "Practice Again" session.
