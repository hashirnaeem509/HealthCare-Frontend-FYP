class PatientReportSummaryDTO {
  final int reportId;
  final String reportName;
  final String reportDate;
  final String reportTime;

  PatientReportSummaryDTO({
    required this.reportId,
    required this.reportName,
    required this.reportDate,
    required this.reportTime,
  });

  factory PatientReportSummaryDTO.fromJson(Map<String, dynamic> json) {
    return PatientReportSummaryDTO(
      reportId: json['reportId'] is int
          ? json['reportId']
          : int.tryParse(json['reportId']?.toString() ?? '0') ?? 0,
      reportName: json['reportName']?.toString() ?? '',
      reportDate: json['reportDate']?.toString() ?? '',
      reportTime: json['reportTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reportName': reportName,
      'reportDate': reportDate,
      'reportTime': reportTime,
    };
  }
}
