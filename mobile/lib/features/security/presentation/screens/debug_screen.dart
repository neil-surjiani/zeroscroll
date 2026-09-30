import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../remote_config/presentation/providers/remote_config_provider.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';
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

    final repo = ref.watch(routeConfigRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Debug Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar_outlined),
            tooltip: 'Probe Posting Capability',
            onPressed: () => _probePostingCapability(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Remote Config',
            onPressed: () async {
              await repo.refreshConfig();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remote configuration refreshed')),
                );
              }
            },
          ),
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
                      'Config Version: ${debugState.configVersion} (${repo.currentSource.name})',
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
                if (repo.lastFetchError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Remote Error: ${repo.lastFetchError}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

  Future<void> _probePostingCapability(BuildContext context) async {
    final controller = ref.read(webViewControllerProvider);
    final buffer = StringBuffer('=== Story Posting Capability Probe ===\n');

    if (controller == null) {
      buffer.writeln('WebViewController is not currently attached.');
    } else {
      try {
        final probeResult = await controller.evaluateJs(
          '''
            (function() {
              var results = {};
              results.hasMediaDevices = !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
              results.hasFileInput = !!document.querySelector("input[type='file']");
              results.hasCaptureSupport = 'capture' in document.createElement('input');
              results.cookieEnabled = navigator.cookieEnabled;
              results.userAgent = navigator.userAgent;
              return JSON.stringify(results);
            })();
          ''',
        );
        buffer.writeln('Mobile Web Capabilities:\n$probeResult');
      } catch (e) {
        buffer.writeln('JS Probe Error: $e');
      }
    }

    final report = buffer.toString();
    ref.read(debugLogProvider.notifier).addConsoleLog(report, 'INFO');

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Posting Capability Probe'),
          content: SingleChildScrollView(
            child: Text(
              report,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: report));
                Navigator.of(ctx).pop();
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
