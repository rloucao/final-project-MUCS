// create static class StatusUtil
import 'package:flutter/material.dart';

class StatusUtil {

  static Color getStatusColor(dynamic status) {
    switch (status) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static String getStatusText(dynamic status) {
    switch (status) {
      case 1:
        return "Status: Bad";
      case 2:
        return "Status: Okay";
      case 3:
        return "Status: Very Good";
      default:
        return "Status: Unknown";
    }
  }

  static int encodeStatus(String status) {
    switch (status.toLowerCase()) {
      case "dead":
        return 1;
      case "not healthy":
        return 2;
      case "healthy":
        return 3;
      default:
        return 0; // Unknown status
    }
  }
}