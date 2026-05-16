import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseService.instance.queryAll('orders');
    _orders = data.map((e) => Order.fromMap(e)).toList();
    
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
    await DatabaseService.instance.insert('orders', order.toMap());
    await fetchOrders();
  }

  Future<void> updateOrderStatus(int id, String newStatus, {String? incidentReason, String? evidencePath, String? signaturePath}) async {
    final Map<String, dynamic> updates = {
      'status': newStatus,
      'delivery_time': DateTime.now().toIso8601String(),
    };
    if (incidentReason != null) updates['incident_reason'] = incidentReason;
    if (evidencePath != null) updates['evidence_path'] = evidencePath;
    if (signaturePath != null) updates['signature_path'] = signaturePath;

    await DatabaseService.instance.update('orders', updates, 'id', id);
    await fetchOrders();
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
