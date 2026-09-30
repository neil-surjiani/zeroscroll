import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/debug_log_provider.dart';

/// Hidden developer diagnostic panel.
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debugState = ref.watch(debugLogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Debug Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
            onPressed: () {
              ref.read(debugLogProvider.notifier).clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debug logs cleared')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.block),
              text: 'Blocked (${debugState.blockedNavigations.length})',
            ),
            Tab(
              icon: const Icon(Icons.terminal),
              text: 'Console (${debugState.consoleLogs.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Status Card
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Config Version: ${debugState.configVersion}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Debug Report'),
                      onPressed: () => _copyReport(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current URL: ${debugState.currentUrl ?? "None"}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Blocked Navigations
                debugState.blockedNavigations.isEmpty
                    ? const Center(
                        child: Text('No blocked navigations recorded yet.'),
                      )
                    : ListView.separated(
                        itemCount: debugState.blockedNavigations.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = debugState.blockedNavigations[index];
                          return ListTile(
                            leading: Icon(
                              Icons.block,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            title: Text(
                              item.path,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'URL: ${item.url}\nTime: ${item.timestamp.toLocal().toString().split('.').first}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),

                // 2. Live Console Logs
                debugState.consoleLogs.isEmpty
                    ? const Center(
                        child: Text('No console messages recorded yet.'),
                      )
                    : ListView.separated(
                        itemCount: debugState.consoleLogs.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final log = debugState.consoleLogs[index];
                          final isError = log.level.toLowerCase().contains(
                            'error',
                          );
                          final isWarn = log.level.toLowerCase().contains(
                            'warn',
                          );

                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isError
                                  ? Icons.error
                                  : (isWarn
                                        ? Icons.warning
                                        : Icons.info_outline),
                              color: isError
                                  ? theme.colorScheme.error
                                  : (isWarn
                                        ? Colors.amber.shade700
                                        : theme.colorScheme.secondary),
                              size: 18,
                            ),
                            title: Text(
                              log.message,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${log.level.toUpperCase()} • ${log.timestamp.toLocal().toString().split('.').first}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyReport(BuildContext context) {
    final report = ref.read(debugLogProvider.notifier).generateDebugReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug report copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
