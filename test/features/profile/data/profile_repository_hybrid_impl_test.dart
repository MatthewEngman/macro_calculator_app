import 'package:flutter_test/flutter_test.dart';
import 'package:macro_masher/src/features/calculator/domain/entities/macro_result.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:macro_masher/src/features/profile/data/repositories/profile_repository_hybrid_impl.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockFirestoreSyncService extends Mock implements FirestoreSyncService {}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late ProfileRepositoryHybridImpl repository;
  late MockFirestoreSyncService mockSyncService;
  TestWidgetsFlutterBinding.ensureInitialized();

  final userInfo = UserInfo(
    id: 'test_user',
    name: 'Test',
    age: 30,
    sex: 'male',
    weight: 180,
    feet: 6,
    inches: 0,
    units: Units.imperial,
    activityLevel: ActivityLevel.lightlyActive,
    goal: Goal.maintain,
    lastModified: DateTime.now(),
  );

  final macroResult = MacroResult.fromUserInfo(
    userInfo,
    explicitUserId: 'test_user',
  );

  setUpAll(() {
    registerFallbackValue(userInfo);
  });

  setUp(() {
    mockSyncService = MockFirestoreSyncService();
    repository = ProfileRepositoryHybridImpl(mockSyncService);
  });

  group('ProfileRepositoryHybridImpl', () {
    test('saveMacro calls FirestoreSyncService.saveUserInfo', () async {
      when(
        () => mockSyncService.saveUserInfo(any(), any()),
      ).thenAnswer((_) async => true);

      await repository.saveMacro(macroResult, userId: 'test_user');

      verify(
        () => mockSyncService.saveUserInfo('test_user', userInfo),
      ).called(1);
    });

    test(
      'saveMacro throws when FirestoreSyncService.saveUserInfo throws',
      () async {
        when(
          () => mockSyncService.saveUserInfo(any(), any()),
        ).thenThrow(Exception('Firestore error'));

        expect(
          () async =>
              await repository.saveMacro(macroResult, userId: 'test_user'),
          throwsA(isA<Exception>()),
        );
        verify(
          () => mockSyncService.saveUserInfo('test_user', userInfo),
        ).called(1);
      },
    );

    test(
      'getSavedMacros returns MacroResult list from FirestoreSyncService.getSavedUserInfos',
      () async {
        // Simulate FirestoreSyncService returning a list with userInfo
        when(
          () => mockSyncService.getSavedUserInfos(any()),
        ).thenAnswer((_) async => [userInfo]);

        final result = await repository.getSavedMacros(userId: 'test_user');

        expect(result, isA<List<MacroResult>>());
        expect(result, isNotEmpty);
        expect(result.first.userId, equals('test_user'));
        expect(result.first.name, equals(userInfo.name));
        verify(() => mockSyncService.getSavedUserInfos('test_user')).called(1);
      },
    );

    test(
      'getSavedMacros returns empty list if FirestoreSyncService.getSavedUserInfos throws',
      () async {
        when(
          () => mockSyncService.getSavedUserInfos(any()),
        ).thenThrow(Exception('Firestore error'));

        final result = await repository.getSavedMacros(userId: 'test_user');

        expect(result, isEmpty);
        verify(() => mockSyncService.getSavedUserInfos('test_user')).called(1);
      },
    );
  });
}
