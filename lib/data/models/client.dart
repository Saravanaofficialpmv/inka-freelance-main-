import 'package:hive/hive.dart';

class Client extends HiveObject {
  String id;
  String name;
  String phone;
  String email;
  String address;
  String? gstNumber;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.gstNumber,
  });

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gstNumber: map['gstNumber'],
    );
  }
}

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 0; // Use a unique id for this model

  @override
  Client read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final phone = reader.readString();
    final email = reader.readString();
    final address = reader.readString();
    
    // Safely read gstNumber for backward compatibility
    String? gstNumber;
    try {
      if (reader.availableBytes > 0) {
        gstNumber = reader.readString();
      }
    } catch (_) {
      gstNumber = null;
    }

    return Client(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      gstNumber: gstNumber,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.phone);
    writer.writeString(obj.email);
    writer.writeString(obj.address);
    writer.writeString(obj.gstNumber ?? '');
  }
}
