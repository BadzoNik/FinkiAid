import 'package:finkiaid/model/Subject.dart';
import 'package:flutter/material.dart';

import 'SubjectExamSessions.dart';
import 'SubjectMidTerms.dart';
import 'SubjectReviews.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen(this.subject, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectMidTerms(subject),
                    )
                  );
                },
                child: const Text('Mid-Terms')
            ),
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectExamSessions(subject),
                      )
                  );
                },
                child: const Text('Exam-Sessions')
            ),
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectReviews(subject),
                      )
                  );
                },
                child: const Text('View Comments')
            )
          ],
        ),
      ),
    );
  }
}

