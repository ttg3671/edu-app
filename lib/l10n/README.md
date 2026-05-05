# Multi-Language Support Documentation

## Overview
This app now supports English (en) and Spanish (es) languages with a simple language switcher in the Account page.

## Files Created

### 1. Translation Files
- `lib/l10n/en.json` - English translations
- `lib/l10n/es.json` - Spanish translations

### 2. Core Classes
- `lib/l10n/app_localizations.dart` - Handles loading and managing translations
- `lib/core/utils/language_manager.dart` - Manages language preferences in SharedPreferences
- `lib/cubits/language_cubit.dart` - State management for language changes

## How to Use Translations in Your Screens

### Step 1: Import AppLocalizations
```dart
import 'package:edu_gym/l10n/app_localizations.dart';
```

### Step 2: Get Localizations Instance
```dart
@override
Widget build(BuildContext context) {
  final localizations = AppLocalizations.of(context);

  // Your widget code
}
```

### Step 3: Use Translations
```dart
// Simple translation
Text(localizations?.translate('key') ?? 'Fallback Text')

// Or use helper getters
Text(localizations?.welcomeBack ?? 'Welcome Back')

// With parameters
Text(localizations?.translate('welcome_user', params: {'name': userName}) ?? 'Welcome')
```

## Examples

### Example 1: Simple Text
```dart
Text(
  localizations?.email ?? 'Email',
  style: textTheme.bodyMedium,
)
```

### Example 2: Button Text
```dart
ElevatedButton(
  onPressed: () {},
  child: Text(localizations?.login ?? 'Login'),
)
```

### Example 3: TextField Hint
```dart
TextField(
  decoration: InputDecoration(
    hintText: localizations?.searchHint ?? 'Search..',
  ),
)
```

### Example 4: With Parameters
```dart
Text(
  localizations?.translate(
    'welcome_user',
    params: {'name': 'John'}
  ) ?? 'Welcome, John'
)
```

## Adding New Translations

### Step 1: Add to en.json
```json
{
  "new_key": "New Text in English"
}
```

### Step 2: Add to es.json
```json
{
  "new_key": "Nuevo texto en español"
}
```

### Step 3: (Optional) Add Helper Getter
In `app_localizations.dart`:
```dart
String get newKey => translate('new_key');
```

## Language Switcher

The language switcher is located in:
- **Account Page** → Other section → Language

It allows users to switch between:
- English
- Español

The selection is saved automatically and persists across app restarts.

## Supported Languages

| Language | Code | JSON File |
|----------|------|-----------|
| English  | en   | en.json   |
| Spanish  | es   | es.json   |

## Default Language

The default language is **English (en)**. If no language preference is saved, the app will use English.

## Key Features

1. **Persistent Storage**: Language preference is saved using SharedPreferences
2. **Real-time Updates**: UI updates immediately when language is changed
3. **Fallback Support**: Always includes fallback text in case translations fail
4. **Type-safe**: Uses helper getters for commonly used translations
5. **Parameter Support**: Can inject dynamic values into translations

## Available Translation Keys

See the full list of translation keys in:
- `lib/l10n/en.json`
- `lib/l10n/es.json`

## Common Translation Keys

- `hey_there`, `welcome_back`, `create_account`
- `email`, `password`, `confirm_password`
- `login`, `register`, `logout`
- `home`, `search`, `profile`, `account`
- `edit`, `update`, `delete`, `cancel`, `retry`
- `language`, `english`, `spanish`

And many more!
