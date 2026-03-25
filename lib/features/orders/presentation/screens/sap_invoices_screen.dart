import 'package:flutter/material.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/features/orders/data/datasources/sap_invoice_datasource.dart';
import 'package:sss/core/services/sap_auth_service.dart'; // NEW


class SapInvoicesScreen extends StatefulWidget {
  const SapInvoicesScreen({super.key});

  @override
  State<SapInvoicesScreen> createState() => _SapInvoicesScreenState();
}

class _SapInvoicesScreenState extends State<SapInvoicesScreen> {
  late Future<List<Map<String, dynamic>>> _invoicesFuture;
  final SapInvoiceDataSource _sapInvoiceDataSource = getIt<SapInvoiceDataSource>();
  final SapAuthService _sapAuthService = getIt<SapAuthService>(); // NEW
  
  int _currentPage = 0; // NEW
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() {
    setState(() {
      _invoicesFuture = _computeInvoicesFuture();
    });
  }

  Future<List<Map<String, dynamic>>> _computeInvoicesFuture() async {
    final creds = await _sapAuthService.loadCredentials();
    final walkInCardCode = creds['walkInCardCode'];
    return _sapInvoiceDataSource.getInvoices(
      skip: _currentPage * _pageSize,
      cardCode: walkInCardCode,
    );
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
      _loadInvoices();
    });
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _loadInvoices();
      });
    }
  }

  void _showInvoiceDetails(int docEntry, String docNum) async {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _sapInvoiceDataSource.getInvoiceDetails(docEntry),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final details = snapshot.data;
            if (details == null) {
              return AlertDialog(
                title: Text('Invoice #$docNum'),
                content: const Text('Failed to load item details from SAP Business One.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
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
                                line['ItemDescription'] ?? line['ItemCode'] ?? 'Unknown Item',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('Quantity: ${line['Quantity']}'),
                              trailing: Text(
                                '$currency ${line['Price']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
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
                          const Text(
                            'Total Amount:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '$currency ${details['DocTotal']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'SAP A/R Invoices',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a237e),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Recent invoices synced with SAP Business One',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadInvoices,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a237e),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
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
                    child: Text('Error loading invoices: ${snapshot.error}'),
                  );
                }

                final invoices = snapshot.data ?? [];

                if (invoices.isEmpty) {
                  return const Center(
                    child: Text(
                      'No invoices found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final docNum = invoice['DocNum']?.toString() ?? 'Unknown';
                    final cardCode = invoice['CardCode'] ?? 'Unknown';
                    final cardName = invoice['CardName'] ?? 'No Name';
                    final docDate = invoice['DocDate']?.toString() ?? '';
                    final docTotal = invoice['DocTotal']?.toString() ?? '0.0';
                    final status = invoice['DocumentStatus'] ?? '';

                    Color statusColor = status == 'bost_Close' ? Colors.green : Colors.blue;
                    String statusText = status == 'bost_Close' ? 'Closed' : status == 'bost_Open' ? 'Open' : status;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          final docEntry = invoice['DocEntry'];
                          if (docEntry != null) {
                            _showInvoiceDetails(docEntry as int, docNum);
                          }
                        },
                        child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1a237e).withValues(alpha:0.1),
                          child: const Icon(Icons.receipt_long, color: Color(0xFF1a237e)),
                        ),
                        title: Text(
                          'Invoice #$docNum',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Customer: $cardName ($cardCode)'),
                            Text('Date: $docDate'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${invoice['DocCurrency'] ?? 'KSh'} $docTotal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ));
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Pagination Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage == 0 ? null : _previousPage,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page ${_currentPage + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
}
