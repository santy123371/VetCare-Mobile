class ClientOwner {
  final String id;
  final String nombre;
  final String? apellido;
  final String? email;
  final String? documento;

  const ClientOwner({
    required this.id,
    required this.nombre,
    this.apellido,
    this.email,
    this.documento,
  });

  String get fullName {
    final ape = apellido?.trim() ?? '';
    return ape.isNotEmpty ? '$nombre $ape' : nombre;
  }

  String get displayName {
    final doc = documento?.trim() ?? '';
    return doc.isNotEmpty ? '$fullName · Doc: $doc' : fullName;
  }

  factory ClientOwner.fromJson(Map<String, dynamic> j) {
    return ClientOwner(
      id: (j['id'] ?? j['id_usu'] ?? '').toString(),
      nombre: (j['nombre'] ?? j['nom_usu'] ?? '').toString(),
      apellido: j['apellido']?.toString() ?? j['ape_usu']?.toString(),
      email: j['email']?.toString() ?? j['correo']?.toString(),
      documento: j['documento']?.toString() ?? j['doc_usu']?.toString(),
    );
  }
}
