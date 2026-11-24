import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vetcare_mobile/shared/models/pet.dart';
import 'package:vetcare_mobile/shared/models/client_owner.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://veterinaria.santiagod.dpdns.org/api/v1\n',
    );
  });

  group('Pet Model', () {
    test('fromJson parses owner and photo attributes correctly', () {
      final json = {
        'id': '10',
        'nombre': 'Firulais',
        'especie': 'Perro',
        'raza': 'Labrador',
        'foto': 'uploads/mascotas/firulais.jpg',
        'id_propietario': '5',
        'nombre_propietario': 'Carlos Gómez',
      };

      final pet = Pet.fromJson(json);

      expect(pet.id, '10');
      expect(pet.nombre, 'Firulais');
      expect(pet.especie, 'Perro');
      expect(pet.raza, 'Labrador');
      expect(pet.foto, 'uploads/mascotas/firulais.jpg');
      expect(pet.idPropietario, '5');
      expect(pet.nombrePropietario, 'Carlos Gómez');
      expect(pet.fullImageUrl, 'https://veterinaria.santiagod.dpdns.org/uploads/mascotas/firulais.jpg');
    });

    test('toJson serializes id_propietario and image fields for backend compatibility', () {
      const pet = Pet(
        id: '10',
        nombre: 'Mimi',
        especie: 'Gato',
        foto: 'uploads/mascotas/mimi.png',
        idPropietario: '7',
      );

      final json = pet.toJson();

      expect(json['nombre'], 'Mimi');
      expect(json['especie'], 'Gato');
      expect(json['id_propietario'], '7');
      expect(json['foto'], 'uploads/mascotas/mimi.png');
      expect(json['imagen'], 'uploads/mascotas/mimi.png');
    });
  });

  group('ClientOwner Model', () {
    test('fromJson and displayName format correctly', () {
      final json = {
        'id': '7',
        'nombre': 'Ana',
        'apellido': 'Martínez',
        'email': 'ana@test.com',
        'documento': '12345678',
      };

      final owner = ClientOwner.fromJson(json);

      expect(owner.id, '7');
      expect(owner.fullName, 'Ana Martínez');
      expect(owner.displayName, 'Ana Martínez · Doc: 12345678');
    });
  });
}
