import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sss/core/database/app_database.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/features/orders/data/datasources/sap_invoice_datasource.dart';
import 'package:sss/core/services/sap_auth_service.dart';

class SapInvoicesScreen extends StatefulWidget {
  const SapInvoicesScreen({super.key});

  @override
  State<SapInvoicesScreen> createState() => _SapInvoicesScreenState();
}

class _SapInvoicesScreenState extends State<SapInvoicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<Map<String, dynamic>>> _invoicesFuture;
  final SapInvoiceDataSource _sapInvoiceDataSource =
      getIt<SapInvoiceDataSource>();
  final SapAuthService _sapAuthService = getIt<SapAuthService>();

  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _showAllInvoices = false;
  String? _activeCardCode;

  // Failed‑sync panel state
  bool _isRetryingAll = false;
  final Set<String> _retryingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── A/R Invoices tab ─────────────────────────────────────────────────────

  void _loadInvoices() {
    setState(() {
      _invoicesFuture = _computeInvoicesFuture();
    });
  }

  Future<List<Map<String, dynamic>>> _computeInvoicesFuture() async {
    final hasSession = await _sapAuthService.ensureSession();
    if (!hasSession) return [];

    final activeCode = await _sapAuthService.getActiveCardCode();
    if (mounted) setState(() => _activeCardCode = activeCode);

    return _sapInvoiceDataSource.getInvoices(
      skip: _currentPage * _pageSize,
      cardCode: _showAllInvoices ? null : activeCode,
    );
  }

  void _nextPage() => setState(() {
        _currentPage++;
        _loadInvoices();
      });

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _loadInvoices();
      });
    }
  }

  void _showInvoiceDetails(int docEntry, String docNum) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
        future: _sapInvoiceDataSource.getInvoiceDetails(docEntry),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final details = snapshot.data;
          if (details == null) {
            return AlertDialog(
              title: Text('Invoice #$docNum'),
              content: const Text(
                  'Failed to load item details from SAP Business One.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            );
          }
          final lines = details['DocumentLines'] as List<dynamic>? ?? [];
          final currency = details['DocCurrency'] ?? 'KSh';
          return AlertDialog(
            title: Text('Invoice #$docNum Details'),
            content: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: lines.map((line) {
                          return ListTile(
                            title: Text(
                              line['ItemDescription'] ??
                                  line['ItemCode'] ??
                                  'Unknown Item',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Quantity: ${line['Quantity']}'),
                            trailing: Text('$currency ${line['Price']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$currency ${details['DocTotal']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  // ── Failed Syncs tab ─────────────────────────────────────────────────────

  /// Retry a single failed order using the datasource helper.
  Future<void> _retrySingleOrder(Order order) async {
    if (_retryingIds.contains(order.id) || _isRetryingAll) return;
    setState(() => _retryingIds.add(order.id));
    try {
      await _sapInvoiceDataSource.retrySingleOrder(order);
    } finally {
      if (mounted) setState(() => _retryingIds.remove(order.id));
    }
  }

  Future<void> _retryAll() async {
    if (_isRetryingAll) return;
    setState(() => _isRetryingAll = true);
    try {
      await _sapInvoiceDataSource.retryFailedSyncs();
    } finally {
      if (mounted) setState(() => _isRetryingAll = false);
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel SAP Sync'),
        content: Text(
            'Stop retrying order ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}?\n\n'
            'It will no longer be sent to SAP Business One.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep retrying')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Cancel sync',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _sapInvoiceDataSource.cancelOrderSync(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Order ${order.id.length > 8 ? order.id.substring(0, 8) : order.id} removed from retry queue.'),
            backgroundColor: Colors.orange[800],
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar header ──
        Container(
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1a237e),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1a237e),
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long), text: 'A/R Invoices'),
              Tab(icon: Icon(Icons.sync_problem), text: 'Failed Syncs'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInvoicesTab(),
              _buildFailedSyncsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── A/R Invoices tab widget ───────────────────────────────────────────────

  Widget _buildInvoicesTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SAP A/R Invoices',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e))),
                  SizedBox(height: 4),
                  Text('Recent invoices synced with SAP Business One',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  Text(
                    _showAllInvoices ? 'All Invoices' : 'Active Customer',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showAllInvoices,
                    activeThumbColor: const Color(0xFF1a237e),
                    activeTrackColor:
                        const Color(0xFF1a237e).withValues(alpha: 0.4),
                    onChanged: (val) {
                      setState(() {
                        _showAllInvoices = val;
                        _currentPage = 0;
                        _loadInvoices();
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadInvoices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a237e),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!_showAllInvoices && _activeCardCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Filtering for: $_activeCardCode',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _invoicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }
                final invoices = snapshot.data ?? [];
                if (invoices.isEmpty) {
                  return const Center(
                      child: Text('No invoices found.',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey)));
                }
                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final docNum =
                        invoice['DocNum']?.toString() ?? 'Unknown';
                    final cardCode = invoice['CardCode'] ?? 'Unknown';
                    final cardName = invoice['CardName'] ?? 'No Name';
                    final docDate =
                        invoice['DocDate']?.toString() ?? '';
                    final docTotal =
                        invoice['DocTotal']?.toString() ?? '0.0';
                    final status = invoice['DocumentStatus'] ?? '';
                    final statusColor = status == 'bost_Close'
                        ? Colors.green
                        : Colors.blue;
                    final statusText = status == 'bost_Close'
                        ? 'Closed'
                        : status == 'bost_Open'
                            ? 'Open'
                            : status;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          final docEntry = invoice['DocEntry'];
                          if (docEntry != null) {
                            _showInvoiceDetails(
                                docEntry as int, docNum);
                          }
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1a237e)
                                .withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt_long,
                                color: Color(0xFF1a237e)),
                          ),
                          title: Text('Invoice #$docNum',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Customer: $cardName ($cardCode)'),
                              Text('Date: $docDate'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  '${invoice['DocCurrency'] ?? 'KSh'} $docTotal',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                child: Text(statusText,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage == 0 ? null : _previousPage,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Page ${_currentPage + 1}',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: _nextPage,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Failed Syncs tab widget ───────────────────────────────────────────────

  Widget _buildFailedSyncsTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Failed SAP Syncs',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e))),
                  SizedBox(height: 4),
                  Text(
                      'Orders that could not be synced to SAP Business One',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isRetryingAll ? null : _retryAll,
                icon: _isRetryingAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.replay),
                label: Text(_isRetryingAll ? 'Retrying all…' : 'Retry All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a237e),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  disabledBackgroundColor:
                      const Color(0xFF1a237e).withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Retrying banner
          if (_isRetryingAll) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.orange)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Retrying all failed orders one by one… '
                      'Manual retries are queued and will run after the current one finishes.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Live list
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _sapInvoiceDataSource.watchFailedOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green[400]),
                        const SizedBox(height: 16),
                        const Text('All orders are synced ✓',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        const Text(
                            'No failed SAP syncs at the moment.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _FailedSyncTile(
                    order: orders[index],
                    isRetrying: _retryingIds.contains(orders[index].id),
                    isRetryingAll: _isRetryingAll,
                    onRetry: () => _retrySingleOrder(orders[index]),
                    onCancel: () => _cancelOrder(orders[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Failed Sync Tile ────────────────────────────────────────────────────────

class _FailedSyncTile extends StatelessWidget {
  const _FailedSyncTile({
    required this.order,
    required this.isRetrying,
    required this.isRetryingAll,
    required this.onRetry,
    required this.onCancel,
  });

  final Order order;
  final bool isRetrying;
  final bool isRetryingAll;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy  HH:mm');
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final busy = isRetrying || isRetryingAll;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Colors.red[50],
          child: isRetrying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.red))
              : const Icon(Icons.sync_problem, color: Colors.red),
        ),
        title: Text('Order $shortId',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Total: KES ${order.totalAmount.toStringAsFixed(2)}'),
            if (order.customerPhone != null &&
                order.customerPhone!.isNotEmpty)
              Text('Phone: ${order.customerPhone}'),
            Text('Date: ${fmt.format(order.createdAt)}'),
            if (order.sapCardCode != null &&
                order.sapCardCode!.isNotEmpty)
              Text('Customer: ${order.sapCardCode}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Retry button
            Tooltip(
              message: busy ? 'Retry in progress…' : 'Retry now',
              child: IconButton(
                onPressed: busy ? null : onRetry,
                icon: const Icon(Icons.play_circle_outline),
                color: const Color(0xFF1a237e),
                iconSize: 28,
              ),
            ),
            const SizedBox(width: 4),
            // Cancel button
            Tooltip(
              message: 'Cancel — stop retrying this order',
              child: IconButton(
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined),
                color: Colors.red[700],
                iconSize: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
