class PatientNote {
  final String id;
  final String patientId;
  final String content;
  final DateTime date;
  final String title;

  PatientNote({
    required this.id,
    required this.patientId,
    required this.content,
    required this.date,
    required this.title,
  });
}
