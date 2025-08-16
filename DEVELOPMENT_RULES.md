# Flutter Development Rules & Action Plan for Claude Code Agent

## Core Principle
**THINK → READ → THINK → EXECUTE → VERIFY**
Every change must follow this cycle to avoid rushed or inconsistent code.

---

## 1. Stack & Architecture Specification

### Technology Stack
- **Mobile**: Flutter (latest stable - 3.24+)
- **State Management**: Provider (with ChangeNotifier pattern)
- **Backend**: Laravel (RESTful APIs)
- **Database**: PostgreSQL (Dockerized, API-only access)
- **Authentication**: JWT tokens with secure storage
- **Users**: Two roles - Users & Organisers
- **Region**: Pan-African system (multi-locale support)

### Flutter Project Structure
```
lib/
├── core/
│   ├── constants/      # App constants, colors, dimensions
│   ├── errors/         # Error handling and exceptions
│   ├── network/        # API client, interceptors
│   └── utils/          # Helpers, formatters, validators
├── data/
│   ├── models/         # Data models (fromJson/toJson)
│   ├── repositories/   # Data layer implementation
│   └── datasources/    # Remote/local data sources
├── domain/
│   ├── entities/       # Business entities
│   ├── repositories/   # Repository contracts
│   └── usecases/       # Business logic
├── presentation/
│   ├── providers/      # ChangeNotifiers
│   ├── screens/        # Full screen widgets
│   ├── widgets/        # Reusable widgets
│   └── theme/          # Theme data
└── main.dart
```

---

## 2. Core Development Process

### Step 1: THINK (Analyze)
- Understand the requirement completely
- Identify affected widgets and providers
- Check for existing similar implementations
- Consider performance implications
- Plan state management approach

### Step 2: READ (Context Gathering)
- Review relevant screens, widgets, and providers
- Check existing API endpoints and models
- Understand current navigation flow
- Review theme and design system usage
- Check for existing utility functions

### Step 3: THINK (Strategy Refinement)
- Refine approach based on codebase patterns
- Identify potential widget rebuilds
- Plan error handling strategy
- Consider loading states and edge cases
- Verify alignment with Material 3 guidelines

### Step 4: EXECUTE (Implementation)
- Implement with minimal code changes
- Follow existing patterns strictly
- Use const constructors where possible
- Implement proper dispose() methods
- Add appropriate error boundaries

### Step 5: VERIFY (Quality Check)
- Test on multiple screen sizes
- Verify hot reload compatibility
- Check for memory leaks
- Validate accessibility features
- Ensure smooth animations (60 FPS)

---

## 3. Flutter-Specific Coding Rules

### 3.1 Widget Rules
- **Max widget build method**: 80 lines (extract to methods/widgets if larger)
- **Prefer composition**: Small, focused widgets over large monolithic ones
- **Use const constructors**: Mark widgets as const when possible
- **Separate business logic**: Keep widgets dumb, logic in providers
- **Widget keys**: Use keys for lists and stateful widgets in collections

### 3.2 State Management Rules (Provider)
```dart
// ALWAYS follow this pattern for providers
class ExampleProvider extends ChangeNotifier {
  // Private state
  bool _isLoading = false;
  String? _error;
  List<Item> _items = [];
  
  // Public getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Item> get items => List.unmodifiable(_items);
  
  // Methods with proper error handling
  Future<void> fetchItems() async {
    _setLoading(true);
    try {
      _items = await repository.getItems();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

### 3.3 Navigation Rules
- Use Navigator 2.0 with declarative routing
- Define routes as constants
- Pass data via constructor parameters, not arguments
- Handle back button properly on Android
- Implement proper WillPopScope for form screens

### 3.4 API Integration Rules
```dart
// Standard API response model
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  
  ApiResponse.success(this.data) : success = true, error = null;
  ApiResponse.error(this.error) : success = false, data = null;
}

// Always use try-catch with specific error handling
try {
  final response = await apiClient.get('/endpoint');
  return ApiResponse.success(Model.fromJson(response));
} on SocketException {
  return ApiResponse.error('No internet connection');
} on TimeoutException {
  return ApiResponse.error('Request timeout');
} catch (e) {
  return ApiResponse.error('Unexpected error occurred');
}
```

### 3.5 Performance Rules
- **Image optimization**: Use cached_network_image for remote images
- **List performance**: Use ListView.builder for long lists
- **Lazy loading**: Implement pagination for large datasets
- **Memory management**: Dispose controllers, streams, and animations
- **Build optimization**: Use const widgets and avoid unnecessary rebuilds

### 3.6 UI/UX Rules
- **Material 3**: Follow Material You design guidelines
- **Responsive design**: Support phones, tablets, and foldables
- **Dark mode**: Implement proper theme switching
- **Loading states**: Show skeletons or shimmer effects
- **Error states**: User-friendly error messages with retry options
- **Empty states**: Meaningful illustrations and CTAs

---

## 4. File Organization Rules

### 4.1 File Size Limits
- **Widgets**: Max 200 lines
- **Providers**: Max 300 lines
- **Screens**: Max 350 lines
- **Models**: Max 150 lines per model
- **Utils**: Max 100 lines per function file

### 4.2 Naming Conventions
```dart
// Files: snake_case
user_profile_screen.dart
api_client.dart

// Classes: PascalCase
class UserProfileScreen extends StatelessWidget {}
class ApiClient {}

// Variables: camelCase
final userName = 'John';
const maxRetryCount = 3;

// Private members: _camelCase
String _privateField;
void _privateMethod() {}

