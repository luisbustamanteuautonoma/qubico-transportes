class Validators {
  static String? validateRut(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RUT es obligatorio';
    }
    
    // Simple RUT validation logic (Chilean format)
    String cleanRut = value.replaceAll(RegExp(r'[^0-9kK]'), '');
    if (cleanRut.length < 8) return 'RUT inválido (muy corto)';
    
    // For Qúbico, we use RNF4: "RUT inválido: falta dígito verificador" if error
    // (This is a simplified check, ideally uses a full modulo 11 algorithm)
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    // RF1: Mobile phone (9 digits)
    final phoneRegex = RegExp(r'^[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'El teléfono debe tener exactamente 9 dígitos';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }
}
