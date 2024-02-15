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
        final List<dynamic> ratingsData = data['ratings'];
        final List<int> ratings = ratingsData.map((dynamic rating) => rating as int).toList();
        final List<dynamic> commentsData = data['comments'];
        final List<String> comments = commentsData.map((dynamic comment) => comment as String).toList();
        return Professor(
          id: doc.id,
          fullName: data['fullName'],
          photoUrl: data['photoUrl'],
          ratings: ratings,
          comments: comments,
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
            (index) {
          final professorRef = FirebaseFirestore.instance.collection('professors').doc();
          return Professor(
            id: professorRef.id,
            fullName: allProfessorsFullNames[index].toString(),
            photoUrl: allProfessorsImageUrls[index].toString(),
            ratings:  <int>[],
            comments: <String>[],
          );
        }
    );


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
        'ratings': professor.ratings,
        'comments': professor.comments,
        'id': professor.id,
      });
    }
    await batch.commit();
  }
}
