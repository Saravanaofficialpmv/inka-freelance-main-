import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/business_profile.dart';
import '../data/models/client.dart';
import '../data/models/expense.dart';
import '../data/models/invoice.dart';
import '../data/models/product.dart';
import '../data/models/time_entry.dart';
import '../data/models/project.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _profileDoc(String userId) =>
      _firestore.collection('users').doc(userId).collection('profile').doc('business');

  CollectionReference<Map<String, dynamic>> _clientsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('clients');

  CollectionReference<Map<String, dynamic>> _invoicesCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('invoices');

  CollectionReference<Map<String, dynamic>> _productsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('products');

  CollectionReference<Map<String, dynamic>> _expensesCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('expenses');

  CollectionReference<Map<String, dynamic>> _timeEntriesCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('timeEntries');

  CollectionReference<Map<String, dynamic>> _projectsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('projects');

  // ==================== BUSINESS PROFILE ====================

  Future<void> saveBusinessProfile(BusinessProfile profile, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _profileDoc(uid).set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveBusinessProfile error: $e');
    }
  }

  Future<BusinessProfile?> getBusinessProfile({String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return null;
    try {
      final doc = await _profileDoc(uid).get();
      if (doc.exists && doc.data() != null) {
        return BusinessProfile.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Firestore getBusinessProfile error: $e');
    }
    return null;
  }

  Stream<BusinessProfile?> streamBusinessProfile({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) return Stream.value(null);
    return _profileDoc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return BusinessProfile.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // ==================== CLIENTS ====================

  Future<void> saveClient(Client client, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _clientsCollection(uid).doc(client.id).set(client.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveClient error: $e');
    }
  }

  Future<void> deleteClient(String clientId, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _clientsCollection(uid).doc(clientId).delete();
    } catch (e) {
      debugPrint('Firestore deleteClient error: $e');
    }
  }

  Future<List<Client>> getClients({String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];
    try {
      final snapshot = await _clientsCollection(uid).get();
      return snapshot.docs.map((doc) => Client.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getClients error: $e');
      return [];
    }
  }

  Stream<List<Client>> streamClients({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) return Stream.value([]);
    return _clientsCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Client.fromMap(doc.data())).toList();
    });
  }

  // ==================== INVOICES ====================

  Future<void> saveInvoice(Invoice invoice, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _invoicesCollection(uid).doc(invoice.id).set(invoice.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveInvoice error: $e');
    }
  }

  Future<void> deleteInvoice(String invoiceId, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _invoicesCollection(uid).doc(invoiceId).delete();
    } catch (e) {
      debugPrint('Firestore deleteInvoice error: $e');
    }
  }

  Future<List<Invoice>> getInvoices({String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];
    try {
      final snapshot = await _invoicesCollection(uid).orderBy('issueDate', descending: true).get();
      return snapshot.docs.map((doc) => Invoice.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getInvoices error: $e');
      return [];
    }
  }

  Stream<List<Invoice>> streamInvoices({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) return Stream.value([]);
    return _invoicesCollection(uid).orderBy('issueDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Invoice.fromMap(doc.data())).toList();
    });
  }

  // ==================== PRODUCTS ====================

  Future<void> saveProduct(Product product, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _productsCollection(uid).doc(product.id).set(product.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveProduct error: $e');
    }
  }

  Future<void> deleteProduct(String productId, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _productsCollection(uid).doc(productId).delete();
    } catch (e) {
      debugPrint('Firestore deleteProduct error: $e');
    }
  }

  Future<List<Product>> getProducts({String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];
    try {
      final snapshot = await _productsCollection(uid).get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getProducts error: $e');
      return [];
    }
  }

  Stream<List<Product>> streamProducts({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) return Stream.value([]);
    return _productsCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    });
  }

  // ==================== EXPENSES ====================

  Future<void> saveExpense(Expense expense, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _expensesCollection(uid).doc(expense.id).set(expense.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveExpense error: $e');
    }
  }

  Future<void> deleteExpense(String expenseId, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _expensesCollection(uid).doc(expenseId).delete();
    } catch (e) {
      debugPrint('Firestore deleteExpense error: $e');
    }
  }

  Future<List<Expense>> getExpenses({String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];
    try {
      final snapshot = await _expensesCollection(uid).get();
      return snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getExpenses error: $e');
      return [];
    }
  }

  Stream<List<Expense>> streamExpenses({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) return Stream.value([]);
    return _expensesCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList();
    });
  }

  // ==================== TIME ENTRIES ====================

  Future<void> saveTimeEntry(TimeEntry entry, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _timeEntriesCollection(uid).doc(entry.id).set(entry.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveTimeEntry error: $e');
    }
  }

  Future<void> deleteTimeEntry(String entryId, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _timeEntriesCollection(uid).doc(entryId).delete();
    } catch (e) {
      debugPrint('Firestore deleteTimeEntry error: $e');
    }
  }

  Future<List<TimeEntry>> getTimeEntries({String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];
    try {
      final snapshot = await _timeEntriesCollection(uid).get();
      return snapshot.docs.map((doc) => TimeEntry.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getTimeEntries error: $e');
      return [];
    }
  }

  Stream<List<TimeEntry>> streamTimeEntries({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) return Stream.value([]);
    return _timeEntriesCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TimeEntry.fromMap(doc.data())).toList();
    });
  }

  // ==================== PROJECTS ====================

  Future<void> saveProject(Project project, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _projectsCollection(uid).doc(project.id).set(project.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveProject error: $e');
    }
  }

  Future<void> deleteProject(String projectId, {String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return;
    try {
      await _projectsCollection(uid).doc(projectId).delete();
    } catch (e) {
      debugPrint('Firestore deleteProject error: $e');
    }
  }

  Future<List<Project>> getProjects({String? userId}) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];
    try {
      final snapshot = await _projectsCollection(uid).get();
      return snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getProjects error: $e');
      return [];
    }
  }

  Stream<List<Project>> streamProjects({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) return Stream.value([]);
    return _projectsCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList();
    });
  }

  // ==================== BIDIRECTIONAL SYNC ====================

  /// Syncs Firestore data into local Hive on login, and pushes unsynced local data to Firestore
  Future<void> syncAllData(String userId) async {
    try {
      final profileBox = Hive.box<BusinessProfile>('business_profile');
      final clientsBox = Hive.box<Client>('clients');
      final invoicesBox = Hive.box<Invoice>('invoices');
      final productsBox = Hive.box<Product>('products');
      final expensesBox = Hive.box<Expense>('expenses');
      final timeEntriesBox = Hive.box<TimeEntry>('time_entries');
      final projectsBox = Hive.box<Project>('projects');

      // 1. Sync Profile
      final remoteProfile = await getBusinessProfile(userId: userId);
      final localProfile = profileBox.get('current');
      if (remoteProfile != null) {
        await profileBox.put('current', remoteProfile);
      } else if (localProfile != null && localProfile.businessName.isNotEmpty) {
        await saveBusinessProfile(localProfile, userId: userId);
      }

      // 2. Sync Clients
      final remoteClients = await getClients(userId: userId);
      if (remoteClients.isNotEmpty) {
        for (var c in remoteClients) {
          await clientsBox.put(c.id, c);
        }
      } else {
        for (var c in clientsBox.values) {
          await saveClient(c, userId: userId);
        }
      }

      // 3. Sync Invoices
      final remoteInvoices = await getInvoices(userId: userId);
      if (remoteInvoices.isNotEmpty) {
        for (var inv in remoteInvoices) {
          await invoicesBox.put(inv.id, inv);
        }
      } else {
        for (var inv in invoicesBox.values) {
          await saveInvoice(inv, userId: userId);
        }
      }

      // 4. Sync Products
      final remoteProducts = await getProducts(userId: userId);
      if (remoteProducts.isNotEmpty) {
        for (var p in remoteProducts) {
          await productsBox.put(p.id, p);
        }
      } else {
        for (var p in productsBox.values) {
          await saveProduct(p, userId: userId);
        }
      }

      // 5. Sync Expenses
      final remoteExpenses = await getExpenses(userId: userId);
      if (remoteExpenses.isNotEmpty) {
        for (var exp in remoteExpenses) {
          await expensesBox.put(exp.id, exp);
        }
      } else {
        for (var exp in expensesBox.values) {
          await saveExpense(exp, userId: userId);
        }
      }

      // 6. Sync Time Entries
      final remoteTimeEntries = await getTimeEntries(userId: userId);
      if (remoteTimeEntries.isNotEmpty) {
        for (var te in remoteTimeEntries) {
          await timeEntriesBox.put(te.id, te);
        }
      } else {
        for (var te in timeEntriesBox.values) {
          await saveTimeEntry(te, userId: userId);
        }
      }

      // 7. Sync Projects
      final remoteProjects = await getProjects(userId: userId);
      if (remoteProjects.isNotEmpty) {
        for (var proj in remoteProjects) {
          await projectsBox.put(proj.id, proj);
        }
      } else {
        for (var proj in projectsBox.values) {
          await saveProject(proj, userId: userId);
        }
      }

      debugPrint('Firestore data sync completed for user: $userId');
    } catch (e) {
      debugPrint('Firestore syncAllData error: $e');
    }
  }
}
