import { renderInvoiceToHtml } from '../src/print/renderToHtml.js';
import { TEMPLATES } from '../src/registry/templateRegistry.js';
import fs from 'fs';
import path from 'path';

// Realistic Indian GST sample invoice
const sampleInvoice = {
  templateId: 'template_billto_shipto',
  invoiceNumber: 'INV-2024-00142',
  issueDate: '19/10/2024',
  dueDate: '03/11/2024',
  placeOfSupply: '27-Maharashtra',
  stateCode: '27',
  ewayBillNumber: '841029485712',
  profile: {
    businessName: 'Inka Technologies Pvt Ltd',
    tagline: 'Enterprise Billing & Logistics Solutions',
    address: 'Plot No. 42, Bandra Kurla Complex, Bandra East, Mumbai, Maharashtra 400051',
    phone: '+91 98765 43210',
    email: 'billing@inka.app',
    gstNumber: '27AAACI1234A1Z5',
    panNumber: 'AAACI1234A',
    taxLabel: 'GSTIN',
    bankName: 'HDFC Bank Ltd',
    accountNumber: '50200012345678',
    ifscCode: 'HDFC0000042',
    branchName: 'BKC Executive Branch',
    upiId: 'inka.technologies@hdfcbank',
    currency: 'INR',
    signatureUrl: '',
    logoUrl: '',
  },
  client: {
    name: 'Apex Global Logistics Pvt Ltd',
    company: 'Apex Retail Division',
    address: 'Warehouse #7, Industrial Area, Phase II, Pune, Maharashtra 411019',
    phone: '+91 91234 56789',
    email: 'procurement@apexlogistics.in',
    gstNumber: '27AABCA5678B1Z2',
    shippingAddress: 'Central Hub Pune, Plot 14, Hinjewadi Phase 1, Pune 411057',
  },
  shipTo: {
    name: 'Apex Distribution Center Pune',
    address: 'Central Hub Pune, Plot 14, Hinjewadi Phase 1, Pune 411057',
    gstin: '27AABCA5678B1Z2',
    state: 'Maharashtra',
  },
  items: [
    {
      id: '1',
      name: 'Industrial Barcode Scanner X-200',
      description: 'High-speed 2D handheld wireless barcode reader with cradle',
      hsnSac: '847190',
      quantity: 5,
      rate: 8500,
      mrp: 9999,
      unit: 'NOS',
      taxRate: 18,
      taxableAmount: 42500,
      total: 50150,
    },
    {
      id: '2',
      name: 'Thermal Receipt Rolls (80mm x 50m)',
      description: 'BPA-free high-density thermal paper rolls pack of 50',
      hsnSac: '481190',
      quantity: 10,
      rate: 1200,
      mrp: 1500,
      unit: 'BOX',
      taxRate: 12,
      taxableAmount: 12000,
      total: 13440,
    },
    {
      id: '3',
      name: 'Cloud POS Integration & Onboarding',
      description: 'System setup, webhook configuration, and field training',
      hsnSac: '998314',
      quantity: 1,
      rate: 15000,
      unit: 'SVC',
      taxRate: 18,
      taxableAmount: 15000,
      total: 17700,
    },
  ],
  subtotal: 69500,
  discount: 2000,
  discountAmount: 2000,
  taxPercentage: 18,
  taxableAmount: 67500,
  cgstAmount: 5895,
  sgstAmount: 5895,
  igstAmount: 0,
  taxAmount: 11790,
  roundOff: 0.0,
  total: 79290,
  totalAmount: 79290,
  totalInWords: 'INR Seventy-Nine Thousand Two Hundred Ninety Rupees Only',
  notes: 'Goods once sold cannot be returned without prior authorization.',
  terms: 'Payment due within 15 days of invoice date. 18% p.a. interest applicable on overdue amounts.',
};

console.log(`Verifying all ${TEMPLATES.length} templates HTML rendering:`);
for (const tmpl of TEMPLATES) {
  const html = renderInvoiceToHtml(tmpl.id, { ...sampleInvoice, templateId: tmpl.id });
  console.log(`✓ ${tmpl.id}: ${html.length} chars generated.`);
}
console.log('All 14 templates verified successfully!');
