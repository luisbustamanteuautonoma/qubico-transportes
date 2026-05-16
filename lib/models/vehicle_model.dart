class Vehicle {
  final int? id;
  final String name;
  final String patente;
  final double maxWeight;
  final String driverName;

  Vehicle({
    this.id,
    required this.name,
    required this.patente,
    required this.maxWeight,
    required this.driverName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'patente': patente,
      'max_weight': maxWeight,
      'driver_name': driverName,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      name: map['name'],
      patente: map['patente'] ?? '',
      maxWeight: map['max_weight'],
      driverName: map['driver_name'],
    );
  }
}
