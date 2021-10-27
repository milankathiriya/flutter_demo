import 'package:firebase_6_pm_app/models/student_model.dart';
import 'package:firebase_database/firebase_database.dart';

class RTDBHelper {
  static final databaseReference = FirebaseDatabase.instance.reference();

  RTDBHelper._();
  static final RTDBHelper instance = RTDBHelper._();

  insert(Student data) {
    // databaseReference.set(data.toMap());
    // databaseReference.child(name).set(data.toMap());
    // databaseReference.child("students").push().set(data);
    databaseReference.child("students").child("${data.id}").set(data.toMap());
  }

  update(Student data) {
    databaseReference
        .child("students")
        .child("${data.id}")
        .update(data.toMap());
  }

  delete(int id) {
    databaseReference.child("students").child("$id").remove();
  }
}
