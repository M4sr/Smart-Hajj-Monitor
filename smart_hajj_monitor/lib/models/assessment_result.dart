class AssessmentResult {
  final int idHasil;
  final String tingkatRisiko;
  final double probabilitas;
  final String rekomendasi;
  final String timestamp;

  AssessmentResult({
    required this.idHasil,
    required this.tingkatRisiko,
    required this.probabilitas,
    required this.rekomendasi,
    required this.timestamp,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      idHasil: json['id_hasil'] ?? 0,
      tingkatRisiko: json['tingkat_risiko'] ?? '',
      probabilitas: (json['probabilitas'] ?? 0.0).toDouble(),
      rekomendasi: json['rekomendasi'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
