import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeNoticeScreen extends StatefulWidget {
  const EmployeeNoticeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeNoticeScreen> createState() => _EmployeeNoticeScreenState();
}

class _EmployeeNoticeScreenState extends State<EmployeeNoticeScreen> {
  List<dynamic> notices = [];
  List<dynamic> recentNotices = [];
  bool isLoading = true;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
    _fetchRecentNotices();
    _fetchUnreadCount();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token'); // Changed from 'token' to 'jwt_token'
  }

  Future<void> _fetchNotices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        _showError('Authentication token not found. Please login again.');
        return;
      }

      print('Fetching employee notices with token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/notices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Employee notices response status: ${response.statusCode}');
      print('Employee notices response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notices = data['data'] ?? [];
          isLoading = false;
        });
        print('Loaded ${notices.length} employee notices');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showError('Authentication token not found. Please login again.');
        setState(() {
          isLoading = false;
        });
      } else {
        final error = json.decode(response.body);
        _showError('Failed to load notices: ${error['message'] ?? 'Unknown error'}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching notices: $e');
      setState(() {
        isLoading = false;
      });
      _showError('Error fetching notices: $e');
    }
  }

  Future<void> _fetchRecentNotices() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/notices?limit=5'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recentNotices = data['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading recent notices: $e');
      _showError('Error loading recent notices: $e');
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/notices/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          unreadCount = data['data']['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
      _showError('Error loading unread count: $e');
    }
  }

  Future<void> _markAsRead(String noticeId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('http://localhost:3000/api/notices/$noticeId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _fetchUnreadCount(); // Refresh unread count
    } catch (e) {
      print('Error marking notice as read: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFE53E3E);
      case 'Medium':
        return const Color(0xFFED8936);
      case 'Low':
        return const Color(0xFF38A169);
      default:
        return const Color(0xFF718096);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Urgent':
        return const Color(0xFFE53E3E);
      case 'Announcement':
        return const Color(0xFF3182CE);
      case 'Policy':
        return const Color(0xFF805AD5);
      case 'Event':
        return const Color(0xFF319795);
      default:
        return const Color(0xFF718096);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Notices',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3182CE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                _fetchNotices();
                _fetchRecentNotices();
                _fetchUnreadCount();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF3182CE),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3182CE)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Loading notices...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : notices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3182CE).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: Color(0xFF3182CE),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No notices available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later for new updates',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchNotices();
                    await _fetchRecentNotices();
                    await _fetchUnreadCount();
                  },
                  color: const Color(0xFF3182CE),
                  backgroundColor: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final notice = notices[index];
                      final isRead = notice['isRead'] ?? false;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isRead 
                                ? Colors.transparent 
                                : const Color(0xFF3182CE).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(notice['_id'] ?? '');
                              }
                              // Show full notice details
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notice['title'] ?? 'Notice',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2D3748),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              icon: const Icon(Icons.close_rounded),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFF7FAFC),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          constraints: const BoxConstraints(maxHeight: 400),
                                          child: SingleChildScrollView(
                                            child: Text(
                                              notice['content'] ?? 'No content',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                height: 1.6,
                                                color: Color(0xFF4A5568),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF3182CE),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Close',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (!isRead)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3182CE),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (!isRead) const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          notice['title'] ?? 'No Title',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: isRead ? const Color(0xFF4A5568) : const Color(0xFF2D3748),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(notice['priority'] ?? ''),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          notice['priority'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    notice['content'] ?? 'No Content',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: isRead ? const Color(0xFF718096) : const Color(0xFF4A5568),
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(notice['category'] ?? '').withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _getCategoryColor(notice['category'] ?? '').withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          notice['category'] ?? '',
                                          style: TextStyle(
                                            color: _getCategoryColor(notice['category'] ?? ''),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 16,
                                            color: const Color(0xFF718096),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(notice['createdAt']),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF718096),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
