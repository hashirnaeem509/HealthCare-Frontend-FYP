class VitalRecord {
    final int obsVId;
  final String vitalName;
  final String date;
  final String time;
  final dynamic value;
  final String vitalTypeName;
    final bool isCritical;

  VitalRecord({
        required this.obsVId,
    required this.vitalName,
    required this.date,
    required this.time,
    required this.value,
    required this.vitalTypeName,
        required this.isCritical,
  });

  factory VitalRecord.fromJson(Map<String, dynamic> json) {
    return VitalRecord(
       obsVId: json['obsVId'],
      vitalName: json['vitalName']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      value: json['value'],
      vitalTypeName: json['vitalTypeName']?.toString() ?? '',
       isCritical: json['isCritical'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vitalName': vitalName,
      'date': date,
      'time': time,
      'value': value,
      'vitalTypeName': vitalTypeName,
    };
  }
}
