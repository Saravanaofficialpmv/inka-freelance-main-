import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../data/models/client.dart';

/// Representation of a contact loaded locally from the user's phonebook.
/// 🔒 PRIVACY GUARANTEE: All contact details are kept strictly on the local device.
/// Contact records are never uploaded to any remote server or external database.
class DeviceContactInfo {
  final String id;
  final String displayName;
  final List<String> phones;
  final List<String> emails;
  final String? address;
  final String? company;

  const DeviceContactInfo({
    required this.id,
    required this.displayName,
    this.phones = const [],
    this.emails = const [],
    this.address,
    this.company,
  });

  String get primaryPhone => phones.isNotEmpty ? phones.first : '';
  String get primaryEmail => emails.isNotEmpty ? emails.first : '';

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Converts this phonebook contact into an Inka [Client] instance.
  Client toClient({String? customId}) {
    return Client(
      id: customId ?? 'client_${DateTime.now().millisecondsSinceEpoch}_${id.replaceAll(RegExp(r'[^\w]'), '')}',
      name: displayName.trim(),
      email: primaryEmail,
      phone: primaryPhone,
      address: address ?? '',
    );
  }

  factory DeviceContactInfo.fromFlutterContact(Contact contact) {
    final phoneList = contact.phones
        .map((p) => p.number.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final emailList = contact.emails
        .map((e) => e.address.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String? fullAddress;
    if (contact.addresses.isNotEmpty) {
      fullAddress = contact.addresses.first.formatted?.trim();
    }

    String? orgName;
    if (contact.organizations.isNotEmpty) {
      orgName = contact.organizations.first.name?.trim();
    }

    final rawName = contact.displayName?.trim();

    return DeviceContactInfo(
      id: contact.id ?? '',
      displayName: (rawName != null && rawName.isNotEmpty) ? rawName : 'Unknown Contact',
      phones: phoneList,
      emails: emailList,
      address: fullAddress,
      company: orgName,
    );
  }
}

/// Service managing secure, read-only on-device contact access and search.
class DeviceContactsService {
  static List<DeviceContactInfo>? _cachedContacts;

  /// Check if contacts read permission is currently granted.
  static Future<bool> hasPermission() async {
    try {
      return await FlutterContacts.permissions.has(PermissionType.read);
    } catch (e) {
      debugPrint('Error checking contact permission: $e');
      return false;
    }
  }

  /// Request read-only contact permission from the user.
  /// Strictly read-only to protect user privacy.
  static Future<bool> requestPermission() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting contact permission: $e');
      return false;
    }
  }

  /// Fetch all phone contacts locally.
  /// Results are sorted alphabetically and cached in memory for high-performance searching.
  static Future<List<DeviceContactInfo>> loadContacts({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedContacts != null) {
      return _cachedContacts!;
    }

    final hasPerm = await hasPermission();
    if (!hasPerm) {
      return [];
    }

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.email,
          ContactProperty.address,
          ContactProperty.organization,
        },
      );

      final List<DeviceContactInfo> list = [];
      for (final c in contacts) {
        final name = c.displayName?.trim() ?? '';
        if (name.isNotEmpty) {
          list.add(DeviceContactInfo.fromFlutterContact(c));
        }
      }

      // Sort alphabetically by name
      list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      _cachedContacts = list;
      return list;
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      return [];
    }
  }

  /// Search contacts in real-time by name, phone number, or email.
  static List<DeviceContactInfo> searchContacts(List<DeviceContactInfo> contacts, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return contacts;

    final numericQuery = query.replaceAll(RegExp(r'[^\d]'), '');

    return contacts.where((contact) {
      // 1. Match by name
      if (contact.displayName.toLowerCase().contains(cleanQuery)) {
        return true;
      }
      // 2. Match by email
      for (final email in contact.emails) {
        if (email.toLowerCase().contains(cleanQuery)) {
          return true;
        }
      }
      // 3. Match by phone number
      if (numericQuery.isNotEmpty) {
        for (final phone in contact.phones) {
          final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanPhone.contains(numericQuery)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  /// Clear the in-memory cache to force a reload next time.
  static void clearCache() {
    _cachedContacts = null;
  }
}
