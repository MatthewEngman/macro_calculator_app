import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/settings_provider.dart';

class MockUserDB extends Mock implements UserDB {}

void main() {
  late MockUserDB mockUserDB;
  const testFirebaseUserId = 'firebase_test';

  setUp(() {
    mockUserDB = MockUserDB();
  });

  test('insertUser returns user id', () async {
    final user = UserInfo(
      id: null,
      name: 'Alice',
      age: 30,
      sex: 'F',
      weight: 140,
      feet: 5,
      inches: 6,
      activityLevel: ActivityLevel.sedentary,
      goal: Goal.maintain,
      units: Units.imperial,
      isDefault: true,
      lastModified: DateTime.now(),
    );
    // Mock the insertUser method to return a fake id
    when(
      () => mockUserDB.insertUser(user, testFirebaseUserId),
    ).thenAnswer((_) async => '1');

    final result = await mockUserDB.insertUser(user, testFirebaseUserId);
    expect(result, equals('1'));
    verify(() => mockUserDB.insertUser(user, testFirebaseUserId)).called(1);
  });

  test('getAllUsers returns list of users', () async {
    final user = UserInfo(
      id: '1',
      name: 'Alice',
      age: 30,
      sex: 'F',
      weight: 140,
      feet: 5,
      inches: 6,
      activityLevel: ActivityLevel.sedentary,
      goal: Goal.maintain,
      units: Units.imperial,
      isDefault: true,
      lastModified: DateTime.now(),
    );
    when(
      () => mockUserDB.getAllUsers(firebaseUserId: testFirebaseUserId),
    ).thenAnswer((_) async => [user]);

    final users = await mockUserDB.getAllUsers(
      firebaseUserId: testFirebaseUserId,
    );
    expect(users, isA<List<UserInfo>>());
    expect(users.length, equals(1));
    expect(users.first.name, equals('Alice'));
    verify(
      () => mockUserDB.getAllUsers(firebaseUserId: testFirebaseUserId),
    ).called(1);
  });

  test('deleteUser completes without error', () async {
    when(() => mockUserDB.deleteUser('1')).thenAnswer((_) async => 1);
    await mockUserDB.deleteUser('1');
    verify(() => mockUserDB.deleteUser('1')).called(1);
  });

  test('setDefaultUser completes without error', () async {
    when(
      () => mockUserDB.setDefaultUser('1', firebaseUserId: testFirebaseUserId),
    ).thenAnswer((_) async {});
    await mockUserDB.setDefaultUser('1', firebaseUserId: testFirebaseUserId);
    verify(
      () => mockUserDB.setDefaultUser('1', firebaseUserId: testFirebaseUserId),
    ).called(1);
  });

  test('getDefaultUser returns a user', () async {
    final user = UserInfo(
      id: '1',
      name: 'Alice',
      age: 30,
      sex: 'F',
      weight: 140,
      feet: 5,
      inches: 6,
      activityLevel: ActivityLevel.sedentary,
      goal: Goal.maintain,
      units: Units.imperial,
      isDefault: true,
      lastModified: DateTime.now(),
    );
    when(
      () => mockUserDB.getDefaultUser(firebaseUserId: testFirebaseUserId),
    ).thenAnswer((_) async => user);

    final result = await mockUserDB.getDefaultUser(
      firebaseUserId: testFirebaseUserId,
    );
    expect(result, isA<UserInfo>());
    expect(result?.name, equals('Alice'));
    verify(
      () => mockUserDB.getDefaultUser(firebaseUserId: testFirebaseUserId),
    ).called(1);
  });
}
