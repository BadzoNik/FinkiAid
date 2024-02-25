import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Notifications {
  static void showPopUpMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 16),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 1, // Limit to a single line
              ),
            ),
          ],
        ),
      ),
    );
  }
}
