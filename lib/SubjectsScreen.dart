import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

import 'ExternalLinks.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<String> subjects = [];
  List<String> filteredSubjects = [];

  @override
  void initState() {
    super.initState();
    getAllSubjects();
  }

  Future<void> getAllSubjects() async {
    final url = Uri.parse(Links.SUBJECTS_LINK);
    final response = await http.get(url);
    dom.Document html = dom.Document.html(response.body);

    final specificTrElements =
    html.querySelectorAll('#\31 059818312 > div > table > tbody > tr:nth-child(3)');

    final allSubjects = specificTrElements
        .map((trElement) => trElement.querySelector('td.s3')?.innerHtml?.trim())
        .where((subject) => subject != null)
        .toSet()
        .toList();

    allSubjects.sort((a, b) => a?.compareTo(b!) ?? 0);

    setState(() {
      subjects = List.generate(
        allSubjects.length,
            (index) => allSubjects[index].toString(),
      );
      filteredSubjects = List.from(subjects);
    });
  }

  void filterSubjects(String query) {
    setState(() {
      filteredSubjects = subjects
          .where((subject) => subject.toLowerCase().contains(query.toLowerCase()))
          .toList();
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
              onChanged: filterSubjects,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredSubjects.length,
              itemBuilder: (context, index) {
                final subject = filteredSubjects[index];

                return ListTile(
                  title: Text('${++index}: $subject'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
