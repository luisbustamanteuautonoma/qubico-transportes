import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateDailyReport(List<Order> orders) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('QÚBICO TRANSPORTES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, fontSize: 18)),
                pw.Text('Reporte Diario de Despachos', style: pw.TextStyle(color: PdfColors.grey700)),
              ],
            ),
            pw.Divider(color: PdfColors.orange800, thickness: 2),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Fecha del reporte: $dateStr'),
              pw.Text('Total de servicios: ${orders.length}'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['ID', 'Cliente', 'Dirección', 'Ventana', 'Estado', 'Puntualidad'],
            data: orders.map((o) {
              final punctuality = _calculatePunctuality(o);
              return [
                o.id.toString(),
                o.clientId,
                o.address,
                o.timeWindow,
                o.status,
                punctuality,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 30),
          _buildSummary(orders),
        ],
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Documento generado automáticamente por Sistema Qúbico', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static String _calculatePunctuality(Order order) {
    if (order.status != 'Entregado') return '-';
    if (order.deliveryTime == null) return '-';

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
      return 'Atrasado ($diff min)';
    }
    return 'A tiempo';
  }

  static pw.Widget _buildSummary(List<Order> orders) {
    final delivered = orders.where((o) => o.status == 'Entregado').length;
    final incidents = orders.where((o) => o.status == 'Incidencia').length;
    final pending = orders.where((o) => o.status == 'Pendiente' || o.status == 'En camino').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN DE OPERACIÓN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 5),
          pw.Text('Servicios Completados: $delivered'),
          pw.Text('Incidencias Reportadas: $incidents'),
          pw.Text('Pendientes de Gestión: $pending'),
        ],
      ),
    );
  }
}
