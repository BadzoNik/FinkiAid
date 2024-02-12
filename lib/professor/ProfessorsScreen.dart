import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

import '../ExternalLinks.dart';
import '../model/Professor.dart';
import '../repository/ProfessorsRepository.dart';
import 'ProfessorDetailScreen.dart';



class ProfessorsScreen extends StatefulWidget {
  const ProfessorsScreen({super.key});

  @override
  State<ProfessorsScreen> createState() => _ProfessorsScreenState();
}

class _ProfessorsScreenState extends State<ProfessorsScreen> {

  List<Professor> professors = [];
  List<Professor> filteredProfessors = [];

  @override
  void initState() {
    super.initState();

    fetchProfessors();
  }

  Future<void> fetchProfessors() async {
    final repository = ProfessorsRepository();
    await repository.checkProfessorsInDatabase();
    setState(() {
      professors = repository.professors;
    });
  }

  void filterProfessors(String query) {
    setState(() {
      filteredProfessors = professors
          .where((professor) => professor.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
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
                  onChanged:filterProfessors,
                    // Implement search functionality here
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredProfessors.isEmpty ? professors.length : filteredProfessors.length,
                  itemBuilder: (context, index) {
                    final professor = filteredProfessors.isEmpty ? professors[index] : filteredProfessors[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            //todo cel object da se prakja
                            builder: (context) => ProfessorDetailScreen(professor),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: Image.network(
                          professor.photoUrl,
                          width: 50,
                        ),
                        title: Text(professor.fullName),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
    );
  }
}
