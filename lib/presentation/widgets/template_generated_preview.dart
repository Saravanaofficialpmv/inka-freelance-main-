import 'package:flutter/material.dart';

/// Renders a razor-sharp, high-definition vector preview for any of the 14 Inka invoice templates.
/// Replaces low-resolution compressed asset photos with clean, generated, native vector graphics.
class TemplateGeneratedPreview extends StatelessWidget {
  final String templateId;
  final bool isZoomed;

  const TemplateGeneratedPreview({
    super.key,
    required this.templateId,
    this.isZoomed = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = _resolveAssetPath(templateId);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isZoomed ? 12 : 4),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              child: _buildLayout(context),
            ),
          );
        },
      ),
    );
  }

  static String _resolveAssetPath(String id) {
    final mapped = switch (id) {
      'classic_corporate' => 'template_classic',
      'compact_thermal' => 'template_compact',
      'minimal_slate' => 'template_elegant',
      'bold_retail' => 'template_genz',
      'executive_ledger' => 'template_legend',
      'modern_clean' => 'template_modern',
      'split_invoice' => 'template_professional',
      'creative_freelance' => 'template_service',
      'gradient_flow' => 'template_service_2',
      'tech_dark' => 'template_vintage',
      _ => id.startsWith('template_') ? id : 'template_$id',
    };
    return 'assets/templates/$mapped.jpg';
  }

  Widget _buildLayout(BuildContext context) {
    switch (templateId) {
      case 'template_billto_shipto':
        return _buildBillToShipToLayout();
      case 'template_classic':
      case 'classic_corporate':
        return _buildClassicLayout();
      case 'template_compact':
      case 'compact_thermal':
        return _buildCompactLayout();
      case 'template_elegant':
      case 'minimal_slate':
        return _buildElegantLayout();
      case 'template_elegant_images':
        return _buildElegantImagesLayout();
      case 'template_evergreen':
        return _buildEvergreenLayout();
      case 'template_genz':
      case 'bold_retail':
        return _buildGenzLayout();
      case 'template_legend':
      case 'executive_ledger':
        return _buildLegendLayout();
      case 'template_modern':
      case 'modern_clean':
        return _buildModernLayout();
      case 'template_mrp_discount':
        return _buildMrpDiscountLayout();
      case 'template_professional':
      case 'split_invoice':
        return _buildProfessionalLayout();
      case 'template_service':
      case 'creative_freelance':
        return _buildServiceLayout();
      case 'template_service_2':
      case 'gradient_flow':
        return _buildService2Layout();
      case 'template_vintage':
      case 'tech_dark':
        return _buildVintageLayout();
      default:
        return _buildClassicLayout();
    }
  }

  // 1. Logistics 4-Party Layout (template_billto_shipto)
  Widget _buildBillToShipToLayout() {
    const brandColor = Color(0xFF1E40AF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('INKA LOGISTICS PVT LTD'),
                  _smallText('GSTIN: 27AAACI1234A1Z5'),
                  _smallText('BKC Executive Park, Mumbai 400051'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge('TAX INVOICE', bg: brandColor, fg: Colors.white),
                const SizedBox(height: 2),
                _smallText('INV-2024-00142', isBold: true),
                _smallText('Date: 19/10/2024'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 4-Party Grid
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _boxedPartyCell(
                      'Bill From:',
                      'Inka Logistics HQ\nMumbai, MH - 400051\nGSTIN: 27AAACI1234A1Z5',
                      borderRight: true,
                    ),
                  ),
                  Expanded(
                    child: _boxedPartyCell(
                      'Ship From:',
                      'Central Warehouse W-4\nBhiwandi, MH - 421302\nState: 27-Maharashtra',
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFCBD5E1)),
              Row(
                children: [
                  Expanded(
                    child: _boxedPartyCell(
                      'Bill To (Buyer):',
                      'Apex Global Logistics\nPune, MH - 411019\nGSTIN: 27AABCA5678B1Z2',
                      borderRight: true,
                    ),
                  ),
                  Expanded(
                    child: _boxedPartyCell(
                      'Ship To (Consignee):',
                      'Apex Pune Hub W-7\nHinjewadi, Pune - 411057\nE-Way: 841029485712',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Table
        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Item Description', 'HSN', 'Rate', 'Qty', 'Amount'],
          rows: [
            ['1', 'Barcode Scanner X-200', '847190', '₹8,500', '5', '₹42,500'],
            ['2', 'Thermal Rolls 80mm', '481190', '₹1,200', '10', '₹12,000'],
            ['3', 'Cloud POS Integration', '998314', '₹15,000', '1', '₹15,000'],
          ],
        ),
        const SizedBox(height: 8),

        // Bottom Totals & QR
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _upiQrBlock('Pay UPI: inka@hdfcbank'),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: _buildTotalsBox([
                ['Subtotal:', '₹69,500.00'],
                ['Discount:', '-₹2,000.00'],
                ['CGST (9%):', '₹5,895.00'],
                ['SGST (9%):', '₹5,895.00'],
                ['Total:', '₹79,290.00'],
              ], highlightColor: brandColor),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Classic Corporate (template_classic)
  Widget _buildClassicLayout() {
    const brandColor = Color(0xFF003399);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('INKA CORPORATION', color: brandColor),
                  _smallText('GSTIN: 27AAACI1234A1Z5'),
                  _smallText('Andheri East, Mumbai 400069'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'TAX INVOICE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: brandColor,
                    letterSpacing: 1,
                  ),
                ),
                _smallText('ORIGINAL FOR RECIPIENT'),
                _smallText('Invoice #: INV-0042', isBold: true),
                _smallText('Date: 19/10/2024'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('BILL TO:'),
                  _boldText('Samsung Enterprise Division'),
                  _smallText('Cyber City, Gurugram, Haryana'),
                  _smallText('GSTIN: 06AAACS2143B1Z1'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('SHIP TO:'),
                  _boldText('Samsung Regional Warehouse'),
                  _smallText('Plot 202, Sector 18, Gurugram'),
                  _smallText('State Code: 06-Haryana'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Item Name', 'HSN/SAC', 'Rate', 'Qty', 'Amount'],
          rows: [
            ['1', 'Display Panel 4K 55"', '852852', '₹45,000', '2', '₹90,000'],
            ['2', 'Mounting Bracket Pro', '830249', '₹2,500', '2', '₹5,000'],
            ['3', 'Installation Service', '998713', '₹5,000', '1', '₹5,000'],
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _circularSealStamp('VERIFIED\nORIGINAL'),
            SizedBox(
              width: 140,
              child: _buildTotalsBox([
                ['Taxable Value:', '₹1,00,000.00'],
                ['IGST (18%):', '₹18,000.00'],
                ['Total:', '₹1,18,000.00'],
              ], highlightColor: brandColor),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Compact Retail Grid (template_compact)
  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _brandTitle('BIG MART RETAIL STORES', size: 10),
        _smallText('GSTIN: 27AABCM9876C1Z8 | FSSAI: 11519018000412'),
        _smallText('Linking Road, Bandra West, Mumbai - 400050'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(3),
          ),
          child: _smallText('TAX INVOICE / POS RECEIPT • INV-98124', isBold: true),
        ),
        const SizedBox(height: 6),

        _buildBorderedGridTable(
          columns: ['#', 'Item', 'Qty', 'Rate', 'Total'],
          rows: [
            ['1', 'Organic Basmati 5kg', '2 NOS', '₹650', '₹1,300'],
            ['2', 'Cold Pressed Oil 1L', '3 BTL', '₹280', '₹840'],
            ['3', 'Arabica Coffee 500g', '1 PKT', '₹450', '₹450'],
          ],
        ),
        const SizedBox(height: 6),

        // Mini GST Breakdown
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('GST TAX SUMMARY:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _smallText('HSN 1006 (5%): CGST+SGST'),
                  ),
                  _smallText('₹65.00'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _smallText('HSN 1515 (12%): CGST+SGST'),
                  ),
                  _smallText('₹154.80'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _barcodeBox('8901234567890'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _smallText('Net Payable: ₹2,590.00', isBold: true),
                _smallText('Total Savings: ₹320.00', color: Colors.green),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 4. Elegant Minimalist (template_elegant)
  Widget _buildElegantLayout() {
    const brandColor = Color(0xFF111827);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('NIKE ATHLETICS INDIA', size: 11),
                  _smallText('GSTIN: 27AABCN1234D1Z9'),
                  _smallText('DLF Cyber City, Tower 10, Gurugram'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'TAX INVOICE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: brandColor,
                  ),
                ),
                _smallText('ORIGINAL FOR RECIPIENT'),
                _smallText('Inv: #NK-90214', isBold: true),
                _smallText('Date: 19/10/2024'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('BILL TO'),
                  _boldText('Rahul Deshmukh'),
                  _smallText('Bandra West, Mumbai 400050'),
                  _smallText('Phone: +91 98201 12345'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('SHIP TO'),
                  _boldText('Rahul Deshmukh (Personal)'),
                  _smallText('Flat 402, Sea Green Apts, Mumbai'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Item Description', 'HSN', 'Rate', 'Qty', 'Amount'],
          rows: [
            ['1', 'Air Zoom Pegasus 40', '640411', '₹11,895', '1', '₹11,895'],
            ['2', 'Dri-FIT Running Tee', '610910', '₹2,495', '2', '₹4,990'],
            ['3', 'Elite Cushion Socks', '611595', '₹995', '3', '₹2,985'],
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _smallText('Authorized Signatory\nNike Athletics India Pvt Ltd')),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: _buildTotalsBox([
                ['Subtotal:', '₹19,870.00'],
                ['GST (18%):', '₹3,576.60'],
                ['Total:', '₹23,446.60'],
              ], highlightColor: brandColor),
            ),
          ],
        ),
      ],
    );
  }

  // 5. Elegant Product Visual (template_elegant_images)
  Widget _buildElegantImagesLayout() {
    const brandColor = Color(0xFF1F2937);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('LIFESTYLE STUDIOS'),
                  _smallText('GSTIN: 27AABCL7890E1Z3'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _badge('PRODUCT INVOICE', bg: brandColor, fg: Colors.white),
          ],
        ),
        const SizedBox(height: 6),

        _buildTableWithThumbnails(
          headerColor: brandColor,
          columns: ['#', 'Photo', 'Product Name', 'Price', 'Qty', 'Total'],
          rows: [
            ['1', 'IMG', 'Air Max Flyknit 2024', '₹14,995', '1', '₹14,995'],
            ['2', 'IMG', 'Windrunner Tech Jacket', '₹8,495', '1', '₹8,495'],
            ['3', 'IMG', 'Commuter Backpack 30L', '₹4,295', '1', '₹4,295'],
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _upiQrBlock('Scan & Pay UPI')),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: _buildTotalsBox([
                ['Subtotal:', '₹27,785.00'],
                ['Tax (12%):', '₹3,334.20'],
                ['Total:', '₹31,119.20'],
              ], highlightColor: brandColor),
            ),
          ],
        ),
      ],
    );
  }

  // 6. Evergreen Corporate (template_evergreen)
  Widget _buildEvergreenLayout() {
    const brandColor = Color(0xFF0D5C3A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: brandColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TAX INVOICE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'ORIGINAL FOR RECIPIENT',
                style: TextStyle(color: Colors.white, fontSize: 7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 2x2 Boxed info
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _boldText('Hindustan Unilever Limited'),
                  _smallText('GSTIN: 27AAACH1234F1Z0'),
                  _smallText('Andheri West, Mumbai'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _smallText('Inv No: HUL/2024/0912', isBold: true),
                  _smallText('Date: 19/10/2024'),
                  _smallText('Place of Supply: 27-Maharashtra'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Goods Description', 'HSN', 'Rate', 'Qty', 'Amount'],
          rows: [
            ['1', 'Dove Care Shampoo 650ml', '330510', '₹450', '24', '₹10,800'],
            ['2', 'Lifebuoy Handwash 5L', '340120', '₹750', '10', '₹7,500'],
            ['3', 'Surf Excel Matic Liquid 4L', '340220', '₹850', '8', '₹6,800'],
          ],
        ),
        const SizedBox(height: 6),

        _buildGstSummaryTable(headerColor: brandColor),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _smallText('Amount: Twenty-Nine Thousand\nSix Hundred Twenty-Eight Only')),
            const SizedBox(width: 8),
            _boldText('Total: ₹29,628.00', color: brandColor),
          ],
        ),
      ],
    );
  }

  // 7. Gen-Z Modern (template_genz)
  Widget _buildGenzLayout() {
    const brandColor = Color(0xFF1A73E8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rounded Top Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: brandColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('GZ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1A73E8))),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'STUDIO GEN-Z',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              _badge('TAX INVOICE', bg: Colors.white, fg: brandColor),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Rounded Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('CUSTOMER:'),
                    _boldText('Aarav Mehta'),
                    _smallText('Bandra, Mumbai'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('INVOICE:'),
                    _boldText('#GZ-2024-88', color: brandColor),
                    _smallText('Date: 19/10/2024'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        _buildTableWithThumbnails(
          headerColor: const Color(0xFFF1F5F9),
          headerTextColor: const Color(0xFF334155),
          columns: ['#', 'Photo', 'Item', 'Rate', 'Qty', 'Amount'],
          rows: [
            ['1', 'P-1', 'Wireless Studio ANC', '₹9,999', '1', '₹9,999'],
            ['2', 'P-2', 'Smart Fitness Band Pro', '₹4,499', '2', '₹8,998'],
          ],
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _badge('Scan & Pay via UPI', bg: const Color(0xFFEFF6FF), fg: brandColor)),
            const SizedBox(width: 8),
            _boldText('Total: ₹18,997.00', color: brandColor, size: 12),
          ],
        ),
      ],
    );
  }

  // 8. Legend B2B e-Invoice (template_legend)
  Widget _buildLegendLayout() {
    const brandColor = Color(0xFF0F2C59);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IRN Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: brandColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'e-INVOICE / TAX INVOICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ORIGINAL FOR RECIPIENT',
                style: TextStyle(color: Colors.white, fontSize: 7),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: const Color(0xFFF1F5F9),
          child: const Text(
            'IRN: 4a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
            style: TextStyle(fontFamily: 'monospace', fontSize: 6.5, color: Color(0xFF334155)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('ITC LIMITED - B2B DIVISION'),
                  _smallText('GSTIN: 19AAACI1234G1Z2'),
                  _smallText('Virginia House, Kolkata 700071'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _qrCodePlaceholder('e-INV QR', size: 36),
          ],
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Goods Description', 'HSN', 'Rate', 'Qty', 'Total'],
          rows: [
            ['1', 'Aashirvaad Atta 10kg', '110100', '₹420', '50', '₹21,000'],
            ['2', 'Sunfeast Dark Fantasy 300g', '190531', '₹120', '100', '₹12,000'],
          ],
        ),
        const SizedBox(height: 6),

        _buildGstSummaryTable(headerColor: brandColor),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _smallText('Ack No: 11234567890 | Date: 19/10/2024')),
            const SizedBox(width: 8),
            _boldText('Total: ₹33,000.00', color: brandColor),
          ],
        ),
      ],
    );
  }

  // 9. Modern Document (template_modern)
  Widget _buildModernLayout() {
    const brandColor = Color(0xFF131921);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAX INVOICE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: brandColor,
                    ),
                  ),
                  _smallText('Invoice #: INV-AMZ-9921', isBold: true),
                  _smallText('Invoice Date: 19/10/2024'),
                  _smallText('Place: 27-Maharashtra'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _brandTitle('CLOUD RETAIL'),
                  _smallText('SOLD BY: Cloud Retail Pvt Ltd'),
                  _smallText('GSTIN: 27AAACC4321H1Z4'),
                  _smallText('Kurla West, Mumbai 400070'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('BILLING ADDRESS:'),
                  _boldText('Vikramaditya Rao'),
                  _smallText('Powai Lake Road, Mumbai 400076'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('SHIPPING ADDRESS:'),
                  _boldText('Vikramaditya Rao'),
                  _smallText('Hiranandani Gardens, Mumbai 400076'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: const Color(0xFFF8FAFC),
          headerTextColor: const Color(0xFF0F172A),
          columns: ['#', 'Description', 'Unit Price', 'Qty', 'Tax', 'Total'],
          rows: [
            ['1', 'Echo Dot 5th Gen (Smart Speaker)', '₹4,499', '1', '18%', '₹4,499'],
            ['2', 'Fire TV Stick 4K Max', '₹5,999', '1', '18%', '₹5,999'],
            ['3', 'Kindle Paperwhite 16GB', '₹13,999', '1', '18%', '₹13,999'],
          ],
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _upiQrBlock('Pay via UPI QR')),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: _buildTotalsBox([
                ['Subtotal:', '₹20,760.00'],
                ['Tax (18%):', '₹3,737.00'],
                ['Total:', '₹24,497.00'],
              ], highlightColor: brandColor),
            ),
          ],
        ),
      ],
    );
  }

  // 10. Retail MRP & Discount (template_mrp_discount)
  Widget _buildMrpDiscountLayout() {
    const brandColor = Color(0xFF15803D);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('SUPER DISCOUNT MART'),
                  _smallText('GSTIN: 27AABCD3456K1Z9'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _badge('RETAIL TAX INVOICE', bg: const Color(0xFF1E293B), fg: Colors.white),
          ],
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: const Color(0xFF1E293B),
          columns: ['#', 'Item', 'MRP', 'Offer', 'Qty', 'Savings', 'Net'],
          rows: [
            ['1', 'Bournvita 1kg Jar', '₹450', '₹380', '2', '₹140', '₹760'],
            ['2', 'Fortune Oil 5L Can', '₹890', '₹720', '1', '₹170', '₹720'],
            ['3', 'Basmati Rice 5kg', '₹600', '₹480', '2', '₹240', '₹960'],
          ],
        ),
        const SizedBox(height: 6),

        // Highlighted Savings Banner (DMart style)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL SAVINGS ON THIS BILL:',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: brandColor,
                ),
              ),
              Text(
                '₹550.00',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: brandColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _smallText('Items: 3 | Total Qty: 5')),
            const SizedBox(width: 8),
            _boldText('Net Payable: ₹2,440.00', size: 11),
          ],
        ),
      ],
    );
  }

  // 11. Professional 3-Column (template_professional)
  Widget _buildProfessionalLayout() {
    const brandColor = Color(0xFF1E3A8A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _brandTitle('MARICO COMMERCIAL CORP')),
            const SizedBox(width: 8),
            const Text(
              'TAX INVOICE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: brandColor),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 3-Column Header
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('SUPPLIER:'),
                    _boldText('Marico Ltd'),
                    _smallText('GSTIN: 27AAACM1234L1Z7'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('RECEIVER:'),
                    _boldText('Prime Retailers'),
                    _smallText('GSTIN: 27AABCP5678M1Z8'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('DISPATCH INFO:'),
                    _smallText('Inv: #MCC-8812'),
                    _smallText('Vehicle: MH-04-AB-1234'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Description', 'HSN', 'Rate', 'Qty', 'Total'],
          rows: [
            ['1', 'Parachute Coconut Oil 500ml', '151311', '₹185', '48', '₹8,880'],
            ['2', 'Saffola Gold Oil 5L', '151790', '₹920', '12', '₹11,040'],
          ],
        ),
        const SizedBox(height: 8),

        // Dual Signatures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 1, color: Colors.grey),
                _smallText("Receiver's Signature"),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(width: 80, height: 1, color: Colors.grey),
                _smallText('Authorized Signatory'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 12. Creative Agency Service (template_service)
  Widget _buildServiceLayout() {
    const brandColor = Color(0xFFE1306C); // Hot Magenta
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('PIXEL & POST AGENCY'),
                  _smallText('Digital Marketing & Creative Studio'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _badge('SERVICE INVOICE', bg: brandColor, fg: Colors.white),
          ],
        ),
        const SizedBox(height: 6),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFCE7F3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('ENGAGEMENT CLIENT:'),
                    _boldText('Urban Lifestyle Brands'),
                    _smallText('Project: Q4 Festive Brand Campaign'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _label('CATEGORY:'),
                  _smallText('SAC Code: 998311'),
                  _smallText('Due: Net 15 Days'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Deliverables / Scope', 'SAC', 'Rate', 'Units', 'Amount'],
          rows: [
            ['1', 'Brand Strategy & Campaign Direction', '998311', '₹45,000', '1', '₹45,000'],
            ['2', 'Reels Production (Set of 8)', '998311', '₹8,000', '8', '₹64,000'],
            ['3', 'Performance Marketing Management', '998311', '₹25,000', '1', '₹25,000'],
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _upiQrBlock('Pay via UPI')),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: _buildTotalsBox([
                ['Subtotal:', '₹1,34,000.00'],
                ['GST (18%):', '₹24,120.00'],
                ['Payable:', '₹1,58,120.00'],
              ], highlightColor: brandColor),
            ),
          ],
        ),
      ],
    );
  }

  // 13. IT Consulting & Tech (template_service_2)
  Widget _buildService2Layout() {
    const brandColor = Color(0xFF004B6E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('COGNIZANT TECH CONSULTING'),
                  _smallText('GSTIN: 27AABCC8812N1Z3'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CONSULTING INVOICE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: brandColor),
            ),
          ],
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Milestone / Deliverable', 'SAC', 'Rate/Hr', 'Hours', 'Amount'],
          rows: [
            ['1', 'Enterprise Cloud Migration Sprint 3', '998314', '₹2,500', '40 hrs', '₹1,00,000'],
            ['2', 'Microservices API Development', '998314', '₹2,500', '32 hrs', '₹80,000'],
            ['3', 'Security Audit & Compliance', '998314', '₹3,000', '10 hrs', '₹30,000'],
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 90, height: 1, color: Colors.grey),
                  _smallText('Client Acceptance Signature'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: _buildTotalsBox([
                ['Consulting Fee:', '₹2,10,000.00'],
                ['GST (18%):', '₹37,800.00'],
                ['Net Total:', '₹2,47,800.00'],
              ], highlightColor: brandColor),
            ),
          ],
        ),
      ],
    );
  }

  // 14. Vintage Industrial (template_vintage)
  Widget _buildVintageLayout() {
    const brandColor = Color(0xFF005A9C); // Tata Blue
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: brandColor,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TAX INVOICE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9),
              ),
              Text(
                'ORIGINAL FOR RECIPIENT',
                style: TextStyle(color: Colors.white, fontSize: 7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandTitle('TATA MOTORS INDUSTRIAL'),
                  _smallText('GSTIN: 27AAACT1234P1Z4'),
                  _smallText('Bombay House, Fort, Mumbai 400001'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _smallText('Invoice #: TM/24/0912\nDate: 19/10/2024'),
          ],
        ),
        const SizedBox(height: 6),

        _buildTable(
          headerColor: brandColor,
          columns: ['#', 'Item Description', 'HSN', 'Rate', 'Qty', 'Amount'],
          rows: [
            ['1', 'Heavy Duty Axle Assembly 16T', '870850', '₹85,000', '2', '₹1,70,000'],
            ['2', 'Pneumatic Brake Kit Pro', '870830', '₹18,500', '4', '₹74,000'],
          ],
        ),
        const SizedBox(height: 6),

        _buildGstSummaryTable(headerColor: brandColor),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _smallText('Statutory Declaration:\nCertified true and correct.')),
            const SizedBox(width: 8),
            _boldText('Total: ₹2,87,920.00', color: brandColor),
          ],
        ),
      ],
    );
  }

  // ── Helper Widgets for Razor-Sharp Layout Components ──

  static Widget _brandTitle(String title, {Color color = const Color(0xFF0F172A), double size = 11}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -0.2,
      ),
    );
  }

  static Widget _boldText(String text, {Color color = const Color(0xFF0F172A), double size = 8.5}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }

  static Widget _smallText(String text, {bool isBold = false, Color color = const Color(0xFF64748B)}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 7.5,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        color: color,
        height: 1.25,
      ),
    );
  }

  static Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 6.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  static Widget _badge(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  static Widget _boxedPartyCell(String title, String body, {bool borderRight = false}) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: borderRight ? const Border(right: BorderSide(color: Color(0xFFCBD5E1), width: 0.8)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),
          const SizedBox(height: 1),
          _smallText(body),
        ],
      ),
    );
  }

  static Widget _buildTable({
    required Color headerColor,
    Color headerTextColor = Colors.white,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(4.5),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2.2),
          4: FlexColumnWidth(1.4),
          5: FlexColumnWidth(2.6),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: headerColor),
            children: columns.map((col) {
              final isRight = col == 'Rate' || col == 'Amount' || col == 'Total' || col == 'Price';
              final isCenter = col == '#' || col == 'Qty' || col == 'HSN' || col == 'SAC';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                child: Text(
                  col,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: headerTextColor,
                  ),
                  textAlign: isRight ? TextAlign.right : (isCenter ? TextAlign.center : TextAlign.left),
                ),
              );
            }).toList(),
          ),
          ...rows.map((row) {
            return TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.8)),
              ),
              children: row.asMap().entries.map((entry) {
                final idx = entry.key;
                final val = entry.value;
                final isRight = idx >= row.length - 2 && (val.contains('₹') || val.contains('%'));
                final isCenter = idx == 0 || idx == 2 || idx == 4;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text(
                    val,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: idx == row.length - 1 ? FontWeight.w700 : FontWeight.w500,
                      color: idx == 1 ? const Color(0xFF0F172A) : const Color(0xFF475569),
                    ),
                    textAlign: isRight ? TextAlign.right : (isCenter ? TextAlign.center : TextAlign.left),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildTableWithThumbnails({
    required Color headerColor,
    Color headerTextColor = Colors.white,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(4.5),
          3: FlexColumnWidth(2.2),
          4: FlexColumnWidth(1.4),
          5: FlexColumnWidth(2.6),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: headerColor),
            children: columns.map((col) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                child: Text(
                  col,
                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: headerTextColor),
                  textAlign: col == 'Amount' || col == 'Total' || col == 'Price' ? TextAlign.right : TextAlign.left,
                ),
              );
            }).toList(),
          ),
          ...rows.map((row) {
            return TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.8)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(row[0], style: const TextStyle(fontSize: 7), textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    width: 14,
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(row[1], style: const TextStyle(fontSize: 8)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text(row[2], style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text(row[3], style: const TextStyle(fontSize: 7), textAlign: TextAlign.right),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text(row[4], style: const TextStyle(fontSize: 7), textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text(row[5], style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700), textAlign: TextAlign.right),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildBorderedGridTable({
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF94A3B8), width: 0.8),
      ),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.6),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
            children: columns.map((col) {
              return Padding(
                padding: const EdgeInsets.all(3),
                child: Text(
                  col,
                  style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          ...rows.map((row) {
            return TableRow(
              children: row.map((val) {
                return Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    val,
                    style: const TextStyle(fontSize: 7),
                    textAlign: val.contains('₹') ? TextAlign.right : TextAlign.left,
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildGstSummaryTable({required Color headerColor}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
      ),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 0.6),
        children: [
          TableRow(
            decoration: BoxDecoration(color: headerColor),
            children: const [
              Padding(padding: EdgeInsets.all(2), child: Text('HSN/SAC', style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('Taxable Val', style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('CGST', style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('SGST', style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('Total Tax', style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
            ],
          ),
          const TableRow(
            children: [
              Padding(padding: EdgeInsets.all(2), child: Text('Total GST', style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('₹25,100', style: TextStyle(fontSize: 6.5), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('₹2,259', style: TextStyle(fontSize: 6.5), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('₹2,259', style: TextStyle(fontSize: 6.5), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('₹4,518', style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildTotalsBox(List<List<String>> entries, {required Color highlightColor}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: entries.map((e) {
          final isTotal = e[0].contains('Total') || e[0].contains('Payable');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    e[0],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTotal ? 7.5 : 6.5,
                      fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                      color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  e[1],
                  style: TextStyle(
                    fontSize: isTotal ? 8.5 : 6.5,
                    fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                    color: isTotal ? highlightColor : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _upiQrBlock(String label) {
    return Row(
      children: [
        _qrCodePlaceholder('UPI QR', size: 36),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _smallText(label, isBold: true),
              _smallText('Scan with GPay/PhonePe'),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _qrCodePlaceholder(String label, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xFF0F172A)),
          Text(label, style: const TextStyle(fontSize: 4.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  static Widget _circularSealStamp(String text) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF003399), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 5.5,
          fontWeight: FontWeight.w900,
          color: Color(0xFF003399),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _barcodeBox(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.barcode_reader, size: 14, color: Color(0xFF334155)),
          const SizedBox(width: 4),
          Text(code, style: const TextStyle(fontSize: 6.5, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
