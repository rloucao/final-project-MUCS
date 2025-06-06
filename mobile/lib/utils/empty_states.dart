import 'package:flutter/material.dart';

class EmptyStates {
  static Widget noHotelSelected() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/defaultImage.jpg',
          fit: BoxFit.cover,
        ),
        Container(
          color: Colors.black.withOpacity(0.6),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Text(
              'No hotel selected',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.green,
                    offset: Offset(-1.5, -1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}