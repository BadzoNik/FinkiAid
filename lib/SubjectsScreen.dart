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

  @override
  void initState() {
    super.initState();

    getAllSubjects();
  }

  Future<void> getAllSubjects() async {
    final url = Uri.parse(Links.SUBJECTS_LINK);
    final response = await http.get(url);
    dom.Document html = dom.Document.html(response.body);

    final specificTrElements = html.querySelectorAll('#\31 059818312 > div > table > tbody > tr:nth-child(3)');

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

    setState(() {
      subjects = List.generate(
          allSubjects.length,
              (index) => allSubjects[index].toString()
      );
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

                  return ListTile(
                    title: Text('${++index}: $subject'),
                  );
                },
              ),
            ),
          ],
        )
    );
  }
}
