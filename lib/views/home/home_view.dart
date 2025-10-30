import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
  height: MediaQuery.of(context).size.height * 0.48,
  width: double.infinity,
            color: Colors.red,
          )
        ],
      )
    );
  }
}