// Constants: camelCase or SCREAMING_SNAKE_CASE for config
const apiBaseUrl = 'https://api.example.com';
const int MAX_FILE_SIZE = 5242880; // 5MB
```

### 4.3 Import Organization
```dart
// Order: dart → flutter → packages → project
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '/core/constants/app_constants.dart';
import '/data/models/user_model.dart';
```

---

## 5. Testing Requirements

### 5.1 Widget Testing
```dart
// Test every custom widget
testWidgets('Widget displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(data: testData),
    ),
  );
  
  expect(find.text('Expected Text'), findsOneWidget);
  expect(find.byType(IconButton), findsNWidgets(2));
});
```

### 5.2 Provider Testing
```dart
// Test all provider methods
test('Provider updates state correctly', () async {
  final provider = ExampleProvider();
  
  expect(provider.isLoading, false);
  
  final future = provider.fetchItems();
  expect(provider.isLoading, true);
  
  await future;
  expect(provider.isLoading, false);
  expect(provider.items.isNotEmpty, true);
});
```

---

## 6. AI Agent Specific Rules

### 6.1 Context Requirements
Before any task, agent must have:
- Current screen/feature being worked on
- Existing providers and their state
- API endpoints available
- Design requirements/mockups
- Performance constraints

### 6.2 Code Generation Rules
```dart
// ALWAYS include these in generated code:

// 1. Proper imports
import 'package:flutter/material.dart';

// 2. Documentation
/// Brief description of what this widget/class does
/// 
/// Usage:
/// ```dart
/// ExampleWidget(param: value)
/// ```

// 3. Type safety
final String userName; // Never use dynamic unless necessary
final List<User> users; // Specify generic types

// 4. Null safety
String? nullableValue; // Use nullable types appropriately
late final TextEditingController controller; // Use late for lifecycle-dependent vars

// 5. Error handling
try {
  // risky operation
} catch (e, stackTrace) {
  // log error with stack trace
  debugPrint('Error: $e\n$stackTrace');
}
```

### 6.3 Progressive Enhancement
1. **Start with basic functionality**: Get it working first
2. **Add error handling**: Handle failures gracefully
3. **Implement loading states**: Show progress indicators
4. **Add animations**: Smooth transitions (after functionality works)
5. **Optimize performance**: Profile and optimize last

### 6.4 Forbidden Actions
- ❌ Never modify pubspec.yaml without explicit permission
- ❌ Never change app architecture without discussion
- ❌ Never remove existing error handling
- ❌ Never use `print()` - use `debugPrint()` or logging
- ❌ Never commit commented-out code
- ❌ Never use absolute positioning without responsive constraints
- ❌ Never hardcode colors/dimensions - use theme

### 6.5 Required Actions
- ✅ Always dispose of controllers in `dispose()`
- ✅ Always handle loading and error states
- ✅ Always validate user input
- ✅ Always use SafeArea for top-level screens
- ✅ Always test on smallest device (iPhone SE) and largest tablet
- ✅ Always implement pull-to-refresh for list screens
- ✅ Always cache images and API responses appropriately

---

## 7. Communication Protocol

### 7.1 Task Initiation
```markdown
TASK: [Clear single-line description]
CONTEXT: [Current state and dependencies]
CONSTRAINTS: [What NOT to change]
SUCCESS CRITERIA: [Definition of done]
```

### 7.2 Progress Updates
```markdown
STATUS: [Starting|In Progress|Blocked|Testing|Complete]
COMPLETED: [What's done]
NEXT: [What's being worked on]
BLOCKERS: [Any issues]
```

### 7.3 Code Review Checklist
- [ ] Follows existing patterns
- [ ] No unnecessary changes
- [ ] Proper error handling
- [ ] Loading states implemented
- [ ] Responsive on all devices
- [ ] Memory leaks prevented
- [ ] Documentation added
- [ ] No hardcoded values
- [ ] Tests included/updated

---

## 8. Common Patterns Library

### 8.1 Screen Template
```dart
class ExampleScreen extends StatelessWidget {
  static const String routeName = '/example';
  
  const ExampleScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: SafeArea(
        child: Consumer<ExampleProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const LoadingWidget();
            }
            
            if (provider.error != null) {
              return ErrorWidget(
                message: provider.error!,
                onRetry: provider.retry,
              );
            }
            
            if (provider.items.isEmpty) {
              return const EmptyStateWidget();
            }
            
            return ListView.builder(
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                return ItemWidget(item: provider.items[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
```

### 8.2 Form Handling
```dart
class FormExample extends StatefulWidget {
  @override
  _FormExampleState createState() => _FormExampleState();
}

class _FormExampleState extends State<FormExample> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );
    
    try {
      await context.read<AuthProvider>().submit(_emailController.text);
      Navigator.pop(context); // Close loading
      Navigator.pop(context, true); // Return success
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            validator: Validators.email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

---

## 9. Emergency Protocols

### 9.1 Breaking Changes
If breaking changes are necessary:
1. STOP and document why
2. List all affected files
3. Get explicit approval
4. Create migration plan
5. Update documentation

### 9.2 Performance Issues
If performance degrades:
1. Profile with Flutter DevTools
2. Identify the bottleneck
3. Document findings
4. Propose optimization
5. Test on low-end devices

### 9.3 Rollback Procedure
1. Git stash current changes
2. Checkout last known good state
3. Document what went wrong
4. Create fix plan
5. Re-attempt with lessons learned

---

## Version Control

**Last Updated**: August 2025
**Flutter Version**: 3.24+
**Dart Version**: 3.5+
**Provider Version**: 6.1+

Remember: **Quality > Speed**. A working simple solution is better than a broken complex one.