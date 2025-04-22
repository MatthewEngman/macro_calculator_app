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
    test(
      'getSavedMacros returns empty list when FirestoreSyncService.getSavedUserInfos returns empty',
      () async {
        when(
          () => mockSyncService.getSavedUserInfos(any()),
        ).thenAnswer((_) async => []);
        final result = await repository.getSavedMacros(userId: 'test_user');
        expect(result, isEmpty);
        verify(() => mockSyncService.getSavedUserInfos('test_user')).called(1);
      },
    );
    test(
      'getSavedMacros returns all MacroResults from multiple UserInfos',
      () async {
        final userInfo2 = userInfo.copyWith(id: 'test_user2', name: 'Test2');
        when(
          () => mockSyncService.getSavedUserInfos(any()),
        ).thenAnswer((_) async => [userInfo, userInfo2]);
        final result = await repository.getSavedMacros(userId: 'test_user');
        expect(result.length, 2);
        expect(result[1].name, 'Test2');
        verify(() => mockSyncService.getSavedUserInfos('test_user')).called(1);
      },
    );
    test('getSavedMacros skips corrupted UserInfo objects', () async {
      // Simulate a corrupted UserInfo (e.g., missing required fields)
      final corruptedUserInfo = userInfo.copyWith(id: null, name: null);
      when(
        () => mockSyncService.getSavedUserInfos(any()),
      ).thenAnswer((_) async => [userInfo, corruptedUserInfo]);
      final result = await repository.getSavedMacros(userId: 'test_user');
      // Should only include the valid one
      expect(result.length, 1);
      expect(result.first.name, userInfo.name);
    });

    test(
      'deleteMacro calls FirestoreSyncService.deleteUserInfo with correct parameters',
      () async {
        when(
          () => mockSyncService.deleteUserInfo(any(), any()),
        ).thenAnswer((_) async => Future.value());
        await repository.deleteMacro('macro_id', userId: 'test_user');
        verify(
          () => mockSyncService.deleteUserInfo('test_user', 'macro_id'),
        ).called(1);
      },
    );

    test(
      'setDefaultMacro calls FirestoreSyncService.setDefaultUserInfo with correct parameters',
      () async {
        when(
          () => mockSyncService.setDefaultUserInfo(any(), any()),
        ).thenAnswer((_) async => Future.value());
        await repository.setDefaultMacro('macro_id', userId: 'test_user');
        verify(
          () => mockSyncService.setDefaultUserInfo('test_user', 'macro_id'),
        ).called(1);
      },
    );

    test(
      'getSavedMacros throws or handles gracefully when userId is null',
      () async {
        // If your method is supposed to throw:
        expect(
          () async => await repository.getSavedMacros(userId: null),
          throwsA(isA<Exception>()),
        );
        // Or, if it should return an empty list:
        // final result = await repository.getSavedMacros(userId: null);
        // expect(result, isEmpty);
      },
    );

    test(
      'saveMacro throws or handles gracefully when MacroResult is missing required fields',
      () async {
        final invalidMacro = macroResult.copyWith(userId: null);
        expect(
          () async =>
              await repository.saveMacro(invalidMacro, userId: 'test_user'),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
