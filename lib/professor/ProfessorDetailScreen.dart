import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/Professor.dart';
import 'ProfessorsScreen.dart';

class ProfessorDetailScreen extends StatefulWidget {
  final Professor professor;

  ProfessorDetailScreen(this.professor, {Key? key}) : super(key: key);

  @override
  _ProfessorDetailScreenState createState() => _ProfessorDetailScreenState();
}

class _ProfessorDetailScreenState extends State<ProfessorDetailScreen> {
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.professor.fullName}'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text('Add rating'),
            Center(
              child: Image.network(
                widget.professor.photoUrl.toString(),
                width: 50,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                    (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: index < rating ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                  },
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Add Comment'),
            ),
          ],
        ),
      ),
    );
  }
}
