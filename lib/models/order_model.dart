import '../services/security_service.dart';

class Order {
  final int? id;
  final String clientId;
  final double weight;
  final double height;
  final double length;
  final double width;
  final String loadType; // Paquetería, Construcción, Eventos
  final String timeWindow; // e.g., "08:00 - 10:00"
  final String address;
  final String status; // En camino, Entregado, Incidencia, Pendiente
  final DateTime scheduledDate;
  final String? driverId;
  final String? evidencePath;
  final String? signaturePath;
  final String? incidentReason;
  final DateTime? deliveryTime;

  Order({
    this.id,
    required this.clientId,
    required this.weight,
    required this.height,
    required this.length,
    required this.width,
    required this.loadType,
    required this.timeWindow,
    required this.address,
    required this.status,
    required this.scheduledDate,
    this.driverId,
    this.evidencePath,
    this.signaturePath,
    this.incidentReason,
    this.deliveryTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': SecurityService.encrypt(clientId),
      'weight': weight,
      'height': height,
      'length': length,
      'width': width,
      'load_type': loadType,
      'time_window': timeWindow,
      'address': address,
      'status': status,
      'scheduled_date': scheduledDate.toIso8601String(),
      'driver_id': driverId,
      'evidence_path': evidencePath,
      'signature_path': signaturePath,
      'incident_reason': incidentReason,
      'delivery_time': deliveryTime?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      clientId: SecurityService.decrypt(map['client_id']),
      weight: map['weight'],
      height: map['height'],
      length: map['length'],
      width: map['width'],
      loadType: map['load_type'],
      timeWindow: map['time_window'],
      address: map['address'],
      status: map['status'],
      scheduledDate: DateTime.parse(map['scheduled_date']),
      driverId: map['driver_id'],
      evidencePath: map['evidence_path'],
      signaturePath: map['signature_path'],
      incidentReason: map['incident_reason'],
      deliveryTime: map['delivery_time'] != null ? DateTime.parse(map['delivery_time']) : null,
    );
  }
}
