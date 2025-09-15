import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/leave_service.dart';
import '../../services/expense_service.dart';
import 'assign_schedule_screen.dart';
import '../widgets/loading_widgets.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _expenseClaims = [];
  List<String> _departments = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';
  
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
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadEmployees(),
        _loadAttendanceRecords(),
        _loadLeaveRequests(),
        _loadExpenseClaims(),
        _loadDepartments(),
      ]);
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    _fadeController.reset();
    _slideController.reset();
    await _loadData();
    setState(() => _isRefreshing = false);
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await AdminService.getEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      print('Error loading employees: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadAttendanceRecords() async {
    try {
      final records = await AdminService.getAttendanceRecords();
      setState(() {
        _attendanceRecords = records;
      });
    } catch (e) {
      print('Error loading attendance records: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attendance records: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadLeaveRequests() async {
    try {
      final requests = await LeaveService.getAllLeaveRequests();
      setState(() {
        _leaveRequests = requests;
      });
    } catch (e) {
      print('Error loading leave requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load leave requests: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadExpenseClaims() async {
    try {
      final claims = await ExpenseService.getAllExpenseClaims();
      print("Fetched expense claims: $claims");
      print("Number of claims: ${claims.length}");
      setState(() {
        _expenseClaims = claims.isEmpty ? [{'_id': 'temp', 'employeeName': 'No Data', 'expenseType': 'N/A', 'amount': 0.0, 'claimDate': DateTime.now().toIso8601String(), 'status': 'N/A', 'description': 'No claims available'}] : claims;
      });
    } catch (e) {
      print('Error loading expense claims: $e');
      setState(() {
        _expenseClaims = [{'_id': 'error', 'employeeName': 'Error', 'expenseType': 'N/A', 'amount': 0.0, 'claimDate': DateTime.now().toIso8601String(), 'status': 'N/A', 'description': 'Failed to load: ${e.toString()}'}];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expense claims: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _departments = [
        "Information Technology",
        "Human Resources",
        "Finance",
        "Marketing",
        "Operations",
        "Design",
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', 
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.w600,
            color: Colors.white
          )
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isRefreshing 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.refresh, color: Colors.white),
              onPressed: _isRefreshing ? null : _handleRefresh,
            ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout, color: Colors.white, size: 20),
              ),
              onPressed: () async {
                final result = await AuthService.logout();
                if (result['success']) {
                  Navigator.pushReplacementNamed(context, '/login');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? _buildLoadingState() // Enhanced loading state
            : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : RefreshIndicator( // Added pull-to-refresh
                    onRefresh: _handleRefresh,
                    color: AppTheme.primaryBlue,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildBody(),
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 4) _loadExpenseClaims();
              else _loadData();
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.dashboard_outlined, Icons.dashboard, 0),
              label: 'Dashboard'
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.people_outline, Icons.people, 1),
              label: 'Employees'
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.schedule_outlined, Icons.schedule, 2),
              label: 'Attendance'
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.request_page_outlined, Icons.request_page, 3),
              label: 'Leaves'
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.receipt_outlined, Icons.receipt, 4),
              label: 'Expenses'
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.notifications_outlined, Icons.notifications, 5),
              label: 'Notices'
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.analytics_outlined, Icons.analytics, 6),
              label: 'Reports'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          LoadingWidgets.fullScreenLoader(
            message: 'Loading dashboard...',
            showMessage: true,
          ),
          SizedBox(height: 40),
          // Skeleton loaders for dashboard cards
          Row(
            children: [
              Expanded(child: LoadingWidgets.dashboardCardSkeleton()),
              SizedBox(width: 15),
              Expanded(child: LoadingWidgets.dashboardCardSkeleton()),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: LoadingWidgets.dashboardCardSkeleton()),
              SizedBox(width: 15),
              Expanded(child: LoadingWidgets.dashboardCardSkeleton()),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: LoadingWidgets.dashboardCardSkeleton()),
              SizedBox(width: 15),
              Expanded(child: LoadingWidgets.dashboardCardSkeleton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, 
                      color: AppTheme.errorRed, 
                      size: 48
                    ),
                    SizedBox(height: 16),
                    Text(_errorMessage, 
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w500
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    LoadingWidgets.loadingButton(
                      text: 'Retry',
                      onPressed: _loadData,
                      isLoading: _isLoading,
                      backgroundColor: AppTheme.primaryBlue,
                      height: 45,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    bool isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 8 : 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: isSelected ? 26 : 24,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildEmployeesTab();
      case 2:
        return _buildAttendanceTab();
      case 3:
        return _buildLeavesTab();
      case 4:
        return _buildExpensesTab();
      case 5:
        return _buildNoticesTab();
      case 6:
        return _buildReportsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBlue, Color(0xFF1E88E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Here\'s your team overview for today',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.dashboard,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 400),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: Text(
                      'Quick Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ..._buildAnimatedStatCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedStatCards() {
    final cards = [
      [
        _buildModernStatCard('Total Employees', '${_employees.length}', Icons.people, AppTheme.primaryBlue, Color(0xFF1E88E5)),
        _buildModernStatCard('Present Today', '${_attendanceRecords.where((r) => r['status'] == 'present').length}', Icons.check_circle, AppTheme.successGreen, Color(0xFF43A047)),
      ],
      [
        _buildModernStatCard('Absent Today', '${_attendanceRecords.where((r) => r['status'] == 'absent').length}', Icons.cancel, AppTheme.errorRed, Color(0xFFE53935)),
        _buildModernStatCard('Late Arrivals', '${_attendanceRecords.where((r) => r['status'] == 'late').length}', Icons.access_time, AppTheme.warningOrange, Color(0xFFFF9800)),
      ],
      [
        _buildModernStatCard('Pending Leaves', '${_leaveRequests.where((r) => r['status'] == 'pending').length}', Icons.pending_actions, Color(0xFF9C27B0), Color(0xFFAB47BC)),
        _buildModernStatCard('Pending Expenses', '${_expenseClaims.where((r) => r['status'] == 'pending').length}', Icons.receipt_long, Color(0xFF795548), Color(0xFF8D6E63)),
      ],
    ];

    return cards.asMap().entries.map((entry) {
      int rowIndex = entry.key;
      List<Widget> rowCards = entry.value;
      
      return TweenAnimationBuilder(
        duration: Duration(milliseconds: 500 + (rowIndex * 100)),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Expanded(child: rowCards[0]),
                    SizedBox(width: 15),
                    Expanded(child: rowCards[1]),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color primaryColor, Color secondaryColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return Column(children: [
      TweenAnimationBuilder(
        duration: Duration(milliseconds: 500),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, -20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employees',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        Text(
                          '${_employees.length} total employees',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(children: [
                      _buildModernButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AssignScheduleScreen())).then((_) => _loadEmployees());
                        },
                        icon: Icons.calendar_month,
                        label: 'Schedule',
                        color: Color(0xFF9C27B0),
                      ),
                      SizedBox(width: 10),
                      _buildModernButton(
                        onPressed: _showAddEmployeeDialog,
                        icon: Icons.add,
                        label: 'Add Employee',
                        color: AppTheme.primaryBlue,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () => _loadEmployees(),
          color: AppTheme.primaryBlue,
          child: _employees.isEmpty
              ? _buildEmptyEmployeeState()
              : ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(50 * (1 - value), 0),
                          child: Opacity(
                            opacity: value,
                            child: _buildEmployeeCard(_employees[index], index),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    ]);
  }

  Widget _buildEmptyEmployeeState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: AppTheme.primaryBlue.withOpacity(0.6),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No employees found',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first employee to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightGray,
                    ),
                  ),
                  SizedBox(height: 30),
                  LoadingWidgets.loadingButton(
                    text: 'Add Employee',
                    onPressed: _showAddEmployeeDialog,
                    isLoading: false,
                    backgroundColor: AppTheme.primaryBlue,
                    height: 45,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              employee['name'][0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          employee['name'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${employee['department'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                SizedBox(width: 12),
                Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${employee['employeeId']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            if (employee['shift'] != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: AppTheme.primaryBlue),
                  SizedBox(width: 4),
                  Text(
                    'Shift: ${employee['shift']['name']} (${employee['shift']['startTime']} - ${employee['shift']['endTime']})',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
                value: 'edit',
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
                value: 'delete',
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditEmployeeDialog(employee);
              } else if (value == 'delete') {
                _deleteEmployee(employee['_id']);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(20),
        child: Text('Attendance Records', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkGray)),
      ),
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: _attendanceRecords.length,
          itemBuilder: (context, index) {
            final record = _attendanceRecords[index];
            final clockInLocation = record['clockIn']?['location']?['name'] ?? 'N/A';
            final clockOutLocation = record['clockOut']?['location']?['name'] ?? 'N/A';
            return Card(
              margin: EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(record['status']),
                  child: Icon(_getStatusIcon(record['status']), color: Colors.white),
                ),
                title: Text('${record['employeeName'] ?? 'Unknown'} (${record['employeeId'] ?? 'N/A'})'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${record['date']}'),
                    Text('Clock In: ${record['clockIn']?['time'] ?? '--'} at $clockInLocation'),
                    Text('Clock Out: ${record['clockOut']?['time'] ?? '--'} at $clockOutLocation'),
                  ],
                ),
                trailing: Chip(
                  label: Text(record['status'].toUpperCase()),
                  backgroundColor: _getStatusColor(record['status']).withOpacity(0.2),
                  labelStyle: TextStyle(color: _getStatusColor(record['status']), fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildLeavesTab() {
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(20),
        child: Text('Leave Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkGray)),
      ),
      Expanded(
        child: _leaveRequests.isEmpty
            ? Center(child: Text('No leave requests found.'))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _leaveRequests.length,
                itemBuilder: (context, index) {
                  final request = _leaveRequests[index];
                  final startDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(request['startDate']));
                  final endDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(request['endDate']));
                  return Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getLeaveStatusColor(request['status']),
                        child: Icon(_getLeaveStatusIcon(request['status']), color: Colors.white),
                      ),
                      title: Text('${request['employeeName'] ?? 'Unknown'} - ${request['leaveType']}'),
                      subtitle: Text('From: $startDate to $endDate (${request['totalDays']} days)\nReason: ${request['reason']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(request['status'].toUpperCase()),
                            backgroundColor: _getLeaveStatusColor(request['status']).withOpacity(0.2),
                            labelStyle: TextStyle(color: _getLeaveStatusColor(request['status']), fontWeight: FontWeight.bold),
                          ),
                          if (request['status'] == 'pending')
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(child: Text('Approve'), value: 'approved'),
                                PopupMenuItem(child: Text('Reject'), value: 'rejected'),
                              ],
                              onSelected: (value) {
                                _updateLeaveRequestStatus(request['_id'], value as String);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildExpensesTab() {
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(20),
        child: Text('Expense Claims', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkGray)),
      ),
      Expanded(
        child: _expenseClaims.isEmpty
            ? Center(child: Text('No expense claims found.'))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _expenseClaims.length,
                itemBuilder: (context, index) {
                  final claim = _expenseClaims[index];
                  final claimDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(claim['claimDate'] ?? DateTime.now().toIso8601String()));
                  return Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getExpenseStatusColor(claim['status'] ?? 'unknown'),
                        child: Icon(_getExpenseStatusIcon(claim['status'] ?? 'unknown'), color: Colors.white),
                      ),
                      title: Text('${claim['employeeName'] ?? 'Unknown'} - ${claim['expenseType']?.replaceAll('-', ' ').toUpperCase() ?? 'N/A'}'),
                      subtitle: Text(
                        'Amount: \$${claim['amount']?.toStringAsFixed(2) ?? '0.00'}\nDate: $claimDate\nDescription: ${claim['description'] ?? 'N/A'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text((claim['status'] ?? 'N/A').toUpperCase()),
                            backgroundColor: _getExpenseStatusColor(claim['status'] ?? 'unknown').withOpacity(0.2),
                            labelStyle: TextStyle(color: _getExpenseStatusColor(claim['status'] ?? 'unknown'), fontWeight: FontWeight.bold),
                          ),
                          if ((claim['status'] ?? 'N/A') == 'pending')
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(child: Text('Approve'), value: 'approved'),
                                PopupMenuItem(child: Text('Reject'), value: 'rejected'),
                              ],
                              onSelected: (value) {
                                _updateExpenseClaimStatus(claim['_id'], value as String);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkGray)),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.file_download, color: AppTheme.primaryBlue),
              title: Text('Export Attendance Report'),
              subtitle: Text('Download monthly attendance report'),
              trailing: ElevatedButton(onPressed: _exportAttendanceReport, child: Text('Export')),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.analytics, color: AppTheme.successGreen),
              title: Text('Generate Analytics'),
              subtitle: Text('View detailed attendance analytics'),
              trailing: ElevatedButton(onPressed: _generateAnalytics, child: Text('Generate')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesTab() {
  return Column(children: [
    Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notices & Announcements',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              Text(
                'Manage company notices',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _buildModernButton(
            onPressed: () {
              Navigator.pushNamed(context, '/admin-notice');
            },
            icon: Icons.notifications,
            label: 'Manage Notices',
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    ),
    Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_alert, color: Colors.white, size: 24),
                ),
                title: Text('Create New Notice'),
                subtitle: Text('Send announcements to all employees'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, '/admin-notice');
                },
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.successGreen, Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.visibility, color: Colors.white, size: 24),
                ),
                title: Text('View All Notices'),
                subtitle: Text('Manage existing notices and announcements'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, '/admin-notice');
                },
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFAB47BC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics, color: Colors.white, size: 24),
                ),
                title: Text('Notice Analytics'),
                subtitle: Text('View notice engagement statistics'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notice analytics coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  ]);
}

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.successGreen;
      case 'absent':
        return AppTheme.errorRed;
      case 'late':
        return AppTheme.warningOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  Color _getLeaveStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningOrange;
      case 'approved':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getLeaveStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getExpenseStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningOrange;
      case 'approved':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getExpenseStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.receipt_long;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedDepartment;
    final designationController = TextEditingController();
    final phoneNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Full Name')),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Department'),
                value: selectedDepartment,
                items: _departments.map((String dept) {
                  return DropdownMenuItem<String>(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (String? newValue) {
                  selectedDepartment = newValue;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select a department';
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: designationController,
                decoration: InputDecoration(labelText: 'Designation (Optional)'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number (Optional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedDepartment == null || selectedDepartment!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a department.')));
                return;
              }
              try {
                final response = await AdminService.addEmployee({
                  'name': nameController.text,
                  'email': emailController.text,
                  'department': selectedDepartment,
                  'designation': designationController.text.isNotEmpty ? designationController.text : 'Employee',
                  'phoneNumber': phoneNumberController.text.isNotEmpty ? phoneNumberController.text : null,
                });

                Navigator.pop(context);
                _loadEmployees();
                if (response['success']) {
                  final employeeId = response['employee']['employeeId'];
                  final generatedPassword = response['employee']['generatedPassword'];
                  final emailStatus = response['emailStatus'] ?? {'sent': false, 'message': 'Email status unknown'};
                  
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Employee Added!'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee ${nameController.text} added successfully.\n'
                            'Employee ID: $employeeId\n'
                            'Temporary Password: $generatedPassword\n',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: emailStatus['sent'] ? Colors.green.shade50 : Colors.orange.shade50,
                              border: Border.all(
                                color: emailStatus['sent'] ? Colors.green : Colors.orange,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  emailStatus['sent'] ? Icons.email : Icons.email_outlined,
                                  color: emailStatus['sent'] ? Colors.green : Colors.orange,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    emailStatus['sent'] 
                                      ? 'Welcome email sent to ${emailController.text}'
                                      : 'Email not sent: ${emailStatus['message']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: emailStatus['sent'] ? Colors.green.shade700 : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!emailStatus['sent']) ...[
                            SizedBox(height: 8),
                            Text(
                              'Please provide these credentials to the employee manually.',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add employee: ${response['message']}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add employee: ${e.toString()}')),
                );
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(Map<String, dynamic> employee) {
    final nameController = TextEditingController(text: employee['name']);
    final emailController = TextEditingController(text: employee['email']);
    String? selectedDepartment = employee['department'];
    final designationController = TextEditingController(text: employee['designation']);
    final phoneNumberController = TextEditingController(text: employee['phoneNumber']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Full Name')),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Department'),
                value: selectedDepartment,
                items: _departments.map((String dept) {
                  return DropdownMenuItem<String>(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (String? newValue) {
                  selectedDepartment = newValue;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select a department';
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextField(controller: designationController, decoration: InputDecoration(labelText: 'Designation')),
              SizedBox(height: 10),
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedDepartment == null || selectedDepartment!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a department.')));
                return;
              }
              try {
                final response = await AdminService.updateEmployee(employee['_id'], {
                  'name': nameController.text,
                  'email': emailController.text,
                  'department': selectedDepartment,
                  'designation': designationController.text,
                  'phoneNumber': phoneNumberController.text,
                });
                Navigator.pop(context);
                _loadEmployees();
                if (response['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Employee updated successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update employee: ${response['message']}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update employee: ${e.toString()}')),
                );
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(String employeeId) async {
    try {
      final response = await AdminService.deleteEmployee(employeeId);
      if (response['success']) {
        _loadEmployees();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete employee: ${response['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete employee: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateLeaveRequestStatus(String requestId, String status) async {
    try {
      final response = await LeaveService.updateLeaveRequestStatus(requestId, status);
      if (response['success']) {
        _loadLeaveRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request status updated to ${status} successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update leave request: ${response['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update leave request: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateExpenseClaimStatus(String claimId, String status) async {
    try {
      final response = await ExpenseService.updateExpenseClaimStatus(claimId, status);
      if (response['success']) {
        _loadExpenseClaims();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense claim status updated to ${status} successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update expense claim: ${response['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update expense claim: ${e.toString()}')),
      );
    }
  }

  void _exportAttendanceReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attendance report exported successfully (Placeholder)')),
    );
  }

  void _generateAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Analytics generated successfully (Placeholder)')),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
