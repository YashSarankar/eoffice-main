import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../Models/receipt_by_status.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final String status;
  final List<ReceiptTable> receipts;

  ReceiptDetailScreen({
    required this.status,
    required this.receipts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4769B2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          '$status Receipts',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: receipts.isNotEmpty
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            border: TableBorder.all(color: Colors.grey),
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FixedColumnWidth(100),
              2: FixedColumnWidth(100),
              3: FixedColumnWidth(100),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFE5E5E5)),
                children: [
                  _buildTableCell('ID', isHeader: true),
                  _buildTableCell('Receipt No', isHeader: true),
                  _buildTableCell('Letter No', isHeader: true),
                  _buildTableCell('Generated Date', isHeader: true),
                ],
              ),
              ...receipts.map((receipt) {
                return TableRow(
                  children: [
                    _buildTableCell(receipt.id.toString()),
                    _buildTableCell(receipt.receiptNo.toString()),
                    _buildTableCell(receipt.letterNo),
                    _buildTableCell(receipt.dateOfGenerated),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      )
          : const Center(
        child: const Text(
          'No receipts found',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isLink = false, Function()? onTap}) {
    return GestureDetector(
      onTap: isLink ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isLink ? Colors.blue : Colors.black87,
            decoration: isLink ? TextDecoration.underline : TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
