enum StudentStatus { boarded, pending, alert }

class Student {
  final String id;
  final String name;
  final String grade;
  final String seat;
  final String photoUrl;
  StudentStatus status;
  final String stopName;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.seat,
    required this.photoUrl,
    required this.status,
    required this.stopName,
  });
}
