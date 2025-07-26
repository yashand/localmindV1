import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/privacy_service.dart';
import '../utils/app_theme.dart';

class PrivacyDashboardScreen extends StatefulWidget {
  const PrivacyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyDashboardScreen> createState() => _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState extends State<PrivacyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadPrivacyData();
  }

  Future<void> _loadPrivacyData() async {
    final privacyService = context.read<PrivacyService>();
    await privacyService.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearDataDialog,
            tooltip: 'Clear all data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPrivacyData,
        child: Consumer<PrivacyService>(
          builder: (context, privacyService, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverviewCard(privacyService),
                const SizedBox(height: 16),
                _buildDataAccessSummary(privacyService),
                const SizedBox(height: 16),
                _buildPermissionsCard(privacyService),
                const SizedBox(height: 16),
                _buildRecentActivityCard(privacyService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCard(PrivacyService privacyService) {
    final summary = privacyService.getDataAccessSummary();
    final totalAccesses = summary.values.fold(0, (sum, count) => sum + count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Access Events',
                    totalAccesses.toString(),
                    Icons.analytics,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Data Types Accessed',
                    summary.length.toString(),
                    Icons.category,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Active Permissions',
                    privacyService.consents.values.where((v) => v).length.toString(),
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Data Types',
                    summary.keys.length.toString(),
                    Icons.storage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataAccessSummary(PrivacyService privacyService) {
    final summary = privacyService.getDataAccessSummary();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Access Summary (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (summary.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No data access recorded'),
                ),
              )
            else
              ...summary.entries.map((entry) => _buildDataTypeRow(
                entry.key,
                entry.value,
                privacyService,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeRow(String dataType, int count, PrivacyService privacyService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _getDataTypeIcon(dataType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDataType(dataType),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '$count access${count == 1 ? '' : 'es'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showDataTypeDetails(dataType, privacyService),
            child: const Text('View'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeleteDataType(dataType, privacyService),
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(PrivacyService privacyService) {
    final permissions = [
      {'key': 'app_usage_tracking', 'label': 'App Usage Tracking', 'icon': Icons.apps},
      {'key': 'location_tracking', 'label': 'Location Tracking', 'icon': Icons.location_on},
      {'key': 'calendar_access', 'label': 'Calendar Access', 'icon': Icons.calendar_today},
      {'key': 'contact_access', 'label': 'Contact Access', 'icon': Icons.contacts},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permission Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...permissions.map((permission) {
              final key = permission['key'] as String;
              final label = permission['label'] as String;
              final icon = permission['icon'] as IconData;
              final isGranted = privacyService.consents[key] ?? false;

              return ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: Switch(
                  value: isGranted,
                  onChanged: (value) {
                    if (value) {
                      privacyService.grantPermission(key, 'user_control');
                    } else {
                      privacyService.revokePermission(key, 'user_control');
                    }
                    setState(() {});
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(PrivacyService privacyService) {
    final recentLogs = privacyService.getRecentAccessLogs(days: 3);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity (Last 3 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (recentLogs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent activity'),
                ),
              )
            else
              ...recentLogs.take(10).map((log) => _buildActivityItem(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(PrivacyAccessLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _getDataTypeIcon(log.dataType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDataType(log.dataType)} - ${_formatAction(log.action)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDataTypeIcon(String dataType) {
    IconData icon;
    Color color;

    switch (dataType.toLowerCase()) {
      case 'location':
        icon = Icons.location_on;
        color = Colors.red;
        break;
      case 'contacts':
        icon = Icons.contacts;
        color = Colors.blue;
        break;
      case 'calendar':
        icon = Icons.calendar_today;
        color = Colors.green;
        break;
      case 'app_usage':
        icon = Icons.apps;
        color = Colors.orange;
        break;
      default:
        icon = Icons.storage;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  String _formatDataType(String dataType) {
    return dataType.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatAction(String action) {
    return action.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDataTypeDetails(String dataType, PrivacyService privacyService) {
    final logs = privacyService.getAccessLogsForDataType(dataType);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDataType(dataType)} Access Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) => _buildActivityItem(logs[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDataType(String dataType, PrivacyService privacyService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Data'),
        content: Text(
          'Are you sure you want to delete all ${_formatDataType(dataType)} data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              privacyService.deleteDataType(dataType);
              Navigator.pop(context);
              setState(() {});
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all privacy data? This will remove all access logs and reset all permissions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<PrivacyService>().clearAllData();
              Navigator.pop(context);
              setState(() {});
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}