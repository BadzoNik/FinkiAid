import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

import '../ExternalLinks.dart';

import 'package:finkiaid/model/Subject.dart';
import 'package:finkiaid/repository/SubjectsRepository.dart';
import 'SubjectDetailScreen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> subjects = [];
  List<Subject> filteredSubjects = [];

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

  void filterSubjects(String query) {
    setState(() {
      filteredSubjects = subjects
          .where((subject) =>
          subject.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Subjects'),
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
                hintText: 'Search subject...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filterSubjects,
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
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredSubjects.isEmpty
                    ? subjects.length
                    : filteredSubjects.length,
                itemBuilder: (context, index) {
                  final subject = filteredSubjects.isEmpty
                      ? subjects[index]
                      : filteredSubjects[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // todo cel object da se prakja??
                          builder: (context) =>
                              SubjectDetailScreen(subject: subject,
                                callerIsFavoriteSubjects: false,),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        title: Text('${++index}: ${subject.name}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}