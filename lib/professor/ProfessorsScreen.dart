import 'package:finkiaid/repository/ProfessorsRepository.dart';
import 'package:flutter/material.dart';
import '../model/Professor.dart';
import 'ProfessorDetailScreen.dart';



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
    fetchProfessors();
  }

  Future<void> fetchProfessors() async {
    final repository = ProfessorsRepository();
    await repository.checkProfessorsInDatabase();
    setState(() {
      professors = repository.professors;
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
