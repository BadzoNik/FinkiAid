import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import '../ExternalLinks.dart';
import '../model/Subject.dart';

class SubjectsRepository {
  List<Subject> subjects = [];

  Future<void> checkSubjectsInDatabase() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('subjects').get();
    if (snapshot.docs.isNotEmpty) {
      subjects = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final Map<String, dynamic> imagesData = data["images"] ?? [];
        final Map<String, List<String>> images = imagesData.map((key, value) {
          if (value is List<String>) {
            return MapEntry(key, value);
          } else if (value is List<dynamic>) {
            return MapEntry(key, value.cast<String>());
          }
          return MapEntry(key, []);
        });
        final List<String> comments = List<String>.from(data['comments'] ?? []);
        return Subject(
          id: doc.id,
          name: data['name'].toString(),
          images: images,
          comments: comments,
        );
      }).toList();
    } else {
      await fetchSubjectsFromApi();
    }
  }

  Future<void> fetchSubjectsFromApi() async {
    final url = Uri.parse(Links.SUBJECTS_LINK);
    final response = await http.get(url);
    dom.Document html = dom.Document.html(response.body);

    final specificTrElements = html.querySelectorAll(
        '#\31 059818312 > div > table > tbody > tr:nth-child(3)');

    final allSubjects = specificTrElements
        .map((trElement) => trElement.querySelector('td.s3')?.innerHtml?.trim())
        .where((subject) => subject != null)
        .toSet()
        .toList();


    subjects = List.generate(
      allSubjects.length,
          (index) {
        final subjectRef = FirebaseFirestore.instance.collection('subjects').doc();
        return Subject(
          id: subjectRef.id,
          name: allSubjects[index].toString(),
          images: {},
          comments: [],
        );
      },
    );

    subjects.sort((a, b) {
      if (a == null && b == null) {
        return 0;
      } else if (a == null) {
        return 1;
      } else if (b == null) {
        return -1;
      } else {
        return a.name.compareTo(b.name);
      }
    });

    await storeSubjectsInDatabase();
  }

  Future<void> storeSubjectsInDatabase() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final subject in subjects) {
      final subjectRef =
      FirebaseFirestore.instance.collection('subjects').doc(subject.id);
      batch.set(subjectRef, {
        'id': subjectRef.id,
        'name': subject.name,
        'images': subject.images,
        'comments': subject.comments,
      });
    }
    await batch.commit();
  }
}
