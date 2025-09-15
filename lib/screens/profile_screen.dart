import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../services/employee_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  String _errorMessage = '';

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactRelationshipController = TextEditingController();
  final TextEditingController _emergencyContactPhoneController = TextEditingController();
  final TextEditingController _profilePictureController = TextEditingController();

  // New controllers for Work Location
  final TextEditingController _workLocationLatitudeController = TextEditingController();
  final TextEditingController _workLocationLongitudeController = TextEditingController();
  final TextEditingController _workLocationRadiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _populateControllers(Map<String, dynamic> user) {
    _nameController.text = user['name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneNumberController.text = user['phoneNumber'] ?? '';
    _profilePictureController.text = user['profilePicture'] ?? '';
    
    // Address
    _streetController.text = user['address']?['street'] ?? '';
    _cityController.text = user['address']?['city'] ?? '';
    _stateController.text = user['address']?['state'] ?? '';
    _zipCodeController.text = user['address']?['zipCode'] ?? '';
    _countryController.text = user['address']?['country'] ?? '';
    
    // Emergency Contact
    _emergencyContactNameController.text = user['emergencyContact']?['name'] ?? '';
    _emergencyContactRelationshipController.text = user['emergencyContact']?['relationship'] ?? '';
    _emergencyContactPhoneController.text = user['emergencyContact']?['phoneNumber'] ?? '';
    
    // Work Location
    _workLocationLatitudeController.text = user['workLocation']?['coordinates']?['latitude']?.toString() ?? '';
    _workLocationLongitudeController.text = user['workLocation']?['coordinates']?['longitude']?.toString() ?? '';
    _workLocationRadiusController.text = user['workLocation']?['radius']?.toString() ?? '';
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = await EmployeeService.getProfile();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile data.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactRelationshipController.dispose();
    _emergencyContactPhoneController.dispose();
    _profilePictureController.dispose();
    _workLocationLatitudeController.dispose();
    _workLocationLongitudeController.dispose();
    _workLocationRadiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await AuthService.logout();
                Navigator.pushReplacementNamed(context, '/login');
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF667eea),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading your profile...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: AppTheme.errorRed.withOpacity(0.7),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Oops! Something went wrong',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _currentUser == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_off,
                                size: 80,
                                color: Colors.grey.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Profile Not Available',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please log in again to access your profile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Color(0xFFFAFBFC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _showEditProfileDialog,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFF667eea).withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          padding: EdgeInsets.all(4),
                                          child: CircleAvatar(
                                            radius: 60,
                                            backgroundColor: Colors.white,
                                            backgroundImage: _currentUser!['profilePicture'] != null &&
                                                    _currentUser!['profilePicture'].isNotEmpty
                                                ? NetworkImage(_currentUser!['profilePicture'])
                                                : null,
                                            child: _currentUser!['profilePicture'] == null ||
                                                    _currentUser!['profilePicture'].isEmpty
                                                ? Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        _currentUser!['name'] != null && _currentUser!['name'].isNotEmpty
                                                            ? _currentUser!['name'][0].toUpperCase()
                                                            : '?',
                                                        style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF4CAF50),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    _currentUser!['name'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF667eea).withOpacity(0.1), Color(0xFF764ba2).withOpacity(0.1)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _currentUser!['designation'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF667eea),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            _buildProfileInfoCard(
                              Icons.badge,
                              'Employee ID',
                              _currentUser!['employeeId'] ?? 'N/A',
                              Color(0xFF2196F3),
                            ),
                            _buildProfileInfoCard(
                              Icons.email,
                              'Email',
                              _currentUser!['email'] ?? 'N/A',
                              Color(0xFF4CAF50),
                            ),
                            _buildProfileInfoCard(
                              Icons.work,
                              'Department',
                              _currentUser!['department'] ?? 'N/A',
                              Color(0xFF9C27B0),
                            ),
                            _buildProfileInfoCard(
                              Icons.phone,
                              'Phone Number',
                              _currentUser!['phoneNumber'] ?? 'N/A',
                              Color(0xFFFF9800),
                            ),
                            _buildProfileInfoCard(
                              Icons.location_on,
                              'Work Location',
                              _currentUser!['workLocation']?['address'] ?? 'N/A',
                              Color(0xFFF44336),
                            ),
                            _buildProfileInfoCard(
                              Icons.access_time,
                              'Working Hours',
                              '${_currentUser!['workingHours']?['startTime'] ?? '--:--'} - ${_currentUser!['workingHours']?['endTime'] ?? '--:--'}',
                              Color(0xFF607D8B),
                            ),
                            _buildProfileInfoCard(
                              Icons.contact_emergency,
                              'Emergency Contact',
                              '${_currentUser!['emergencyContact']?['name'] ?? 'N/A'} (${_currentUser!['emergencyContact']?['relationship'] ?? 'N/A'}) - ${_currentUser!['emergencyContact']?['phoneNumber'] ?? 'N/A'}',
                              Color(0xFFE91E63),
                            ),
                            SizedBox(height: 32),
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667eea).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _showEditProfileDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: Icon(Icons.edit, color: Colors.white),
                                label: Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildProfileInfoCard(IconData icon, String title, String value, Color iconColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    _populateControllers(_currentUser!);

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFFAFBFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Personal Information', Icons.person),
                      _buildStyledTextField(_profilePictureController, 'Profile Picture URL (Optional)', Icons.image, TextInputType.url),
                      SizedBox(height: 16),
                      _buildStyledTextField(_nameController, 'Full Name', Icons.person, TextInputType.text),
                      SizedBox(height: 16),
                      _buildStyledTextField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
                      SizedBox(height: 16),
                      _buildStyledTextField(_phoneNumberController, 'Phone Number', Icons.phone, TextInputType.phone),
                      
                      SizedBox(height: 24),
                      _buildSectionHeader('Address Details', Icons.home),
                      _buildStyledTextField(_streetController, 'Street', Icons.location_on, TextInputType.text),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStyledTextField(_cityController, 'City', Icons.location_city, TextInputType.text)),
                          SizedBox(width: 16),
                          Expanded(child: _buildStyledTextField(_stateController, 'State', Icons.map, TextInputType.text)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStyledTextField(_zipCodeController, 'Zip Code', Icons.local_post_office, TextInputType.text)),
                          SizedBox(width: 16),
                          Expanded(child: _buildStyledTextField(_countryController, 'Country', Icons.flag, TextInputType.text)),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      _buildSectionHeader('Work Location (Geofencing)', Icons.work),
                      Row(
                        children: [
                          Expanded(child: _buildStyledTextField(_workLocationLatitudeController, 'Latitude', Icons.gps_fixed, TextInputType.numberWithOptions(decimal: true))),
                          SizedBox(width: 16),
                          Expanded(child: _buildStyledTextField(_workLocationLongitudeController, 'Longitude', Icons.gps_fixed, TextInputType.numberWithOptions(decimal: true))),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildStyledTextField(_workLocationRadiusController, 'Radius (meters)', Icons.radio_button_unchecked, TextInputType.number),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _useCurrentLocationForWorkLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.my_location, color: Colors.white),
                          label: Text(
                            'Use Current Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      _buildSectionHeader('Emergency Contact', Icons.contact_emergency),
                      _buildStyledTextField(_emergencyContactNameController, 'Contact Name', Icons.person, TextInputType.text),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStyledTextField(_emergencyContactRelationshipController, 'Relationship', Icons.family_restroom, TextInputType.text)),
                          SizedBox(width: 16),
                          Expanded(child: _buildStyledTextField(_emergencyContactPhoneController, 'Contact Phone', Icons.phone, TextInputType.phone)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _updateProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF667eea), size: 20),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String label, IconData icon, TextInputType keyboardType) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF667eea), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocationForWorkLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permissions are denied.'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them manually.'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _workLocationLatitudeController.text = position.latitude.toString();
        _workLocationLongitudeController.text = position.longitude.toString();
        _workLocationRadiusController.text = '100';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current location fetched successfully!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
        'profilePicture': _profilePictureController.text.isNotEmpty ? _profilePictureController.text : null,
        'address': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zipCode': _zipCodeController.text,
          'country': _countryController.text,
        },
        'emergencyContact': {
          'name': _emergencyContactNameController.text,
          'relationship': _emergencyContactRelationshipController.text,
          'phoneNumber': _emergencyContactPhoneController.text,
        },
        'workLocation': {
          'name': _currentUser!['workLocation']?['name'] ?? 'Custom Location',
          'address': _currentUser!['workLocation']?['address'] ?? 'Custom Address',
          'coordinates': {
            'latitude': double.tryParse(_workLocationLatitudeController.text),
            'longitude': double.tryParse(_workLocationLongitudeController.text),
          },
          'radius': double.tryParse(_workLocationRadiusController.text),
        },
      };

      final response = await EmployeeService.updateProfile(updatedData);

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        await _loadProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
