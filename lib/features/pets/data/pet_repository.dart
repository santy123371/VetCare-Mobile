import 'dart:io';
import 'package:dio/dio.dart';

import '../../../shared/models/pet.dart';
import '../../../shared/models/client_owner.dart';

class PetRepository {
  PetRepository(this._dio);
  final Dio _dio;

  Future<List<Pet>> list({String? ownerId}) async {
    final res = await _dio.get('/mascotas', queryParameters: {
      if (ownerId != null) 'id_propietario': ownerId,
    });
    final data = res.data['data'] ?? res.data;
    final items = (data is List) ? data : (data['items'] ?? data['mascotas'] ?? []);
    return (items as List).map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ClientOwner>> listOwners() async {
    final res = await _dio.get('/usuarios', queryParameters: {
      'activo': 'true',
    });
    final data = res.data['data'] ?? res.data;
    final items = (data is List) ? data : (data['items'] ?? data['usuarios'] ?? []);
    return (items as List)
        .map((e) => ClientOwner.fromJson(e as Map<String, dynamic>))
        .where((c) => c.id.isNotEmpty && c.nombre.isNotEmpty)
        .toList();
  }

  Future<Pet> get(String id) async {
    final res = await _dio.get('/mascotas/$id');
    final data = res.data['data'] ?? res.data;
    return Pet.fromJson(data as Map<String, dynamic>);
  }

  Future<Pet> create(Pet pet) async {
    final res = await _dio.post('/mascotas', data: pet.toJson());
    final data = res.data['data'] ?? res.data;
    return Pet.fromJson(data as Map<String, dynamic>);
  }

  Future<Pet> update(String id, Pet pet) async {
    final res = await _dio.put('/mascotas/$id', data: pet.toJson());
    final data = res.data['data'] ?? res.data;
    return Pet.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/mascotas/$id');
  }

  Future<String> uploadImage(File file, {String? petId}) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      if (petId != null && petId.isNotEmpty) 'mascota_id': petId,
      'imagen': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final endpoint = petId != null && petId.isNotEmpty
        ? '/mascotas/$petId/upload-image'
        : '/mascotas/upload-image';

    final res = await _dio.post(
      endpoint,
      data: formData,
    );
    final data = res.data['data'] ?? res.data;
    return (data['imagen'] ?? data['path'] ?? '') as String;
  }
}