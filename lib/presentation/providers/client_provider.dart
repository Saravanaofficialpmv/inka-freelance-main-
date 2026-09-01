import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/client.dart';
import '../../services/firestore_service.dart';

final clientSearchQueryProvider = StateProvider<String>((ref) => '');

final clientsProvider = StateNotifierProvider<ClientsNotifier, List<Client>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ClientsNotifier(firestoreService);
});

final clientProvider = clientsProvider;

final filteredClientsProvider = Provider<List<Client>>((ref) {
  final query = ref.watch(clientSearchQueryProvider).toLowerCase();
  final clients = ref.watch(clientsProvider);

  if (query.isEmpty) return clients;
  
  return clients.where((client) {
    return client.name.toLowerCase().contains(query) ||
           client.phone.toLowerCase().contains(query) ||
           client.email.toLowerCase().contains(query);
  }).toList();
});

class ClientsNotifier extends StateNotifier<List<Client>> {
  final FirestoreService _firestoreService;

  ClientsNotifier(this._firestoreService) : super([]) {
    _loadClients();
  }

  late final Box<Client> _clientsBox = Hive.box<Client>('clients');

  Future<void> _loadClients() async {
    state = _clientsBox.values.toList();
  }

  void refreshFromLocal() {
    state = _clientsBox.values.toList();
  }

  void clear() {
    state = [];
    _clientsBox.clear();
  }

  Future<void> addClient(Client client) async {
    final newClient = client.copyWith(id: client.id.isEmpty ? DateTime.now().toIso8601String() : client.id);
    await _clientsBox.put(newClient.id, newClient);
    state = _clientsBox.values.toList();
    await _firestoreService.saveClient(newClient);
  }

  Future<void> updateClient(Client client) async {
    await _clientsBox.put(client.id, client);
    state = _clientsBox.values.toList();
    await _firestoreService.saveClient(client);
  }

  Future<void> deleteClient(String id) async {
    await _clientsBox.delete(id);
    state = _clientsBox.values.toList();
    await _firestoreService.deleteClient(id);
  }
}
