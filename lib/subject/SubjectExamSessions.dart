
import 'package:finkiaid/model/Subject.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SubjectExamSessions extends StatelessWidget {
  final Subject subject;

  const SubjectExamSessions(this.subject, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
      ),
      body:  Row(
        children: [
          TextButton(
              onPressed:() {

              },
              child: const Text('Browse Image')
          ),
          TextButton(
              onPressed:() {

              },
              child: const Text('Take photo')
          ),
        ],
      ),
    );
  }
}
