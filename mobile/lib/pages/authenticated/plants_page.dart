import 'package:flutter/material.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Plants Page'),
      ),
    );
  }
}