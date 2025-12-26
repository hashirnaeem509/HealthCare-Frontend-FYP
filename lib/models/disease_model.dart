class Disease {
  final int id;
  final String diseaseName;

  Disease({required this.id, required this.diseaseName});

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'],
      diseaseName: json['diseaseName'],
    );
  }
}
