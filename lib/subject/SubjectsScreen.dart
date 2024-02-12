import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finkiaid/repository/SubjectsRepository.dart';
import 'package:flutter/material.dart';

import '../ExternalLinks.dart';
import 'SubjectDetailScreen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();

    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    final repository = SubjectsRepository();
    await repository.checkSubjectsInDatabase();
    setState(() {
      subjects = repository.subjects;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('All Subjects'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search subject...',
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
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          //todo cel object da se prakja??
                          builder: (context) => SubjectDetailScreen(subject),
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text('${++index}: $subject'),
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
