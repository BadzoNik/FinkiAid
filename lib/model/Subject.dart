enum MidTermTypeImage { first, second }

enum ExamSessionTypeImage { january, june, august }

class Subject {
  final String id;
  final String name;
  final Map<dynamic, List<String>> images;
  final List<String> comments;

  Subject(
      {required this.id,
      required this.name,
      required this.images,
      required this.comments});
}
