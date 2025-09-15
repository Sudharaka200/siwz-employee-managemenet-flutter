import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AttendanceCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final bool isActive;

  const AttendanceCard({
    Key? key,
    required this.title,
    required this.time,
    required this.icon,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : AppTheme.primaryBlue,
            size: 30,
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.white.withOpacity(0.8) : Colors.grey[600],
            ),
          ),
          SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
