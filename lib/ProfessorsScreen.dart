import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

import 'ExternalLinks.dart';

class Professor {
  final String fullName;
  final String photoUrl;

  const Professor({required this.fullName, required this.photoUrl});
}

class ProfessorsScreen extends StatefulWidget {
  const ProfessorsScreen({super.key});

  @override
  State<ProfessorsScreen> createState() => _ProfessorsScreenState();
}

class _ProfessorsScreenState extends State<ProfessorsScreen> {

  List<Professor> professors = [];

  @override
  void initState() {
    super.initState();

    getAllProfessors();
  }

  Future<void> getAllProfessors() async {
    final url =
        Uri.parse(Links.PROFESSORS_LINK);
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

    setState(() {
      professors = List.generate(
          allProfessorsFullNames.length,
              (index) => Professor(
                  fullName: allProfessorsFullNames[index].toString(),
                  photoUrl: allProfessorsImageUrls[index].toString()
              )
      );
    });
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All professors'),
      ),
      body:
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search professor...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Implement search functionality here
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: professors.length,
                  itemBuilder: (context, index) {
                    final professor = professors[index];

                    return ListTile(
                      leading: Image.network(
                        professor.photoUrl,
                        width: 50,
                      ),
                      title: Text(professor.fullName),
                    );
                  },
                ),
              ),
            ],
          )
    );
  }
}
