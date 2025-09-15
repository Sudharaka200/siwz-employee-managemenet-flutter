import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../services/shift_service.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _schedule;
  bool _isLoading = true;
  bool _isRetrying = false; // Added retry loading state
  String _currentTime = DateFormat('h:mm a').format(DateTime.now().toUtc().add(Duration(hours: 5, minutes: 30)));
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _loadSchedule();
    _updateTimePeriodically();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final schedule = await ShiftService.getMySchedule();
      print('📱 Received schedule in screen: $schedule');
      
      setState(() {
        _schedule = schedule;
        _isLoading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('❌ Schedule screen error: $e');
      setState(() {
        _isLoading = false;
      });
      String errorMessage = e.toString();
      if (errorMessage.contains('403')) {
        errorMessage = 'Access denied. Please log in again or contact support.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorRed,
          action: SnackBarAction(
            label: 'Retry',
            textColor: AppTheme.primaryBlue,
            onPressed: _handleRetry, // Use new retry handler
          ),
        ),
      );
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    await Future.delayed(Duration(milliseconds: 500)); // Brief delay for UX
    await _loadSchedule();
    setState(() => _isRetrying = false);
  }

  Future<void> _handleRefresh() async {
    _fadeController.reset();
    _slideController.reset();
    await _loadSchedule();
  }

  void _updateTimePeriodically() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('h:mm a').format(DateTime.now().toUtc().add(Duration(hours: 5, minutes: 30)));
        });
      }
      return true;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Schedule', style: TextStyle(color: AppTheme.darkGray)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.darkGray),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isRetrying 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: _isRetrying ? null : _handleRefresh,
            ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _currentTime,
                style: TextStyle(fontSize: 16, color: AppTheme.darkGray, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget() // Enhanced loading widget
          : RefreshIndicator( // Added pull-to-refresh
              onRefresh: _handleRefresh,
              color: AppTheme.primaryBlue,
              child: _schedule == null || !_schedule!['hasSchedule']
                  ? _buildNoScheduleWidget()
                  : _buildScheduleContent(),
            ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppTheme.primaryBlue,
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading your schedule...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.lightGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40),
          _buildShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: List.generate(4, (index) => 
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity * 0.6,
                            decoration: BoxDecoration(
                              color: AppTheme.lightGray.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            height: 16,
                            width: double.infinity * 0.8,
                            decoration: BoxDecoration(
                              color: AppTheme.lightGray.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoScheduleWidget() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.calendar_today, 
                          size: 80, 
                          color: AppTheme.primaryBlue.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No schedule assigned yet!',
                    style: TextStyle(fontSize: 18, color: AppTheme.darkGray),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Contact your admin to get a schedule assigned.',
                    style: TextStyle(fontSize: 14, color: AppTheme.lightGray),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleContent() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildScheduleCard(),
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    final shift = _schedule!['shift'];
    print('🔍 Building schedule card with shift data: $shift');
    
    String shiftName = shift['name']?.toString() ?? 'Unknown Shift';
    String startTime = shift['startTime']?.toString() ?? '00:00';
    String endTime = shift['endTime']?.toString() ?? '00:00';
    int breakDuration = shift['breakDuration'] is int ? shift['breakDuration'] : (int.tryParse(shift['breakDuration']?.toString() ?? '0') ?? 0);
    List<dynamic> workingDaysList = shift['workingDays'] is List ? shift['workingDays'] : [];
    String description = shift['description']?.toString() ?? '';
    
    String workingHours = '$startTime - $endTime';
    String breakText = '$breakDuration minutes';
    String workingDaysText = workingDaysList.isNotEmpty 
        ? workingDaysList.map((day) => _capitalizeFirst(day.toString())).join(', ')
        : 'Not specified';
    
    print('🔍 Extracted values - Name: $shiftName, Hours: $workingHours, Break: $breakText, Days: $workingDaysText, Description: $description');
    
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Assigned Shift',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          SizedBox(height: 20),
          TweenAnimationBuilder(
            duration: Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: AppTheme.primaryBlue,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  shiftName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          ..._buildAnimatedInfoRows([
                            {'icon': Icons.access_time, 'label': 'Working Hours', 'value': workingHours},
                            {'icon': Icons.coffee, 'label': 'Break Duration', 'value': breakText},
                            {'icon': Icons.calendar_view_week, 'label': 'Working Days', 'value': workingDaysText},
                            if (description.isNotEmpty) {'icon': Icons.info_outline, 'label': 'Description', 'value': description},
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedInfoRows(List<Map<String, dynamic>> rows) {
    return rows.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> row = entry.value;
      
      return TweenAnimationBuilder(
        duration: Duration(milliseconds: 400 + (index * 100)),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _buildInfoRow(row['icon'], row['label'], row['value']),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    print('🎯 Building info row - Label: $label, Value: $value');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.darkGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
