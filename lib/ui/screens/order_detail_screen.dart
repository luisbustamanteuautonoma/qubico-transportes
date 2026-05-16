import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final bool isAdmin;

  const OrderDetailScreen({super.key, required this.order, this.isAdmin = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _selectedIncidentReason;
  final List<String> _incidentReasons = [
    'Cliente ausente',
    'Dirección incorrecta',
    'Rechazado por cliente',
    'Problema con vehículo',
  ];

  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppTheme.primaryBlue,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _launchGoogleMaps() async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent("${widget.order.address}, Santiago, Chile")}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Pedido #${widget.order.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _launchGoogleMaps,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('GOOGLE MAPS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MapScreen(selectedOrder: widget.order)),
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('MAPA QÚBICO'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
            if (!widget.isAdmin) ...[
              const SizedBox(height: 32),
              const Text(
                'ACCIONES DE ENTREGA',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (widget.order.status != 'Entregado' && widget.order.status != 'Incidencia') ...[
                ElevatedButton.icon(
                  onPressed: () => _updateStatus('En camino'),
                  icon: const Icon(Icons.directions_car),
                  label: const Text('MARCAR "EN CAMINO"'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showSignatureDialog('Entregado'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('MARCAR "ENTREGADO"'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showIncidentDialog(),
                  icon: const Icon(Icons.warning),
                  label: const Text('REPORTAR "INCIDENCIA"'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.errorColor,
                  ),
                ),
              ] else ...[
                Center(
                  child: Text(
                    'Este pedido ya ha sido procesado.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                  ),
                ),
              ],
            ] else if (widget.order.status == 'Entregado' || widget.order.status == 'Incidencia') ...[
              const SizedBox(height: 32),
              const Text(
                'DETALLES DE RESOLUCIÓN',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (widget.order.incidentReason != null)
                _buildInfoRow(Icons.warning, 'Motivo de Incidencia', widget.order.incidentReason!),
              if (widget.order.deliveryTime != null)
                _buildInfoRow(Icons.access_time_filled, 'Hora de Resolución', widget.order.deliveryTime!.toLocal().toString().split('.')[0]),
              if (widget.order.signaturePath != null)
                _buildInfoRow(Icons.draw, 'Firma Digital', 'Firma guardada en dispositivo'),
              if (widget.order.evidencePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Evidencia Fotográfica', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Image.file(File(widget.order.evidencePath!), height: 150, fit: BoxFit.cover),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.location_on, 'Dirección', widget.order.address),
            _buildInfoRow(Icons.access_time, 'Ventana Horaria', widget.order.timeWindow),
            _buildInfoRow(Icons.inventory, 'Tipo de Carga', widget.order.loadType),
            _buildInfoRow(Icons.monitor_weight, 'Peso', '${widget.order.weight} kg'),
            _buildInfoRow(Icons.straighten, 'Dimensiones', '${widget.order.height}x${widget.order.length}x${widget.order.width} cm'),
            if (widget.isAdmin) ...[
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'RUT Cliente', widget.order.clientId),
              _buildInfoRow(Icons.local_shipping, 'Conductor Asignado', widget.order.driverId ?? 'No asignado'),
              _buildInfoRow(Icons.calendar_today, 'Fecha Programada', '${widget.order.scheduledDate.day}/${widget.order.scheduledDate.month}/${widget.order.scheduledDate.year}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // RNF9: Image quality and dimensions to keep size < 500KB
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // High compression
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (photo != null) {
      setState(() {
        _capturedImage = File(photo.path);
      });
    }
  }

  void _updateStatus(String status, {String? signaturePath, String? evidencePath, String? incidentReason}) {
    context.read<OrderProvider>().updateOrderStatus(
      widget.order.id!, 
      status,
      signaturePath: signaturePath,
      evidencePath: evidencePath,
      incidentReason: incidentReason,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido actualizado: $status')),
    );
    Navigator.pop(context);
  }

  void _showSignatureDialog(String status) {
    // Reset image for this flow
    _capturedImage = null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Firma Digital de Recepción'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.maxFinite,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _signatureController.clear(),
                    icon: const Icon(Icons.clear),
                    label: const Text('LIMPIAR'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await _pickImage();
                      setDialogState(() {}); // Refresh dialog UI
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_capturedImage == null ? 'AÑADIR FOTO' : 'FOTO CAPTURADA'),
                  ),
                ],
              ),
              if (_capturedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.file(_capturedImage!, height: 80, fit: BoxFit.cover),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (_signatureController.isNotEmpty) {
                final path = _capturedImage?.path;
                Navigator.pop(context);
                _updateStatus(status, 
                  signaturePath: 'simulated_path/signature.png',
                  evidencePath: path,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La firma es obligatoria (RF9)')),
                );
              }
            },
            child: const Text('CONFIRMAR ENTREGA'),
          ),
        ],
      ),
    );
  }

  void _showIncidentDialog() {
    _capturedImage = null;
    _selectedIncidentReason = null;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reportar Incidencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  hint: const Text('Seleccionar motivo'),
                  value: _selectedIncidentReason,
                  items: _incidentReasons.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => _selectedIncidentReason = val),
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
                const SizedBox(height: 24),
                if (_capturedImage == null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _pickImage();
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('CAPTURAR FOTO (OBLIGATORIO)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  )
                else
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_capturedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await _pickImage();
                          setDialogState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('REPETIR FOTO'),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                const Text(
                  'RF10: El registro de incidencia requiere una fotografía obligatoria.',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: (_selectedIncidentReason == null || _capturedImage == null)
                  ? null
                  : () {
                      final path = _capturedImage!.path;
                      final reason = _selectedIncidentReason;
                      Navigator.pop(context);
                      _updateStatus(
                        'Incidencia',
                        incidentReason: reason,
                        evidencePath: path,
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
              child: const Text('REPORTAR'),
            ),
          ],
        ),
      ),
    );
  }
}
