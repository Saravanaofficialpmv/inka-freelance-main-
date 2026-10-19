import React, { useState } from 'react';
import ReactDOM from 'react-dom/client';
import { TEMPLATES } from './registry/templateRegistry';
import { TemplateId } from './types/template';
import { InvoicePayload } from './types/invoice';
import './styles/templates.css';
import './styles/print.css';
import './index'; // Load window bridge

// Realistic Indian GST sample invoice for development and verification
const SAMPLE_INVOICE: InvoicePayload = {
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
      cgstAmount: 3825,
      sgstAmount: 3825,
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
      cgstAmount: 720,
      sgstAmount: 720,
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
      cgstAmount: 1350,
      sgstAmount: 1350,
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
  gstBreakdown: [
    {
      hsnSac: '847190',
      taxableAmount: 42500,
      cgstRate: 9,
      cgstAmount: 3825,
      sgstRate: 9,
      sgstAmount: 3825,
      totalTax: 7650,
    },
    {
      hsnSac: '481190',
      taxableAmount: 12000,
      cgstRate: 6,
      cgstAmount: 720,
      sgstRate: 6,
      sgstAmount: 720,
      totalTax: 1440,
    },
    {
      hsnSac: '998314',
      taxableAmount: 15000,
      cgstRate: 9,
      cgstAmount: 1350,
      sgstRate: 9,
      sgstAmount: 1350,
      totalTax: 2700,
    },
  ],
};

function App() {
  const [selectedId, setSelectedId] = useState<TemplateId>('template_billto_shipto');
  const activeTemplate = TEMPLATES.find((t) => t.id === selectedId) || TEMPLATES[0];
  const Component = activeTemplate.component;

  return (
    <div style={{ backgroundColor: '#F3F4F6', minHeight: '100vh', padding: '24px' }}>
      <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
        {/* Navigation Toolbar */}
        <div style={{ backgroundColor: '#FFFFFF', padding: '16px 20px', borderRadius: '12px', marginBottom: '20px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <div>
              <h1 style={{ fontSize: '18px', fontWeight: 'bold', color: '#111827' }}>Inka Reference-Driven Invoice Engine</h1>
              <p style={{ fontSize: '13px', color: '#6B7280' }}>14 Exact Reference-Engineered Indian GST Layouts</p>
            </div>
            <button
              onClick={() => window.print()}
              style={{
                backgroundColor: '#1E40AF',
                color: '#FFFFFF',
                padding: '8px 16px',
                borderRadius: '8px',
                fontWeight: '600',
                fontSize: '13px',
                cursor: 'pointer',
                border: 'none',
              }}
            >
              Print / Save PDF
            </button>
          </div>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
            {TEMPLATES.map((tmpl) => (
              <button
                key={tmpl.id}
                onClick={() => setSelectedId(tmpl.id)}
                style={{
                  padding: '6px 12px',
                  borderRadius: '6px',
                  fontSize: '12px',
                  fontWeight: selectedId === tmpl.id ? '700' : '500',
                  backgroundColor: selectedId === tmpl.id ? '#1E40AF' : '#F3F4F6',
                  color: selectedId === tmpl.id ? '#FFFFFF' : '#374151',
                  border: '1px solid',
                  borderColor: selectedId === tmpl.id ? '#1E40AF' : '#E5E7EB',
                  cursor: 'pointer',
                }}
              >
                {tmpl.name}
              </button>
            ))}
          </div>
        </div>

        {/* Invoice Page Container */}
        <div style={{ backgroundColor: '#FFFFFF', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)', padding: '20mm', borderRadius: '4px', maxWidth: '210mm', margin: '0 auto' }}>
          <Component data={{ ...SAMPLE_INVOICE, templateId: selectedId }} />
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
