import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/core/utils/extensions.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    // TODO: Load actual user profile from storage
    _displayName = 'John Doe'; // Mock data
    _nameController.text = _displayName;
  }

  void _toggleNameEdit() {
    setState(() {
      _isEditingName = !_isEditingName;
      if (!_isEditingName) {
        // Save the name
        _displayName = _nameController.text.trim();
        if (_displayName.isEmpty) {
          _displayName = 'User';
          _nameController.text = _displayName;
        }
        // TODO: Save to storage
      }
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? This will clear all your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    // TODO: Clear secure storage and navigate to onboarding
    context.showSuccessSnackBar('Logged out successfully');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
        child: Column(
          children: [
            // Profile header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.gridSpacing * 3),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: AppConstants.avatarSize,
                      backgroundColor: context.colorScheme.primaryContainer,
                      child: Text(
                        _getInitials(_displayName),
                        style: context.textTheme.headlineMedium?.copyWith(
                          color: context.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.gridSpacing * 2),
                    
                    // Name field
                    if (_isEditingName)
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _toggleNameEdit(),
                      )
                    else
                      GestureDetector(
                        onTap: _toggleNameEdit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _displayName,
                              style: context.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppConstants.gridSpacing),
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    
                    if (_isEditingName) ...[
                      const SizedBox(height: AppConstants.gridSpacing),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              _nameController.text = _displayName;
                              setState(() {
                                _isEditingName = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppConstants.gridSpacing),
                          FilledButton(
                            onPressed: _toggleNameEdit,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.gridSpacing * 3),
            
            // Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.gridSpacing * 2),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Fact Checks',
                            '42',
                            Icons.fact_check,
                          ),
                        ),
                        const SizedBox(width: AppConstants.gridSpacing),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Bookmarks',
                            '8',
                            Icons.bookmark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.gridSpacing * 3),
            
            // Settings
            Card(
              child: Column(
                children: [
                  // Theme setting
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                    subtitle: const Text('Choose your preferred theme'),
                    trailing: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark
                        ? const Icon(Icons.dark_mode)
                        : AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light
                            ? const Icon(Icons.light_mode)
                            : const Icon(Icons.auto_mode),
                    onTap: _showThemeDialog,
                  ),
                  
                  const Divider(height: 1),
                  
                  // About
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    subtitle: Text('Version ${AppConstants.appVersion}'),
                    onTap: _showAboutDialog,
                  ),
                  
                  const Divider(height: 1),
                  
                  // Logout
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: context.colorScheme.error,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: context.colorScheme.error,
                      ),
                    ),
                    subtitle: const Text('Clear all data and logout'),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.gridSpacing * 3),
            
            // Credits
            Text(
              'Made with ❤️ by ${AppConstants.teamName}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: AppConstants.iconSize * 1.5,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: AppConstants.gridSpacing),
          Text(
            value,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.primary,
            ),
          ),
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Icon(
                AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
              ),
              onTap: () {
                AdaptiveTheme.of(context).setLight();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Icon(
                AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
              ),
              onTap: () {
                AdaptiveTheme.of(context).setDark();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('System'),
              leading: Icon(
                AdaptiveTheme.of(context).mode == AdaptiveThemeMode.system 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
              ),
              onTap: () {
                AdaptiveTheme.of(context).setSystem();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: context.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.fact_check,
          size: 32,
          color: context.colorScheme.onPrimaryContainer,
        ),
      ),
      children: [
        const Text('AI-powered fact-checking application'),
        const SizedBox(height: 16),
        Text('Made by ${AppConstants.teamName}'),
      ],
    );
  }

  String _getInitials(String name) {
    final names = name.trim().split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }
}
