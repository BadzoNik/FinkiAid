enum MidTermTypeImage { first, second }

enum ExamSessionTypeImage { january, june, august }

class Subject {
  final String id;
  final String name;
  Map<dynamic, List<dynamic>> images;
  final List<String> comments;

  Subject(
      {required this.id,
      required this.name,
      required this.images,
      required this.comments});

  void setImages(Map<dynamic, List<dynamic>> newImages) {
    images = newImages;
  }
}
