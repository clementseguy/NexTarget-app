import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/screens/profile_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'profile_screen_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;

  final testUser = {
    'id': '123e4567-e89b-12d3-a456-426614174000',
    'email': 'alice@example.com',
    'display_name': 'Alice Dupont',
    'avatar_url': null,
    'experience_level': 'beginner',
    'provider': 'google',
    'created_at': '2025-10-21T14:30:00Z',
    'is_active': true,
  };

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget buildProfileScreen(AuthProvider authProvider) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('affiche "Non connecté" si utilisateur non authentifié', (tester) async {
      final authProvider = AuthProvider(mockAuthService);
      await tester.pumpWidget(buildProfileScreen(authProvider));

      expect(find.text('Mon profil'), findsOneWidget);
      expect(find.text('Non connecté'), findsOneWidget);
    });

    testWidgets('affiche le nom et l\'email de l\'utilisateur', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      expect(find.text('Alice Dupont'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('affiche les initiales si avatar_url est null', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      // Initiales de "Alice Dupont" = "AD"
      expect(find.text('AD'), findsOneWidget);
    });

    testWidgets('affiche le SegmentedButton avec le niveau actuel sélectionné', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      expect(find.text('Débutant'), findsOneWidget);
      expect(find.text('Confirmé'), findsOneWidget);
      expect(find.text('Expert'), findsOneWidget);
    });

    testWidgets('affiche le provider avec majuscule', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('affiche les labels d\'information', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      expect(find.text('Membre depuis'), findsOneWidget);
      expect(find.text('Connexion via'), findsOneWidget);
    });

    testWidgets('affiche la date created_at formatée en français', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      // '2025-10-21T14:30:00Z' → '21 oct. 2025' en fr_FR
      expect(find.text('21 oct. 2025'), findsOneWidget);
    });

    testWidgets('affiche tiret si created_at est null', (tester) async {
      final userNoDate = {...testUser, 'created_at': null};
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => userNoDate);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      // Quand created_at est null, on affiche '—'
      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('affiche le bouton "Se déconnecter"', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      expect(find.text('Se déconnecter'), findsOneWidget);
    });

    testWidgets('changement de niveau appelle updateExperienceLevel', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);
      when(mockAuthService.updateProfile(experienceLevel: 'expert'))
          .thenAnswer((_) async => {...testUser, 'experience_level': 'expert'});

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      // Tap sur "Expert"
      await tester.tap(find.text('Expert'));
      await tester.pump();

      verify(mockAuthService.updateProfile(experienceLevel: 'expert')).called(1);
    });

    testWidgets('affiche SnackBar en cas d\'erreur de mise à jour', (tester) async {
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => testUser);
      when(mockAuthService.updateProfile(experienceLevel: 'expert'))
          .thenThrow(Exception('Erreur réseau'));

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      await tester.tap(find.text('Expert'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur : impossible de mettre à jour le niveau'), findsOneWidget);
    });

    testWidgets('affiche initiale de l\'email si display_name est null', (tester) async {
      final userNoName = {...testUser, 'display_name': null};
      when(mockAuthService.hasToken()).thenAnswer((_) async => true);
      when(mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthService.getUserInfo()).thenAnswer((_) async => userNoName);

      final authProvider = AuthProvider(mockAuthService);
      await authProvider.checkAuthStatus();

      await tester.pumpWidget(buildProfileScreen(authProvider));
      await tester.pump();

      // Initiale de l'email "alice@example.com" = "A"
      expect(find.text('A'), findsOneWidget);
    });
  });
}
