import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../logic/medicine_provider.dart';
import '../data/medicine_model.dart';
import '../../../../app/theme.dart';
import 'add_medicine_screen.dart';
import 'widgets/notification_preview.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicineNotifierProvider);
    final medicines = state.filteredMedicines;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSearchBar(ref),
            ),
          ),
          SliverToBoxAdapter(child: _buildFilterChips(state, ref)),
          if (medicines.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(state.searchQuery.isNotEmpty),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildMedicineCard(context, ref, medicines[index]),
                  childCount: medicines.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
          );
        },
        label: const Text('Add Medicine'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 40),
        decoration: const BoxDecoration(
          gradient: AppTheme.tealGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Medicines',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stay healthy, stay on track',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNotificationBell(context, ref),
              ],
            ),
            const SizedBox(height: 30),
            _buildStatistics(ref.watch(medicineNotifierProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, WidgetRef ref) {
    final medicines = ref.watch(medicineNotifierProvider).medicines;
    return InkWell(
      onTap: () {
        if (medicines.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) =>
                NotificationPreview(medicine: medicines.first),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No active reminders')));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(Icons.notifications_none, color: AppTheme.tealPrimary),
            if (medicines.isNotEmpty)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(MedicineState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statColumn('Total\nMedicines', '${state.totalCount}'),
          _verticalDivider(),
          _statColumn('Active Today', '${state.activeTodayCount}'),
          _verticalDivider(),
          _statColumn('Adherence', '${state.adherencePercentage}%'),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) =>
            ref.read(medicineNotifierProvider.notifier).setSearchQuery(value),
        decoration: const InputDecoration(
          hintText: 'Search medicines...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilterChips(MedicineState state, WidgetRef ref) {
    final filters = [
      {'label': 'All', 'value': MedicineFilter.all},
      {'label': 'Morning', 'value': MedicineFilter.morning},
      {'label': 'Afternoon', 'value': MedicineFilter.afternoon},
      {'label': 'Evening', 'value': MedicineFilter.evening},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.tune, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = state.selectedFilter == f['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f['label'] as String),
                      selected: isSelected,
                      onSelected: (_) => ref
                          .read(medicineNotifierProvider.notifier)
                          .setFilter(f['value'] as MedicineFilter),
                      selectedColor: AppTheme.tealPrimary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.medication_liquid,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No matches found' : 'No medicines added yet',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
  ) {
    final timeStr = DateFormat.jm().format(medicine.time);
    final hour = medicine.time.hour;

    String timeOfDayStr;
    IconData timeIcon;
    Color timeColor;

    if (hour >= 5 && hour < 12) {
      timeOfDayStr = 'Morning';
      timeIcon = Icons.wb_sunny_outlined;
      timeColor = Colors.orange;
    } else if (hour >= 12 && hour < 17) {
      timeOfDayStr = 'Afternoon';
      timeIcon = Icons.sunny;
      timeColor = Colors.orange.shade700;
    } else {
      timeOfDayStr = 'Evening';
      timeIcon = Icons.nightlight_outlined;
      timeColor = Colors.indigo;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tealPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.medication,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medicine.dose,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _badge(
                        timeStr,
                        Icons.access_time,
                        Colors.teal.shade700,
                        Colors.teal.shade50,
                      ),
                      const SizedBox(width: 8),
                      _badge(
                        timeOfDayStr,
                        timeIcon,
                        timeColor,
                        timeColor.withOpacity(0.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _actionButton(
                  Icons.edit_outlined,
                  Colors.blue.shade700,
                  Colors.blue.shade50,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddMedicineScreen(medicine: medicine),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _actionButton(
                  Icons.notifications_active_outlined,
                  Colors.orange.shade700,
                  Colors.orange.shade50,
                  () => ref
                      .read(medicineNotifierProvider.notifier)
                      .testNotification(medicine),
                ),
                const SizedBox(height: 8),
                _actionButton(
                  Icons.delete_outline,
                  Colors.red.shade700,
                  Colors.red.shade50,
                  () => _showDeleteDialog(context, ref, medicine),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    Color color,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Medicine?'),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(medicineNotifierProvider.notifier)
                  .deleteMedicine(medicine.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
