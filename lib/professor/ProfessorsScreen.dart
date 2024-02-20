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
          .where((professor) =>
          professor.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Professors'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.cyan.shade200, Colors.cyan.shade200],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Professor...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: filterProfessors,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.cyan.shade200, Colors.blue.shade500],
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filteredProfessors.isEmpty
                    ? professors.length
                    : filteredProfessors.length,
                itemBuilder: (context, index) {
                  final professor = filteredProfessors.isEmpty
                      ? professors[index]
                      : filteredProfessors[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfessorDetailScreen(professor),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            professor.photoUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          professor.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          professor.fullName,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 8);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}