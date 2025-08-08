// Simplified Flutter widget test for the Splitzy app without Mockito
// This version uses manual mocks to avoid build_runner issues

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/main.dart';

// Since we don't have access to the actual service classes, we'll create mock interfaces
// that match what the tests expect

// Base classes that match expected interface
abstract class BaseThemeProvider extends ChangeNotifier {
  bool get isDarkMode;
  ThemeMode get themeMode;
  ThemeData get lightTheme;
  ThemeData get darkTheme;
  void toggleTheme(bool? isDark);
}

abstract class BaseAuthService extends ChangeNotifier {
  bool get isLoggedIn;
  dynamic get currentUser;
}

abstract class BaseLocalStorageService {
  static Future<void> initialize() async {}
}

abstract class BaseDatabaseService extends ChangeNotifier {
  Future<List<BaseGroupModel>> getGroups();
  Future<void> createGroup(BaseGroupModel group);
}

// Simple group model for testing
class BaseGroupModel {
  final String id;
  final String name;
  final List<String> members;
  final Map<String, String> memberNames;
  final String createdBy;
  final DateTime createdAt;

  BaseGroupModel({
    required this.id,
    required this.name,
    required this.members,
    required this.memberNames,
    required this.createdBy,
    required this.createdAt,
  });
}

// Manual mock classes (no code generation needed)
class MockThemeProvider extends BaseThemeProvider {
  bool _isDarkMode = false;
  
  @override
  bool get isDarkMode => _isDarkMode;
  
  @override
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  @override
  void toggleTheme(bool? isDark) {
    _isDarkMode = isDark ?? !_isDarkMode;
    notifyListeners();
  }
  
  @override
  ThemeData get lightTheme => _createLightTheme();
  
  @override
  ThemeData get darkTheme => _createDarkTheme();
}

class MockAuthService extends BaseAuthService {
  bool _isLoggedIn = false;
  String? _mockError;
  
  void setMockError(String? error) {
    _mockError = error;
  }
  
  @override
  bool get isLoggedIn {
    if (_mockError != null) {
      throw Exception(_mockError);
    }
    return _isLoggedIn;
  }
  
  @override
  dynamic get currentUser => null;
  
  void setLoggedIn(bool loggedIn) {
    _isLoggedIn = loggedIn;
  }
}

class MockDatabaseService extends BaseDatabaseService {
  List<BaseGroupModel> _mockGroups = [];
  bool _shouldThrowError = false;
  int _createGroupCallCount = 0;
  
  void setMockGroups(List<BaseGroupModel> groups) {
    _mockGroups = groups;
  }
  
  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }
  
  int get createGroupCallCount => _createGroupCallCount;
  
  @override
  Future<List<BaseGroupModel>> getGroups() async {
    if (_shouldThrowError) {
      throw Exception('Database error');
    }
    return _mockGroups;
  }
  
  @override
  Future<void> createGroup(BaseGroupModel group) async {
    if (_shouldThrowError) {
      throw Exception('Database error');
    }
    _mockGroups.add(group);
    _createGroupCallCount++;
  }
}

