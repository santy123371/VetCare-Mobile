import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PetSpeciesHelper {
  static (String emoji, List<Color> colors) getStyle(String especie) {
    final lower = especie.trim().toLowerCase();
    if (lower.contains('can') || lower.contains('perro') || lower.contains('dog')) {
      return ('🐶', const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]);
    } else if (lower.contains('fel') || lower.contains('gato') || lower.contains('cat')) {
      return ('🐱', const [Color(0xFFF59E0B), Color(0xFFD97706)]);
    } else if (lower.contains('ave') || lower.contains('pajaro') || lower.contains('bird')) {
      return ('🦜', const [Color(0xFF10B981), Color(0xFF047857)]);
    } else if (lower.contains('conejo') || lower.contains('rabbit')) {
      return ('🐰', const [Color(0xFFEC4899), Color(0xFFBE185D)]);
    } else if (lower.contains('hamster') || lower.contains('hámster')) {
      return ('🐹', const [Color(0xFF8B5CF6), Color(0xFF6D28D9)]);
    }
    return ('🐾', const [Color(0xFF6366F1), Color(0xFF4F46E5)]);
  }
}

class Pet {
  final String id;
  final String nombre;
  final String especie;
  final String? raza;
  final String? sexo;
  final String? edad;
  final String? fechaNacimiento;
  final double? peso;
  final String? foto;
  final String? idPropietario;

  const Pet({
    required this.id,
    required this.nombre,
    required this.especie,
    this.raza,
    this.sexo,
    this.edad,
    this.fechaNacimiento,
    this.peso,
    this.foto,
    this.idPropietario,
  });

  String? get fullImageUrl {
    if (foto == null || foto!.trim().isEmpty) return null;
    final cleanPath = foto!.trim().replaceAll(r'\', '/');
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    final baseUrl = (dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null) ??
        'https://lenders-med-surfaces-robbie.trycloudflare.com/veterinaria_php/api/v1';
    final hostUrl = baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return '$hostUrl/${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';
  }

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        id: (j['id'] ?? j['id_mas'] ?? '').toString(),
        nombre: (j['nombre'] ?? j['nom_mas'] ?? '').toString(),
        especie: (j['especie'] ?? j['esp_mas'] ?? '').toString(),
        raza: j['raza']?.toString() ?? j['raz_mas']?.toString(),
        sexo: j['sexo']?.toString() ?? j['sex_mas']?.toString(),
        edad: j['edad']?.toString() ?? j['ed_mas']?.toString(),
        fechaNacimiento: j['fecha_nacimiento']?.toString() ?? j['fec_nac_mas']?.toString(),
        peso: (j['peso'] is num) ? (j['peso'] as num).toDouble() : null,
        foto: j['foto']?.toString() ?? j['fot_mas']?.toString() ?? j['imagen']?.toString() ?? j['img_mas']?.toString(),
        idPropietario: (j['id_propietario'] ?? j['id_prop_mas'])?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'especie': especie,
        if (raza != null) 'raza': raza,
        if (sexo != null) 'sexo': sexo,
        if (edad != null) 'edad': edad,
        if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
        if (peso != null) 'peso': peso,
      };
}
