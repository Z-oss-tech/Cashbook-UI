import 'package:flutter/material.dart';

import '../models/people_model.dart';

class PersonProvider extends ChangeNotifier {

  final List<PersonModel> _people = [
    PersonModel(
      id: 'person_1',
      name: 'Amit Sharma',
      phone: '9876543210',
      balance: 2500.0,
    ),
    PersonModel(
      id: 'person_2',
      name: 'Rahul Traders',
      phone: '9876543211',
      balance: -1200.0,
    ),
    PersonModel(
      id: 'person_3',
      name: 'Ramesh Store',
      phone: '9876543212',
      balance: 4000.0,
    ),
    PersonModel(
      id: 'person_4',
      name: 'Vikas Electronics',
      phone: '9876543213',
      balance: -850.0,
    ),
    PersonModel(
      id: 'person_5',
      name: 'Rahul Verma',
      phone: '9876543214',
      balance: -1200.0,
    ),
    PersonModel(
      id: 'person_6',
      name: 'Ali Khan',
      phone: '9876543215',
      balance: 4000.0,
    ),
    PersonModel(
      id: 'person_7',
      name: 'Priya Patel',
      phone: '9876543216',
      balance: -850.0,
    ),
  ];

  List<PersonModel> get people => _people;

  // Add Person
  void addPerson(PersonModel person) {
    _people.add(person);
    notifyListeners();
  }

  // Delete Person
  void deletePerson(String id) {
    _people.removeWhere(
          (person) => person.id == id,
    );

    notifyListeners();
  }

  // Update Person
  void updatePerson(
      String id,
      PersonModel updatedPerson,
      ) {
    final index = _people.indexWhere(
          (person) => person.id == id,
    );

    if (index != -1) {
      _people[index] = updatedPerson;
      notifyListeners();
    }
  }

  // Get Person By ID
  PersonModel? getPersonById(String id) {
    try {
      return _people.firstWhere(
            (person) => person.id == id,
      );
    } catch (e) {
      return null;
    }
  }
}