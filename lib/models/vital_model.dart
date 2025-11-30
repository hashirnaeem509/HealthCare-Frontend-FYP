class VitalRecord {
  final String vitalName;
  final String date;
  final String time;
  final dynamic value;
  final String vitalTypeName;

  VitalRecord({
    required this.vitalName,
    required this.date,
    required this.time,
    required this.value,
    required this.vitalTypeName,
  });

  factory VitalRecord.fromJson(Map<String, dynamic> json) {
    return VitalRecord(
      vitalName: json['vitalName']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      value: json['value'],
      vitalTypeName: json['vitalTypeName']?.toString() ?? '',
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
