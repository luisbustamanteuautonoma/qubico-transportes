import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';
import '../services/database_service.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseService.instance.queryAll('vehicles');
      _vehicles = data.map((e) => Vehicle.fromMap(e)).toList();

      // If DB is empty, provide some default ones
      if (_vehicles.isEmpty) {
        await addVehicle(Vehicle(name: 'Furgón Pequeño', patente: 'AB-CD-12', maxWeight: 300, driverName: 'Conductor 1'));
        await addVehicle(Vehicle(name: 'Camioneta Mediana', patente: 'WX-YZ-99', maxWeight: 800, driverName: 'Conductor 2'));
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    try {
      final id = await DatabaseService.instance.insert('vehicles', vehicle.toMap());
      final newVehicle = Vehicle(
        id: id,
        name: vehicle.name,
        patente: vehicle.patente,
        maxWeight: vehicle.maxWeight,
        driverName: vehicle.driverName,
      );
      _vehicles.add(newVehicle);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    if (vehicle.id == null) return;
    try {
      await DatabaseService.instance.update('vehicles', vehicle.toMap(), 'id', vehicle.id);
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = vehicle;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
    }
  }
}
