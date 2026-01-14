import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medicine_model.dart';
import '../data/medicine_storage.dart';
import '../../../services/notification_service.dart';

enum MedicineFilter { all, morning, afternoon, evening }

class MedicineState {
  final List<Medicine> medicines;
  final String searchQuery;
  final MedicineFilter selectedFilter;

  MedicineState({
    required this.medicines,
    this.searchQuery = '',
    this.selectedFilter = MedicineFilter.all,
  });

  MedicineState copyWith({
    List<Medicine>? medicines,
    String? searchQuery,
    MedicineFilter? selectedFilter,
  }) {
    return MedicineState(
      medicines: medicines ?? this.medicines,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  List<Medicine> get filteredMedicines {
    return medicines.where((m) {
      final matchesSearch =
          m.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          m.dose.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (selectedFilter != MedicineFilter.all) {
        final hour = m.time.hour;
        if (selectedFilter == MedicineFilter.morning) {
          matchesFilter = hour >= 5 && hour < 12;
        } else if (selectedFilter == MedicineFilter.afternoon) {
          matchesFilter = hour >= 12 && hour < 17;
        } else if (selectedFilter == MedicineFilter.evening) {
          matchesFilter = hour >= 17 || hour < 5;
        }
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get totalCount => medicines.length;
  int get activeTodayCount =>
      medicines.length; // Simplified for this implementation
  int get adherencePercentage => 95; // Placeholder as requested
}

final medicineStorageProvider = Provider((ref) => MedicineStorage());

final medicineNotifierProvider =
    StateNotifierProvider<MedicineNotifier, MedicineState>((ref) {
      final storage = ref.watch(medicineStorageProvider);
      return MedicineNotifier(storage, NotificationService());
    });

class MedicineNotifier extends StateNotifier<MedicineState> {
  final MedicineStorage _storage;
  final NotificationService _notificationService;

  MedicineNotifier(this._storage, this._notificationService)
    : super(MedicineState(medicines: [])) {
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final medicines = _storage.getAllMedicines();
    _sortAndSetState(medicines);
  }

  void _sortAndSetState(List<Medicine> medicines) {
    medicines.sort((a, b) {
      final now = DateTime.now();
      final timeA = DateTime(
        now.year,
        now.month,
        now.day,
        a.time.hour,
        a.time.minute,
      );
      final timeB = DateTime(
        now.year,
        now.month,
        now.day,
        b.time.hour,
        b.time.minute,
      );
      return timeA.compareTo(timeB);
    });
    state = state.copyWith(medicines: medicines);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(MedicineFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _storage.addMedicine(medicine);
    await _notificationService.scheduleNotification(medicine);
    _loadMedicines();
  }

  Future<void> deleteMedicine(String id) async {
    try {
      final medicine = state.medicines.firstWhere((m) => m.id == id);
      await _notificationService.cancelNotification(medicine.notificationId);
    } catch (_) {
      // Medicine already gone or id not found
    }
    await _storage.deleteMedicine(id);
    _loadMedicines();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _storage.updateMedicine(medicine);
    await _notificationService.cancelNotification(medicine.notificationId);
    await _notificationService.scheduleNotification(medicine);
    _loadMedicines();
  }

  Future<void> testNotification(Medicine medicine) async {
    await _notificationService.showInstantNotification(medicine);
  }

  Future<void> snoozeMedicine(Medicine medicine, Duration duration) async {
    // 1. Cancel the main notification (clears tray and stops current schedule)
    await _notificationService.cancelNotification(medicine.notificationId);

    // 2. Reschedule the main recurring notification for tomorrow (so we don't lose the cycle)
    await _notificationService.scheduleNotification(
      medicine,
      forceNextDay: true,
    );

    // 3. Schedule the one-off snooze notification
    await _notificationService.snoozeNotification(medicine, duration);
  }

  Future<void> markMedicineTaken(Medicine medicine) async {
    // 1. Cancel main notification (clears tray)
    await _notificationService.cancelNotification(medicine.notificationId);

    // 2. Cancel any potential snoozed notification (if they snoozed then took it)
    await _notificationService.cancelNotification(
      medicine.notificationId + 5000,
    );

    // 3. Update state to track that it was taken today
    final updatedMedicine = medicine.copyWith(lastTakenDate: DateTime.now());
    await _storage.updateMedicine(updatedMedicine);

    // 4. Re-schedule main notification for tomorrow to ensure continuity
    await _notificationService.scheduleNotification(
      updatedMedicine,
      forceNextDay: true,
    );

    // 5. Refresh UI
    _loadMedicines();
  }
}
