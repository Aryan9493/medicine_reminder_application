import 'package:hive_flutter/hive_flutter.dart';
import 'medicine_model.dart';

class MedicineStorage {
  static const String _boxName = 'medicines';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicineAdapter());
    await Hive.openBox<Medicine>(_boxName);
  }

  Box<Medicine> get _box => Hive.box<Medicine>(_boxName);

  List<Medicine> getAllMedicines() {
    return _box.values.toList();
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _box.put(medicine.id, medicine);
  }

  Future<void> deleteMedicine(String id) async {
    await _box.delete(id);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _box.put(medicine.id, medicine);
  }
}
