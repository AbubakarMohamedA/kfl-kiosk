import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';

class ReceiptScreenDesktop extends StatefulWidget {
  final String language;
  final Order order;

  const ReceiptScreenDesktop({
    super.key,
    required this.language,
    required this.order,
  });

  @override
  State<ReceiptScreenDesktop> createState() => _ReceiptScreenDesktopState();
}

class _ReceiptScreenDesktopState extends State<ReceiptScreenDesktop> {
  Color _primaryColor = const Color(AppColors.primaryBlue);
  Color _secondaryColor = const Color(AppColors.secondaryGold);
  StreamSubscription? _configSubscription;

  @override
  void initState() {
    super.initState();
    _setupStream();
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupStream() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString('last_synced_tenant_id');
    if (tenantId != null) {
      _configSubscription?.cancel();
      _configSubscription = getIt<TenantConfigDao>().watchConfig(tenantId).listen((config) {
        if (config != null && mounted) {
          setState(() {
            if (config.primaryColor != null) {
              _primaryColor = Color(config.primaryColor!);
            }
            if (config.secondaryColor != null) {
              _secondaryColor = Color(config.secondaryColor!);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor, Colors.white],
            stops: const [0.25, 0.25],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double h = constraints.maxHeight;
              final double w = constraints.maxWidth;

              // ── Adaptive font sizes (scale with height) ──
              final double successFont = h < 600
                  ? 20
                  : h < 800
                  ? 24
                  : h < 1000
                  ? 28
                  : 32;
              final double companyFont = h < 600
                  ? 16
                  : h < 800
                  ? 18
                  : h < 1000
                  ? 20
                  : 24;
              final double subLabelFont = h < 600
                  ? 11
                  : h < 800
                  ? 12
                  : h < 1000
                  ? 14
                  : 16;
              final double detailFont = h < 600
                  ? 12
                  : h < 800
                  ? 13
                  : h < 1000
                  ? 15
                  : 17;
              final double itemFont = h < 600
                  ? 12
                  : h < 800
                  ? 13
                  : h < 1000
                  ? 14
                  : 15;
              final double totalLabelFont = h < 600
                  ? 16
                  : h < 800
                  ? 18
                  : h < 1000
                  ? 20
                  : 24;
              final double totalValueFont = h < 600
                  ? 18
                  : h < 800
                  ? 20
                  : h < 1000
                  ? 24
                  : 28;
              final double infoTitleFont = h < 600
                  ? 12
                  : h < 800
                  ? 13
                  : h < 1000
                  ? 14
                  : 16;
              final double infoBodyFont = h < 600
                  ? 11
                  : h < 800
                  ? 12
                  : h < 1000
                  ? 13
                  : 15;
              final double autoReturnFont = h < 600
                  ? 10
                  : h < 800
                  ? 11
                  : h < 1000
                  ? 12
                  : 13;

              // ── Adaptive icon sizes ──
              final double checkIconSize = h < 600
                  ? 36
                  : h < 800
                  ? 44
                  : h < 1000
                  ? 52
                  : 64;
              final double checkPad = h < 600
                  ? 6
                  : h < 800
                  ? 8
                  : h < 1000
                  ? 12
                  : 16;
              final double infoIconSize = h < 600
                  ? 18
                  : h < 800
                  ? 22
                  : h < 1000
                  ? 26
                  : 32;

              // ── Adaptive paddings ──
              final double cardPad = h < 600
                  ? 10
                  : h < 800
                  ? 16
                  : h < 1000
                  ? 22
                  : 32;
              final double totalBoxPad = h < 600
                  ? 6
                  : h < 800
                  ? 8
                  : h < 1000
                  ? 12
                  : 16;
              final double infoPad = h < 600
                  ? 6
                  : h < 800
                  ? 8
                  : h < 1000
                  ? 12
                  : 16;

              // ── Small fixed gaps (kept minimal; big gaps handled by Spacer) ──
              final double tinyGap = h < 600
                  ? 2
                  : h < 800
                  ? 3
                  : 4;
              final double smallGap = h < 600
                  ? 3
                  : h < 800
                  ? 5
                  : 6;

              final double maxCardWidth = w < 500 ? w - 24 : 680;

              return Center(
                child: Padding(
                  padding: EdgeInsets.all(h < 600 ? 6 : 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxCardWidth,
                      // Let the card fill the full safe-area height so Column
                      // can distribute space with Spacer.
                      maxHeight: h,
                    ),
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(h < 600 ? 10 : 18),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(cardPad),
                        child: Column(
                          // KEY FIX: max forces Column to fill available height;
                          // Spacer widgets then distribute the leftover evenly.
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Success Icon ──
                            Container(
                              padding: EdgeInsets.all(checkPad),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: checkIconSize,
                                color: _primaryColor,
                              ),
                            ),
                            SizedBox(height: smallGap),

                            // ── Success Message ──
                            Text(
                              AppStrings.get(
                                'payment_success',
                                widget.language,
                              ),
                              style: TextStyle(
                                fontSize: successFont,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),

                            // ── Spacer 1 — between success header & company ──
                            const Spacer(),

                            // ── Company Header ──
                            Text(
                              'SSS',
                              style: TextStyle(
                                fontSize: companyFont,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: tinyGap),
                            Text(
                              'RECEIPT',
                              style: TextStyle(
                                fontSize: subLabelFont,
                                color: Colors.grey,
                                letterSpacing: 2,
                              ),
                            ),

                            // ── Spacer 2 ──
                            const Spacer(),

                            Divider(thickness: 1.5, color: Colors.grey[300]),

                            // ── Spacer 3 ──
                            const Spacer(),

                            // ── Order Details ──
                            _detailRow(
                              'Order ID:',
                              widget.order.id,
                              detailFont,
                            ),
                            SizedBox(height: smallGap),
                            _detailRow(
                              'Date:',
                              '${widget.order.timestamp.day}/${widget.order.timestamp.month}/${widget.order.timestamp.year}',
                              detailFont,
                            ),
                            SizedBox(height: smallGap),
                            _detailRow(
                              'Time:',
                              '${widget.order.timestamp.hour.toString().padLeft(2, '0')}:${widget.order.timestamp.minute.toString().padLeft(2, '0')}',
                              detailFont,
                            ),

                            // ── Spacer 4 ──
                            const Spacer(),

                            Divider(thickness: 1.5, color: Colors.grey[300]),

                            // ── Spacer 5 ──
                            const Spacer(),

                            // ── Items Header ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ITEMS',
                                  style: TextStyle(
                                    fontSize: itemFont,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'AMOUNT',
                                  style: TextStyle(
                                    fontSize: itemFont,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: smallGap),

                            // ── Order Items ──
                            ...widget.order.items.map(
                              (item) => Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: tinyGap,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.product.name} (${item.product.size}) x${item.quantity}',
                                        style: TextStyle(fontSize: itemFont),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'KSh ${item.subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: itemFont,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── Spacer 6 ──
                            const Spacer(),

                            Divider(thickness: 1.5, color: Colors.grey[300]),

                            // ── Spacer 7 ──
                            const Spacer(),

                            // ── Total Box ──
                            Container(
                              padding: EdgeInsets.all(totalBoxPad),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _primaryColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL:',
                                    style: TextStyle(
                                      fontSize: totalLabelFont,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'KSh ${widget.order.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: totalValueFont,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Spacer 8 ──
                            const Spacer(),

                            // ── Pickup Instructions ──
                            Container(
                              padding: EdgeInsets.all(infoPad),
                              decoration: BoxDecoration(
                                color: _secondaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _secondaryColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: infoIconSize,
                                    color: _secondaryColor,
                                  ),
                                  SizedBox(height: tinyGap),
                                  Text(
                                    AppStrings.get(
                                      'order_preparing',
                                      widget.language,
                                    ),
                                    style: TextStyle(
                                      fontSize: infoTitleFont,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: tinyGap),
                                  Text(
                                    '${AppStrings.get('show_order_id', widget.language)} ${widget.order.id} ${AppStrings.get('at_pickup', widget.language)}',
                                    style: TextStyle(fontSize: infoBodyFont),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            // ── Spacer 9 (last, small) ──
                            const Spacer(),

                            // ── Auto-return message ──
                            Text(
                              'This screen will automatically return to the home screen in a few seconds',
                              style: TextStyle(
                                fontSize: autoReturnFont,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Reusable label → value row for Order ID / Date / Time.
  static Widget _detailRow(String label, String value, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
