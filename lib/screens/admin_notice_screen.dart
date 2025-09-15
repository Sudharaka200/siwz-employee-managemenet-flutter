import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert' as convert;

class AdminNoticeScreen extends StatefulWidget {
  const AdminNoticeScreen({Key? key}) : super(key: key);

  @override
  State<AdminNoticeScreen> createState() => _AdminNoticeScreenState();
}

class _AdminNoticeScreenState extends State<AdminNoticeScreen> {
  List<dynamic> notices = [];
  bool isLoading = true;
  String? selectedPriority;
  String? selectedCategory;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'General';
  String _selectedTargetAudience = 'all';
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
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

      String url = 'http://localhost:3000/api/notices';
      // Use admin-specific endpoint as per NoticeService
      url += '/admin/all';

      // Add filters if selected
      List<String> queryParams = [];
      if (selectedPriority != null) queryParams.add('priority=$selectedPriority');
      if (selectedCategory != null) queryParams.add('category=$selectedCategory');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('Fetching notices from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notices = data['data'] ?? [];
          isLoading = false;
        });
        print('Loaded ${notices.length} notices');
      } else if (response.statusCode == 403) {
        _showError('Access denied. Admin privileges required.');
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

  Future<void> _createNotice() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    try {
      final token = await _getToken();
      if (token == null) {
        _showError('Authentication token not found. Please login again.');
        return;
      }

      final userId = _getUserIdFromToken(token);
      if (userId == null) {
        _showError('Unable to get user information from token. Please login again.');
        return;
      }

      final Map<String, dynamic> requestBody = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'priority': _selectedPriority,
        'category': _selectedCategory,
        'targetAudience': _selectedTargetAudience,
        'createdBy': userId, // Remove .toString() to keep as original type
      };

      // Add expiry date only if it's set
      if (_expiryDate != null) {
        requestBody['expiryDate'] = _expiryDate!.toIso8601String();
      }

      print('Creating notice with data: $requestBody');
      print('CreatedBy value: ${requestBody['createdBy']}');
      print('CreatedBy type: ${requestBody['createdBy'].runtimeType}');
      
      String jsonBody;
      try {
        jsonBody = json.encode(requestBody);
        print('JSON body: $jsonBody'); // Debug the actual JSON being sent
      } catch (e) {
        print('JSON encoding error: $e');
        _showError('Error preparing request data');
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/notices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonBody, // Use the explicitly encoded JSON
      );

      print('Create notice response status: ${response.statusCode}');
      print('Create notice response body: ${response.body}');

      if (response.statusCode == 201) {
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _selectedPriority = 'Medium';
          _selectedCategory = 'General';
          _selectedTargetAudience = 'all';
          _expiryDate = null;
        });
        _fetchNotices();
        Navigator.of(context).pop();
        _showSuccess('Notice created successfully');
      } else if (response.statusCode == 403) {
        _showError('Access denied. Admin privileges required.');
      } else {
        final error = json.decode(response.body);
        _showError('Error: ${error['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error creating notice: $e');
      _showError('Error creating notice: $e');
    }
  }

  Future<void> _deleteNotice(String noticeId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError('Authentication token not found. Please login again.');
        return;
      }

      print('Deleting notice with ID: $noticeId');

      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/notices/$noticeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Delete notice response status: ${response.statusCode}');
      print('Delete notice response body: ${response.body}');

      if (response.statusCode == 200) {
        _fetchNotices();
        _showSuccess('Notice deleted successfully');
      } else if (response.statusCode == 403) {
        _showError('Access denied. Admin privileges required.');
      } else {
        final error = json.decode(response.body);
        _showError('Error: ${error['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error deleting notice: $e');
      _showError('Error deleting notice: $e');
    }
  }

  String? _getUserIdFromToken(String token) {
    try {
      // JWT tokens have 3 parts separated by dots
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed for base64 decoding
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(decoded);
      
      print('JWT payload: $payloadMap'); // Added debug logging
      
      // Extract user ID (common field names: id, userId, _id, sub)
      final userId = payloadMap['id'] ?? payloadMap['userId'] ?? payloadMap['_id'] ?? payloadMap['sub'];
      print('Extracted user ID: $userId'); // Added debug logging
      
      return userId?.toString();
    } catch (e) {
      print('Error decoding JWT token: $e');
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Urgent':
        return Colors.red;
      case 'Announcement':
        return Colors.blue;
      case 'Policy':
        return Colors.purple;
      case 'Event':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showCreateNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Notice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                    hintText: 'Enter notice title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content *',
                    border: OutlineInputBorder(),
                    hintText: 'Enter notice content',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ['High', 'Medium', 'Low'].map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(priority),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['General', 'Announcement', 'Policy', 'Event', 'Urgent'].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTargetAudience,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Employees')),
                    DropdownMenuItem(value: 'department', child: Text('Department')),
                    DropdownMenuItem(value: 'role', child: Text('Role')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedTargetAudience = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Expiry Date (Optional)'),
                  subtitle: Text(_expiryDate != null
                      ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                      : 'No expiry date'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_expiryDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setDialogState(() {
                              _expiryDate = null;
                            });
                          },
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        _expiryDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                _titleController.clear();
                _contentController.clear();
                setState(() {
                  _selectedPriority = 'Medium';
                  _selectedCategory = 'General';
                  _selectedTargetAudience = 'all';
                  _expiryDate = null;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createNotice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Notice'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'all_priority') {
                  selectedPriority = null;
                } else if (['High', 'Medium', 'Low'].contains(value)) {
                  selectedPriority = value;
                } else if (value == 'all_category') {
                  selectedCategory = null;
                } else if (['General', 'Announcement', 'Policy', 'Event', 'Urgent'].contains(value)) {
                  selectedCategory = value;
                }
              });
              _fetchNotices();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all_priority',
                child: Text('All Priorities'),
              ),
              const PopupMenuItem(
                value: 'High',
                child: Text('High Priority'),
              ),
              const PopupMenuItem(
                value: 'Medium',
                child: Text('Medium Priority'),
              ),
              const PopupMenuItem(
                value: 'Low',
                child: Text('Low Priority'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'all_category',
                child: Text('All Categories'),
              ),
              const PopupMenuItem(
                value: 'General',
                child: Text('General'),
              ),
              const PopupMenuItem(
                value: 'Announcement',
                child: Text('Announcement'),
              ),
              const PopupMenuItem(
                value: 'Policy',
                child: Text('Policy'),
              ),
              const PopupMenuItem(
                value: 'Event',
                child: Text('Event'),
              ),
              const PopupMenuItem(
                value: 'Urgent',
                child: Text('Urgent'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _fetchNotices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notice Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Notices: ${notices.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateNoticeDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          // Notices List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notices.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No notices found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first notice to get started',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotices,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: notices.length,
                          itemBuilder: (context, index) {
                            final notice = notices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notice['title'] ?? 'No Title',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(notice['priority'] ?? ''),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            notice['priority'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(notice['category'] ?? ''),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            notice['category'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      notice['content'] ?? 'No Content',
                                      style: const TextStyle(fontSize: 14, height: 1.4),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          notice['createdBy']?['name'] ?? 'Unknown',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${notice['readCount'] ?? 0} reads',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _formatDate(notice['createdAt']),
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'delete') {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Delete Notice'),
                                                  content: const Text('Are you sure you want to delete this notice?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                        _deleteNotice(notice['_id'] ?? '');
                                                      },
                                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          child: const Icon(Icons.more_vert, size: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateNoticeDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
