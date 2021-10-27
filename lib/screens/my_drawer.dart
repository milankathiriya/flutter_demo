import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatefulWidget {
  UserCredential? userCredential;

  MyDrawer({this.userCredential});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(
                  widget.userCredential!.user!.photoURL.toString()),
            ),
            padding: const EdgeInsets.all(20),
          ),
          Text(
            "Name: ${widget.userCredential!.user!.displayName}",
          ),
          Text(
            "Email: ${widget.userCredential!.user!.email}",
          ),
        ],
      ),
    );
  }
}
