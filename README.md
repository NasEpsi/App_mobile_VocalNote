# Voxnote - Application de notes vocales (Flutter)

Application mobile de prise de notes vocales inspirée de la maquette
[Voxnote](https://transcribe-and-save.lovable.app). Elle permet d'enregistrer
de l'audio, d'importer des fichiers audio, de transcrire la parole en texte, de
sauvegarder les notes localement et de les exporter en PDF ou TXT.

## Fonctionnalités

- Enregistrement audio depuis le micro
- Import d'un fichier audio existant
- Transcription parole -> texte (hybride) :
  - en direct, sur l'appareil, pendant l'enregistrement (`speech_to_text`)
  - via le cloud pour les fichiers importés (API Hugging Face, modèle Whisper)
- Sauvegarde des notes dans une base SQLite
- Export d'une note en PDF et en TXT (avec partage système)
- Filtrage par catégorie (Tous, Travail, Idées, Perso)
- Lecture audio de la note enregistrée

## Architecture

```
lib/
  main.dart                      # MultiProvider + chargement .env + MaterialApp
  models/
    note.dart                    # Modèle Note + catégories
  services/
    database_service.dart        # CRUD SQLite (sqflite)
    audio_recorder_service.dart  # Enregistrement micro (record)
    speech_service.dart          # Transcription live (speech_to_text)
    transcription_service.dart   # Transcription cloud (Hugging Face Whisper)
    audio_player_service.dart    # Lecture audio (just_audio)
    export_service.dart          # Export PDF/TXT + partage (pdf, printing, share_plus)
  providers/
    notes_provider.dart          # Liste, filtre et CRUD des notes
    recording_provider.dart      # État d'enregistrement + transcript live
  screens/
    home_screen.dart             # Écran principal (maquette Voxnote)
    record_screen.dart           # Enregistrement + révision avant sauvegarde
    note_detail_screen.dart      # Lecture, édition et export d'une note
  widgets/
    note_card.dart
    filter_chips.dart
    record_button.dart
    empty_state.dart
```

Gestion d'état : [`provider`](https://pub.dev/packages/provider).

## Prérequis

- Flutter (canal stable) installé. Vérifier avec `flutter doctor`.
- Pour Android : Android Studio / Android SDK configuré
  (`flutter doctor` doit valider la ligne "Android toolchain").

## Configuration

1. Installer les dépendances :

```bash
flutter pub get
```

2. Configurer la transcription cloud (pour les fichiers importés). Copier le
   modèle d'environnement puis renseigner un jeton Hugging Face **gratuit** :

```bash
cp .env.example .env
```

Ouvrir `.env` et renseigner :

```
HF_API_TOKEN=hf_votre_token
HF_STT_MODEL=openai/whisper-large-v3
```

Créez un jeton gratuit sur https://huggingface.co/settings/tokens.

> Sans jeton, l'enregistrement et la transcription en direct fonctionnent
> toujours ; seule la transcription des fichiers **importés** est désactivée.

## Lancement

```bash
flutter run          
```
