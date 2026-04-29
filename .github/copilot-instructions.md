# AI Agent Instructions for Quiz App Supabase

## Project Overview
A Flutter-based quiz application that fetches questions from a Supabase (PostgreSQL) backend. The app presents a hierarchical structure: Categories → Quizzes → Questions (4-option multiple choice). Currently, the screen layer is empty and under development.

## Architecture

### Data Flow
**Supabase Tables** → **SupabaseService** (singleton query methods) → **Model Classes** (JSON deserialization) → **Future Plans: Screens + State Management**

### Key Components
- **Models** (`lib/models/`): `Category`, `Quiz`, `Question` - plain Dart classes with `fromJson()` and `toJson()` factories
- **Services** (`lib/services/supabase_service.dart`): Central service for all database queries via REST API
- **Screens** (`lib/screen/`): Currently empty - planned for UI implementation using Material3

## Development Conventions

### Supabase Integration Pattern
Database queries always:
1. Use `Supabase.instance.client` initialized in `main.dart`
2. Cast responses as `List` before mapping to models: `(response as List).map(...).toList()`
3. Wrap in try-catch with descriptive error messages: `Exception('Failed to load X: $e')`
4. Order results by `created_at` ascending (standard pattern for temporal ordering)

Example (from `supabase_service.dart`):
```dart
Future<List<Category>> getCategories() async {
  try {
    final response = await _supabase
        .from('categories')
        .select()
        .order('created_at', ascending: true);
    return (response as List)
        .map((category) => Category.fromJson(category))
        .toList();
  } catch (e) {
    throw Exception('Failed to load categories: $e');
  }
}
```

### Model Class Pattern
All models implement:
- Constructor with required fields (nullable fields optional)
- `factory Category.fromJson(Map<String, dynamic>)` for deserialization
- `Map<String, dynamic> toJson()` for serialization
- Proper DateTime parsing: `DateTime.parse(json['created_at'] as String)`

### JSON Key Mapping Convention
- Database columns use snake_case: `category_id`, `created_at`, `question_text`
- Dart model properties use camelCase: `categoryId`, `createdAt`, `questionText`
- Always cast to expected type in fromJson: `json['field'] as String`

## Known Issues & Patterns

### Bugs to Fix
1. **`SupabaseService.getQuizById()`** (line 63): Returns Category model instead of Quiz; references undefined `categoryId`
2. **`Quiz.fromJson()`**: Maps `json['description']` to both `title` and `description` fields (title should map to `json['title']`)
3. **`Category.toJson()`**: Missing `icon` field in returned map

### Code Quality Notes
- Models use nullable fields with default null for optional data (`description`, `icon`)
- Question model includes helper: `List<String> get options` and `getOptionLetter(int)` for UI convenience
- Service uses enum-like filtering: `.eq('field', value)` for queries

## Dependencies & Setup
- **Flutter SDK**: ^3.11.0
- **supabase_flutter**: ^2.12.4 (manages authentication, real-time sync, REST queries)
- **google_fonts**: ^8.1.0 (Material Design typography)
- **Material3**: Enabled globally in `main.dart` theme configuration
- Supabase credentials hardcoded in `main.dart` (public anon key acceptable for client-side: URL is `yhwwxjlayuckweydroju.supabase.co`)

## Project Structure Important Notes
- **Empty screen folder**: Implement new screens here using Stateful/Stateless widgets
- **Single service file**: All database logic centralized in `SupabaseService` — add methods here for new data operations
- **No state management yet**: Plan for adding Provider, Riverpod, or Bloc for UI state (quiz progress, answer tracking, scoring)
- Test folder contains only `widget_test.dart` — unit/widget tests minimal

## Common Tasks

### Adding a New Quiz Feature
1. Add query method to `SupabaseService` following the exception-wrapped pattern
2. Create corresponding screen in `lib/screen/` using `StatefulWidget` for question progression
3. Add state tracking (selected answers, score, current question index) — currently no provider pattern yet
4. Use Material3 theme colors defined in `MyApp.build()`

### Modifying Database Queries
- Always validate JSON field names match Supabase table columns
- Use `.eq()`, `.order()`, `.select()` chaining in the standard way shown
- Test mapping with `toJson()/fromJson()` roundtrip (many bugs are JSON key mismatches)

## Testing & Debugging
- No automated tests configured; consider adding `flutter_test` integration tests
- Debug Supabase queries by checking browser console when testing web platform
- Model deserialization errors are most common — ensure JSON keys match exactly (snake_case in DB)
