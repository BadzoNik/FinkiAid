import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import '../ExternalLinks.dart';

class SubjectsRepository {
  List<String> subjects = [];

  Future<void> checkSubjectsInDatabase() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('subjects').get();
    if (snapshot.docs.isNotEmpty) {
      subjects = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'].toString();
      }).toList();
    } else {
      fetchSubjectsFromApi();
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

    allSubjects.sort((a, b) {
      if (a == null && b == null) {
        return 0;
      } else if (a == null) {
        return 1;
      } else if (b == null) {
        return -1;
      } else {
        return a.compareTo(b);
      }
    });

    subjects = List.generate(
        allSubjects.length, (index) => allSubjects[index].toString());

    await storeSubjectsInDatabase();
  }

  Future<void> storeSubjectsInDatabase() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final subject in subjects) {
      final subjectRef =
          FirebaseFirestore.instance.collection('subjects').doc();
      batch.set(subjectRef, {'name': subject});
    }
    await batch.commit();
  }
}
