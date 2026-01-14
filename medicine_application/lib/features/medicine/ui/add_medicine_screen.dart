import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/medicine_model.dart';
import '../logic/medicine_provider.dart';
import '../../../../app/theme.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  final Medicine? medicine;
  const AddMedicineScreen({super.key, this.medicine});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  DateTime? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _doseController.text = widget.medicine!.dose;
      _selectedTime = widget.medicine!.time;
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.tealPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      final now = DateTime.now();
      setState(() {
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _saveMedicine() {
    if (_formKey.currentState!.validate() && _selectedTime != null) {
      if (widget.medicine != null) {
        final updatedMedicine = widget.medicine!.copyWith(
          name: _nameController.text.trim(),
          dose: _doseController.text.trim(),
          time: _selectedTime!,
        );
        ref
            .read(medicineNotifierProvider.notifier)
            .updateMedicine(updatedMedicine);
        _showSuccessDialog(updatedMedicine.name, isEdit: true);
      } else {
        final medicine = Medicine(
          name: _nameController.text.trim(),
          dose: _doseController.text.trim(),
          time: _selectedTime!,
        );
        ref.read(medicineNotifierProvider.notifier).addMedicine(medicine);
        _showSuccessDialog(medicine.name, isEdit: false);
      }
    }
  }

  void _showSuccessDialog(String name, {required bool isEdit}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Success!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isEdit
                  ? '$name updated successfully!'
                  : '$name added successfully!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid =
        _nameController.text.isNotEmpty &&
        _doseController.text.isNotEmpty &&
        _selectedTime != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildForm(isValid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.tealGradient),
        ),
        title: Text(
          widget.medicine != null ? 'Edit Medicine' : 'Add Medicine',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildForm(bool isValid) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Medicine Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.tealDark,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                  hintText: 'e.g. Aspirin',
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter medicine name'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _doseController,
                decoration: const InputDecoration(
                  labelText: 'Dose',
                  prefixIcon: Icon(Icons.scale),
                  hintText: 'e.g. 1 Tablet, 5ml',
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter dose'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        color: _selectedTime == null
                            ? Colors.grey
                            : AppTheme.tealPrimary,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder Time',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _selectedTime == null
                                ? 'Set Reminder Time'
                                : DateFormat.jm().format(_selectedTime!),
                            style: TextStyle(
                              color: _selectedTime == null
                                  ? Colors.grey
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: _selectedTime == null
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: isValid ? AppTheme.orangeGradient : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isValid
                      ? [
                          BoxShadow(
                            color: AppTheme.orangeAccent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: isValid ? _saveMedicine : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Medicine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
