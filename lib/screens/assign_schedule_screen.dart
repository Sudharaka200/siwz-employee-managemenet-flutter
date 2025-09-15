import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/admin_service.dart';
import '../services/shift_service.dart';

class AssignScheduleScreen extends StatefulWidget {
  @override
  _AssignScheduleScreenState createState() => _AssignScheduleScreenState();
}

class _AssignScheduleScreenState extends State<AssignScheduleScreen> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _shifts = [];
  String? _selectedEmployeeId;
  String? _selectedShiftId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final employees = await AdminService.getEmployees();
      final shifts = await ShiftService.getAllShifts();
      setState(() {
        _employees = employees;
        _shifts = shifts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data for assign schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignShift() async {
    if (_selectedEmployeeId == null || _selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an employee and a shift.')),
      );
      return;
    }

    try {
      final response = await AdminService.assignShiftToEmployee(
        _selectedEmployeeId!,
        _selectedShiftId!,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shift assigned successfully!')),
        );
        Navigator.pop(context); // Go back to admin dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign shift: ${response['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning shift: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Work Schedule'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign a Shift to an Employee',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Employee',
                border: OutlineInputBorder(),
              ),
              value: _selectedEmployeeId,
              items: _employees.map((employee) {
                return DropdownMenuItem<String>(
                  value: employee['_id'],
                  child: Text('${employee['name']} (${employee['employeeId']})'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedEmployeeId = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an employee';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Shift',
                border: OutlineInputBorder(),
              ),
              value: _selectedShiftId,
              items: _shifts.map((shift) {
                return DropdownMenuItem<String>(
                  value: shift['_id'],
                  child: Text('${shift['name']} (${shift['startTime']} - ${shift['endTime']})'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedShiftId = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a shift';
                }
                return null;
              },
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _assignShift,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Assign Shift'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
