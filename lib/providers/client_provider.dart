import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../services/database_service.dart';

class ClientProvider with ChangeNotifier {
  List<Client> _clients = [];
  List<Client> get clients => _clients;

  Future<void> fetchClients() async {
    final data = await DatabaseService.instance.queryAll('clients');
    _clients = data.map((e) => Client.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addClient(Client client) async {
    await DatabaseService.instance.insert('clients', client.toMap());
    await fetchClients();
  }
}
