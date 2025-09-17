import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../utils/theme.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  @override
  _AttendanceHistoryScreenState createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final records = await AttendanceService.getAttendanceHistory();
      if (!mounted) return;
      setState(() {
        _attendanceRecords = records;
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load attendance history: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppTheme.successGreen;
      case 'late':
        return AppTheme.warningOrange;
      default:
        return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance History'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFE8F2FF),
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: AppTheme.errorRed, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAttendanceHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAttendanceHistory,
                    color: AppTheme.primaryBlue,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = _attendanceRecords[index];
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(record['status'] ?? ''),
                              child: Icon(
                                record['status'] == 'present' ? Icons.check_circle : Icons.warning,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              DateFormat('dd/MM/yyyy').format(DateTime.parse(record['date'] ?? DateTime.now().toString())),
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkGray),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${record['status'] ?? 'N/A'}'),
                                Text('Clock In: ${record['clockIn']?['time'] ?? '--:--'}'),
                                Text('Clock Out: ${record['clockOut']?['time'] ?? '--:--'}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}