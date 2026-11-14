class AssessmentHistory {
  final int idAssessment;
  final String tanggal;
  final String gejala;
  final String kondisi;
  final double suhuTubuh;
  final String namaJemaah;
  final int usia;
  final String jenisKelamin;
  final String tingkatRisiko;
  final double probabilitas;
  final String batuk;
  final String sesakNapas;
  final String riwayatPenyakit;
  final String lainnya;
  final String rekomendasi;
  final String noHp;

  AssessmentHistory({
    required this.idAssessment,
    required this.tanggal,
    required this.gejala,
    required this.kondisi,
    required this.suhuTubuh,
    required this.namaJemaah,
    required this.usia,
    required this.jenisKelamin,
    required this.tingkatRisiko,
    required this.probabilitas,
    required this.batuk,
    required this.sesakNapas,
    required this.riwayatPenyakit,
    required this.lainnya,
    required this.rekomendasi,
    required this.noHp,
  });

  factory AssessmentHistory.fromJson(Map<String, dynamic> json) {
    return AssessmentHistory(
      idAssessment: json['id_assessment'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      gejala: json['gejala'] ?? '',
      kondisi: json['kondisi'] ?? '',
      suhuTubuh: (json['suhu_tubuh'] as num?)?.toDouble() ?? 0.0,
      namaJemaah: json['nama_jemaah'] ?? '',
      usia: json['usia'] ?? 0,
      jenisKelamin: json['jenis_kelamin'] ?? '',
      tingkatRisiko: json['tingkat_risiko'] ?? '',
      probabilitas: (json['probabilitas'] as num?)?.toDouble() ?? 0.0,
      batuk: json['batuk'] ?? 'Tidak',
      sesakNapas: json['sesak_napas'] ?? 'Tidak',
      riwayatPenyakit: json['riwayat_penyakit'] ?? 'Tidak Ada',
      lainnya: json['lainnya'] ?? 'Tidak Ada',
      rekomendasi: json['rekomendasi'] ?? 'Tidak ada rekomendasi tercatat.',
      noHp: json['no_hp'] ?? '',
    );
  }
}
