import 'dart:math';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'medicine_model.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String dose;

  @HiveField(3)
  final DateTime time;

  @HiveField(4)
  final int notificationId;

  @HiveField(5)
  final DateTime? lastTakenDate;

  Medicine({
    String? id,
    required this.name,
    required this.dose,
    required this.time,
    int? notificationId,
    this.lastTakenDate,
  }) : id = id ?? const Uuid().v4(),
       notificationId = notificationId ?? Random().nextInt(100000000);

  Medicine copyWith({
    String? name,
    String? dose,
    DateTime? time,
    DateTime? lastTakenDate,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      time: time ?? this.time,
      notificationId: notificationId,
      lastTakenDate: lastTakenDate ?? this.lastTakenDate,
    );
  }
}
