import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  final List<Map<String, dynamic>> _generatedReports = [];
  List<Map<String, dynamic>> get generatedReports => _generatedReports;

  void addGeneratedReport(String date, String type, String filePath) {
    _generatedReports.add({
      'date': date,
      'type': type,
      'generatedAt': DateTime.now().toIso8601String(),
      'filePath': filePath,
    });
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseService.instance.queryAll('orders');
      _orders = data.map((e) => Order.fromMap(e)).toList();
    } catch (e) {
      print('DB Error in fetchOrders, using resilient in-memory fallback: $e');
      if (_orders.isEmpty) {
        _orders = [];
      }
    }
    
    // RF6: Sort by time window start, then FIFO
    _sortOrders();

    _isLoading = false;
    notifyListeners();
  }

  void _sortOrders() {
    _orders.sort((a, b) {
      // Simple parse of "HH:mm - HH:mm"
      final aStart = a.timeWindow.split(' - ').first;
      final bStart = b.timeWindow.split(' - ').first;
      
      int cmp = aStart.compareTo(bStart);
      if (cmp == 0) {
        // FIFO: Assuming lower ID means registered earlier
        return (a.id ?? 0).compareTo(b.id ?? 0);
      }
      return cmp;
    });
  }

  Future<void> addOrder(Order order) async {
    try {
      final id = await DatabaseService.instance.insert('orders', order.toMap());
      
      // Log creation in audit trail
      await DatabaseService.instance.insert('audit_logs', {
        'user_id': 'Admin',
        'action': 'Creación Pedido #$id',
        'timestamp': DateTime.now().toIso8601String(),
        'old_value': 'Ninguno',
        'new_value': 'Creado y Asignado a ${order.driverId}',
      });
    } catch (e) {
      print('DB Error in addOrder, performing resilient in-memory add: $e');
      final newId = _orders.isEmpty ? 1 : (_orders.map((o) => o.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final newOrder = Order(
        id: newId,
        clientId: order.clientId,
        weight: order.weight,
        height: order.height,
        length: order.length,
        width: order.width,
        loadType: order.loadType,
        timeWindow: order.timeWindow,
        address: order.address,
        status: order.status,
        scheduledDate: order.scheduledDate,
        driverId: order.driverId,
      );
      _orders.add(newOrder);
      _sortOrders();
      notifyListeners();
      return;
    }

    await fetchOrders();
  }

  Future<void> updateOrderStatus(int id, String newStatus, {String? incidentReason, String? evidencePath, String? signaturePath}) async {
    // Fetch old status for logging
    String oldStatus = 'Pendiente';
    String driver = 'Conductor';
    try {
      final oldOrder = _orders.firstWhere((o) => o.id == id);
      oldStatus = oldOrder.status;
      driver = oldOrder.driverId ?? 'Conductor';
    } catch (_) {}

    try {
      final Map<String, dynamic> updates = {
        'status': newStatus,
        'delivery_time': DateTime.now().toIso8601String(),
      };
      if (incidentReason != null) updates['incident_reason'] = incidentReason;
      if (evidencePath != null) updates['evidence_path'] = evidencePath;
      if (signaturePath != null) updates['signature_path'] = signaturePath;

      await DatabaseService.instance.update('orders', updates, 'id', id);

      // Log state transition in audit trail
      await DatabaseService.instance.insert('audit_logs', {
        'user_id': driver,
        'action': 'Actualización Estado Pedido #$id',
        'timestamp': DateTime.now().toIso8601String(),
        'old_value': oldStatus,
        'new_value': newStatus + (incidentReason != null ? ' ($incidentReason)' : ''),
      });
    } catch (e) {
      print('DB Error in updateOrderStatus, performing resilient in-memory update: $e');
      final idx = _orders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final o = _orders[idx];
        _orders[idx] = Order(
          id: o.id,
          clientId: o.clientId,
          weight: o.weight,
          height: o.height,
          length: o.length,
          width: o.width,
          loadType: o.loadType,
          timeWindow: o.timeWindow,
          address: o.address,
          status: newStatus,
          scheduledDate: o.scheduledDate,
          driverId: o.driverId,
          incidentReason: incidentReason ?? o.incidentReason,
          evidencePath: evidencePath ?? o.evidencePath,
          signaturePath: signaturePath ?? o.signaturePath,
          deliveryTime: DateTime.now(),
        );
        _sortOrders();
        notifyListeners();
      }
      return;
    }

    await fetchOrders();
  }

  Future<List<Map<String, dynamic>>> getAuditLogsForOrder(int orderId) async {
    try {
      final data = await DatabaseService.instance.queryAll('audit_logs');
      return data.where((log) => log['action'].toString().contains('#$orderId')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGlobalAuditLogs() async {
    try {
      final data = await DatabaseService.instance.queryAll('audit_logs');
      // Sort by timestamp descending (newest first)
      final logs = List<Map<String, dynamic>>.from(data);
      logs.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      return logs;
    } catch (_) {
      return [];
    }
  }

  Future<void> updateOrder(Order order) async {
    if (order.id == null) return;
    await DatabaseService.instance.update('orders', order.toMap(), 'id', order.id);
    await fetchOrders();
  }

  Future<void> deleteOrder(int id) async {
    await DatabaseService.instance.delete('orders', 'id', id);
    await fetchOrders();
  }

  // RF13: Punctuality Indicator
  String getPunctualityStatus(Order order) {
    if (order.deliveryTime == null) return "Pendiente";
    
    // Extract end of window "HH:mm"
    final endWindowStr = order.timeWindow.split(' - ').last;
    final parts = endWindowStr.split(':');
    final endWindow = DateTime(
      order.scheduledDate.year,
      order.scheduledDate.month,
      order.scheduledDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (order.deliveryTime!.isAfter(endWindow)) {
      final diff = order.deliveryTime!.difference(endWindow).inMinutes;
      return "Atrasado ($diff min)";
    }
    return "A tiempo";
  }
}
