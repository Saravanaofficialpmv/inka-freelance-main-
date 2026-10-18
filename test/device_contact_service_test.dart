import 'package:flutter_test/flutter_test.dart';
import 'package:inka/services/device_contact_service.dart';

void main() {
  group('DeviceContactInfo & Search Tests', () {
    const contactA = DeviceContactInfo(
      id: 'c_1',
      displayName: 'Sivaramakrishnan',
      phones: ['+91 98765 43210', '044 2345 6789'],
      emails: ['siva@example.com'],
      address: '12 Anna Salai, Chennai',
      company: 'Siva Enterprises',
    );

    const contactB = DeviceContactInfo(
      id: 'c_2',
      displayName: 'Anand Kumar',
      phones: ['+91 91234 56789'],
      emails: ['anand@techcorp.in'],
      address: '45 MG Road, Bangalore',
    );

    const contactC = DeviceContactInfo(
      id: 'c_3',
      displayName: 'Kavitha Ramesh',
      phones: ['+91 99887 76655'],
      emails: ['kavitha.design@studio.com'],
    );

    final allContacts = [contactA, contactB, contactC];

    test('Primary fields, initials and toClient() conversion', () {
      expect(contactA.primaryPhone, '+91 98765 43210');
      expect(contactA.primaryEmail, 'siva@example.com');
      expect(contactA.initials, 'S');

      expect(contactB.initials, 'AK');

      final client = contactA.toClient();
      expect(client.name, 'Sivaramakrishnan');
      expect(client.phone, '+91 98765 43210');
      expect(client.email, 'siva@example.com');
      expect(client.address, '12 Anna Salai, Chennai');
      expect(client.id, isNotEmpty);
    });

    test('Search contacts by name (case-insensitive & substring)', () {
      // Search by partial first name
      final results1 = DeviceContactsService.searchContacts(allContacts, 'siva');
      expect(results1.length, 1);
      expect(results1.first.displayName, 'Sivaramakrishnan');

      // Search by partial last name
      final results2 = DeviceContactsService.searchContacts(allContacts, 'Kumar');
      expect(results2.length, 1);
      expect(results2.first.displayName, 'Anand Kumar');

      // Search by uppercase
      final results3 = DeviceContactsService.searchContacts(allContacts, 'KAVITHA');
      expect(results3.length, 1);
      expect(results3.first.displayName, 'Kavitha Ramesh');
    });

    test('Search contacts by phone number', () {
      // Search by digits without country code
      final results = DeviceContactsService.searchContacts(allContacts, '98765');
      expect(results.length, 1);
      expect(results.first.displayName, 'Sivaramakrishnan');
    });

    test('Search contacts by email', () {
      final results = DeviceContactsService.searchContacts(allContacts, 'techcorp');
      expect(results.length, 1);
      expect(results.first.displayName, 'Anand Kumar');
    });

    test('Empty search query returns all contacts', () {
      final results = DeviceContactsService.searchContacts(allContacts, '   ');
      expect(results.length, 3);
    });

    test('No matching contacts returns empty list', () {
      final results = DeviceContactsService.searchContacts(allContacts, 'XYZUnknownNonExistentName');
      expect(results, isEmpty);
    });
  });
}
