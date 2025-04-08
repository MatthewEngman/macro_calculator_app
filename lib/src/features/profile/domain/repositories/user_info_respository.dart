import '../entities/user_info.dart';

abstract class UserInfoRepository {
  Future<List<UserInfo>> getSavedUserInfos();
  Future<void> saveUserInfo(UserInfo userInfo);
  Future<void> deleteUserInfo(String id);
  Future<void> setDefaultUserInfo(String id);
  Future<UserInfo?> getDefaultUserInfo();
}