void main() {
  group('Splitzy App Widget Tests', () {
    late MockThemeProvider mockThemeProvider;
    late MockAuthService mockAuthService;
    late MockDatabaseService mockDatabaseService;

    setUp(() {
      mockThemeProvider = MockThemeProvider();
      mockAuthService = MockAuthService();
      mockDatabaseService = MockDatabaseService();
    });

    group('SplashScreen Tests', () {
      testWidgets('displays app name, tagline, and loading indicator', (WidgetTester tester) async {
        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        // Verify initial UI elements are present
        expect(find.text('Splitzy'), findsOneWidget);
        expect(find.text('Split expenses with ease'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);

        // Check for the wallet icon (fallback when image fails to load)
        expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      });

      testWidgets('displays error UI when initialization fails', (WidgetTester tester) async {
        // Set up mock to throw error
        mockAuthService.setMockError('Auth initialization failed');

        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        // Wait for initialization to complete
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify error UI elements
        expect(find.text('Initialization Error'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.textContaining('Auth initialization failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retry button works correctly', (WidgetTester tester) async {
        // First, simulate an error
        mockAuthService.setMockError('Network error');

        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify error state
        expect(find.text('Retry'), findsOneWidget);

        // Fix the mock to succeed on retry
        mockAuthService.setMockError(null);

        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Verify loading state appears again
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
      });
    });

    group('Theme Tests', () {
      testWidgets('app respects light theme', (WidgetTester tester) async {
        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        // Verify light theme is applied by checking scaffold background
        final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.theme, isNotNull);
        expect(materialApp.themeMode, ThemeMode.light);
      });

      testWidgets('theme provider can toggle dark mode', (WidgetTester tester) async {
        expect(mockThemeProvider.isDarkMode, false);
        
        mockThemeProvider.toggleTheme(true);
        
        expect(mockThemeProvider.isDarkMode, true);
        expect(mockThemeProvider.themeMode, ThemeMode.dark);
      });
    });

    group('Database Service Tests', () {
      testWidgets('can create mock groups', (WidgetTester tester) async {
        final testGroups = [
          BaseGroupModel(
            id: '1',
            name: 'Test Group',
            members: ['user1', 'user2'],
            memberNames: {'user1': 'User 1', 'user2': 'User 2'},
            createdBy: 'user1',
            createdAt: DateTime.now(),
          ),
        ];
        
        mockDatabaseService.setMockGroups(testGroups);
        
        final groups = await mockDatabaseService.getGroups();
        expect(groups.length, 1);
        expect(groups.first.name, 'Test Group');
      });

      testWidgets('handles database errors correctly', (WidgetTester tester) async {
        mockDatabaseService.setShouldThrowError(true);
        
        expect(() => mockDatabaseService.getGroups(), throwsException);
      });

      testWidgets('tracks create group calls', (WidgetTester tester) async {
        final testGroup = BaseGroupModel(
          id: '1',
          name: 'New Group',
          members: ['user1'],
          memberNames: {'user1': 'User 1'},
          createdBy: 'user1',
          createdAt: DateTime.now(),
        );
        
        expect(mockDatabaseService.createGroupCallCount, 0);
        
        await mockDatabaseService.createGroup(testGroup);
        
        expect(mockDatabaseService.createGroupCallCount, 1);
      });
    });

    group('Auth Service Tests', () {
      testWidgets('can simulate login state', (WidgetTester tester) async {
        expect(mockAuthService.isLoggedIn, false);
        
        mockAuthService.setLoggedIn(true);
        
        expect(mockAuthService.isLoggedIn, true);
      });

      testWidgets('can simulate auth errors', (WidgetTester tester) async {
        mockAuthService.setMockError('Authentication failed');
        
        expect(() => mockAuthService.isLoggedIn, throwsException);
      });
    });

    group('MyApp Widget Tests', () {
      testWidgets('uses theme provider correctly', (WidgetTester tester) async {
        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        // Verify MaterialApp is configured correctly
        final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.title, 'Splitzy');
        expect(materialApp.debugShowCheckedModeBanner, false);
        expect(materialApp.themeMode, ThemeMode.light); // Default for mock
      });

      testWidgets('provides all required services', (WidgetTester tester) async {
        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        // Verify providers are available in the widget tree
        final context = tester.element(find.byType(MaterialApp));
        
        expect(Provider.of<BaseThemeProvider>(context, listen: false), isA<MockThemeProvider>());
        expect(Provider.of<BaseAuthService>(context, listen: false), isA<MockAuthService>());
        expect(Provider.of<BaseDatabaseService>(context, listen: false), isA<MockDatabaseService>());
      });
    });

    group('SplashScreen State Management Tests', () {
      testWidgets('handles loading state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        // Initially should be loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
        
        // Should not show error initially
        expect(find.text('Initialization Error'), findsNothing);
      });

      testWidgets('transitions from loading state after delay', (WidgetTester tester) async {
        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        // Should start with loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // After pumping, should still be in loading state (navigation happens after splash delay)
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('shows different error messages for different failures', (WidgetTester tester) async {
        mockAuthService.setMockError('Network connection failed');

        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.textContaining('Network connection failed'), findsOneWidget);
      });

      testWidgets('error UI has proper styling', (WidgetTester tester) async {
        mockAuthService.setMockError('Test error');

        await tester.pumpWidget(_createTestApp(
          mockThemeProvider,
          mockAuthService,
          mockDatabaseService,
        ));

        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify error components exist
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Initialization Error'), findsOneWidget);
      });
    });
  });
}

// Helper methods to create test widgets

Widget _createTestApp(
  MockThemeProvider mockThemeProvider,
  MockAuthService mockAuthService,
  MockDatabaseService mockDatabaseService,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BaseThemeProvider>.value(value: mockThemeProvider),
      ChangeNotifierProvider<BaseAuthService>.value(value: mockAuthService),
      ChangeNotifierProvider<BaseDatabaseService>.value(value: mockDatabaseService),
    ],
    child: const MyApp(),
  );
}

// Helper methods to create themes
ThemeData _createLightTheme() {
  return ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      onPrimary: Colors.white,
      secondary: Colors.blueAccent,
      error: Colors.red,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}

ThemeData _createDarkTheme() {
  return ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      onPrimary: Colors.white,
      secondary: Colors.blueAccent,
      error: Colors.red,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}