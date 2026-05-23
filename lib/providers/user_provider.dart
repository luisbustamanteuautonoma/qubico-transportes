import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  List<User> get users => _users;

  Future<void> fetchUsers() async {
    final data = await DatabaseService.instance.queryAll('users');
    _users = data.map((map) => User.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addUser(User user) async {
    await DatabaseService.instance.insert('users', user.toMap());
    await fetchUsers();
  }

  Future<void> toggleUserStatus(String id, bool currentStatus) async {
    await DatabaseService.instance.update('users', {'is_active': currentStatus ? 0 : 1}, 'id', id);
    await fetchUsers();
  }
}
