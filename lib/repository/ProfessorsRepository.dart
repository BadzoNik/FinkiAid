import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import '../ExternalLinks.dart';
import '../model/Professor.dart';

class ProfessorsRepository {
  List<Professor> professors = [];

  Future<void> checkProfessorsInDatabase() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('professors').get();
    if (snapshot.docs.isNotEmpty) {
      professors = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Professor(
          fullName: data['fullName'],
          photoUrl: data['photoUrl'],
        );
      }).toList();
    } else {
      fetchProfessorsFromApi();
    }
  }

  Future<void> fetchProfessorsFromApi() async {
    final url = Uri.parse(Links.PROFESSORS_LINK);
    final response = await http.get(url);
    dom.Document html = dom.Document.html(response.body);

    final allProfessorsFullNames = html
        .querySelectorAll('h2 > a')
        .map((element) => element.innerHtml.trim())
        .toList();
    final allProfessorsImageUrls = html
        .querySelectorAll('div > div > div > div > img')
        .map((element) => element.attributes['src']!)
        .toList();

    professors = List.generate(
        allProfessorsFullNames.length,
        (index) => Professor(
            fullName: allProfessorsFullNames[index].toString(),
            photoUrl: allProfessorsImageUrls[index].toString()));

    await storeProfessorsInDatabase();
  }

  Future<void> storeProfessorsInDatabase() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final professor in professors) {
      final professorRef =
          FirebaseFirestore.instance.collection('professors').doc();
      batch.set(professorRef, {
        'fullName': professor.fullName,
        'photoUrl': professor.photoUrl,
      });
    }
    await batch.commit();
  }
}
