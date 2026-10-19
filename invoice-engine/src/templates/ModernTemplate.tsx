import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const ModernTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const brandDark = '#131921'; // Amazon Slate / Charcoal Modern

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Top Header: Invoice Details on Left, Seller on Right ── */}
      <div className="flex justify-between items-start pb-3 border-b-2 border-gray-800">
        <div>
          <h1 className="text-xl font-extrabold uppercase tracking-tight text-gray-950">
            TAX INVOICE
          </h1>
          <div className="text-gray-500 font-bold uppercase tracking-wider mb-2" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>

          <div className="space-y-0.5" style={{ fontSize: '8.5px' }}>
            <div><span className="text-gray-500">Invoice Number: </span><span className="font-bold text-gray-950">{data.invoiceNumber}</span></div>
            <div><span className="text-gray-500">Invoice Date: </span><span className="font-medium">{data.issueDate}</span></div>
            {data.dueDate && <div><span className="text-gray-500">Due Date: </span><span>{data.dueDate}</span></div>}
            {data.placeOfSupply && (
              <div><span className="text-gray-500">Place of Supply: </span><span className="font-semibold text-gray-900">{data.placeOfSupply}</span></div>
            )}
            {data.ewayBillNumber && (
              <div><span className="text-gray-500">E-Way Bill: </span><span className="font-mono">{data.ewayBillNumber}</span></div>
            )}
          </div>
        </div>

        {/* Seller Info on Right */}
        <div className="text-right flex flex-col items-end" style={{ fontSize: '8.5px', maxWidth: '300px' }}>
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              className="mb-1"
              style={{ maxHeight: '42px', maxWidth: '120px', objectFit: 'contain' }}
            />
          )}
          <div className="text-gray-500 font-bold" style={{ fontSize: '7.5px' }}>SOLD BY:</div>
          <div className="font-bold text-sm text-gray-950">{profile.businessName}</div>
          <div className="text-gray-700 leading-tight mt-0.5">{profile.address}</div>
          {profile.gstNumber && (
            <div className="font-semibold text-gray-800 mt-0.5">
              {profile.taxLabel || 'GSTIN'}: <span className="font-mono">{profile.gstNumber}</span>
            </div>
          )}
          {profile.phone && <div className="text-gray-600">Ph: {profile.phone}</div>}
        </div>
      </div>

      {/* ── Bill To & Ship To ── */}
      <div className="grid grid-cols-2 gap-4 py-3 border-b border-gray-200" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
        <div>
          <div className="text-gray-500 uppercase tracking-wider font-bold mb-1" style={{ fontSize: '7.5px' }}>
            Billing Address:
          </div>
          <div className="font-bold text-gray-950">{client.name}</div>
          {client.gstNumber && (
            <div className="font-semibold text-gray-800">
              GSTIN: <span className="font-mono">{client.gstNumber}</span>
            </div>
          )}
          <div className="text-gray-700 whitespace-pre-line mt-0.5">{client.address}</div>
          {client.phone && <div>Ph: {client.phone}</div>}
        </div>

        <div>
          <div className="text-gray-500 uppercase tracking-wider font-bold mb-1" style={{ fontSize: '7.5px' }}>
            Shipping Address:
          </div>
          <div className="font-bold text-gray-950">{data.shipTo?.name || client.name}</div>
          <div className="text-gray-700 whitespace-pre-line mt-0.5">
            {data.shipTo?.address || client.shippingAddress || client.address}
          </div>
        </div>
      </div>

      {/* ── Clean 7-Column Modern Table ── */}
      <table className="inv-table my-3" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '2px solid #CBD5E1' }}>
            <th className="text-center py-2 px-1 text-gray-700 font-bold" style={{ width: '4%' }}>#</th>
            <th className="text-left py-2 px-2 text-gray-800 font-bold" style={{ width: '46%' }}>Description</th>
            <th className="text-right py-2 px-2 text-gray-700 font-bold" style={{ width: '12%' }}>Unit Price</th>
            <th className="text-center py-2 px-1 text-gray-700 font-bold" style={{ width: '8%' }}>Qty</th>
            <th className="text-right py-2 px-2 text-gray-700 font-bold" style={{ width: '14%' }}>Net Amount</th>
            <th className="text-center py-2 px-1 text-gray-700 font-bold" style={{ width: '8%' }}>Tax</th>
            <th className="text-right py-2 px-2 text-gray-800 font-bold" style={{ width: '16%' }}>Total</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => (
            <tr key={idx} style={{ borderBottom: '1px solid #E2E8F0' }}>
              <td className="text-center text-gray-500 py-2.5">{idx + 1}</td>
              <td className="py-2.5 px-2">
                <div className="font-bold text-gray-950">{item.name}</div>
                <div className="text-gray-500 text-xs mt-0.5 flex gap-2" style={{ fontSize: '7.5px' }}>
                  {item.hsnSac && <span>HSN/SAC: <strong className="font-mono text-gray-700">{item.hsnSac}</strong></span>}
                  {item.description && <span>• {item.description}</span>}
                </div>
              </td>
              <td className="text-right py-2.5 px-2 text-gray-700">{formatINR(item.rate)}</td>
              <td className="text-center py-2.5 font-medium">{item.quantity} {item.unit || ''}</td>
              <td className="text-right py-2.5 px-2 font-medium">{formatINR(item.taxableAmount ?? (item.rate * item.quantity))}</td>
              <td className="text-center py-2.5 text-gray-600">
                {item.taxRate !== undefined ? `${item.taxRate}%` : '-'}
              </td>
              <td className="text-right font-bold text-gray-950 py-2.5 px-2">{formatINR(item.total)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* ── Summary & Totals / Bank Details ── */}
      <div className="flex justify-between items-start my-3 pt-2">
        <div className="w-7/12 pr-4" style={{ fontSize: '8px' }}>
          <div className="p-2 bg-gray-50 border border-gray-200 rounded mb-2">
            <span className="font-bold text-gray-700 uppercase" style={{ fontSize: '7.5px' }}>Amount in Words:</span>
            <div className="font-semibold text-gray-950 italic mt-0.5">
              {data.totalInWords || convertToIndianWords(data.totalAmount)}
            </div>
          </div>

          <div className="flex gap-3 items-start">
            <div className="flex-1">
              <BankDetails profile={profile} />
            </div>
            {profile.upiId && (
              <div className="border border-gray-200 p-2 rounded bg-white">
                <PaymentQrCode upiId={profile.upiId} payeeName={profile.businessName} amount={data.totalAmount} size={60} />
              </div>
            )}
          </div>
        </div>

        <div className="w-5/12 pl-4">
          <table className="w-full text-right" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
            <tbody>
              <tr>
                <td className="py-1 text-gray-600">Subtotal:</td>
                <td className="py-1 font-semibold text-gray-900">{formatINR(data.subtotal)}</td>
              </tr>
              {data.discountAmount !== undefined && data.discountAmount > 0 && (
                <tr>
                  <td className="py-1 text-red-600">Discount:</td>
                  <td className="py-1 font-semibold text-red-600">- {formatINR(data.discountAmount)}</td>
                </tr>
              )}
              {data.cgstAmount !== undefined && data.cgstAmount > 0 && (
                <tr>
                  <td className="py-1 text-gray-600">CGST:</td>
                  <td className="py-1 font-semibold text-gray-900">{formatINR(data.cgstAmount)}</td>
                </tr>
              )}
              {data.sgstAmount !== undefined && data.sgstAmount > 0 && (
                <tr>
                  <td className="py-1 text-gray-600">SGST:</td>
                  <td className="py-1 font-semibold text-gray-900">{formatINR(data.sgstAmount)}</td>
                </tr>
              )}
              {data.igstAmount !== undefined && data.igstAmount > 0 && (
                <tr>
                  <td className="py-1 text-gray-600">IGST:</td>
                  <td className="py-1 font-semibold text-gray-900">{formatINR(data.igstAmount)}</td>
                </tr>
              )}
              {data.roundOff !== undefined && data.roundOff !== 0 && (
                <tr>
                  <td className="py-1 text-gray-600">Round Off:</td>
                  <td className="py-1 font-semibold text-gray-900">
                    {data.roundOff > 0 ? `+${formatINR(data.roundOff)}` : formatINR(data.roundOff)}
                  </td>
                </tr>
              )}
              <tr style={{ borderTop: '2px solid #111827', borderBottom: '2px solid #111827' }}>
                <td className="py-2 font-extrabold text-gray-950 text-sm uppercase">Grand Total:</td>
                <td className="py-2 font-extrabold text-gray-950 text-base">{formatINR(data.totalAmount)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Signature Block ── */}
      <div className="flex justify-between items-end my-3 pt-3 border-t border-gray-200">
        <div style={{ fontSize: '7.5px' }} className="text-gray-500 max-w-sm">
          {data.notes && <div><strong>Notes:</strong> {data.notes}</div>}
          {data.terms && <div className="mt-1"><strong>Terms:</strong> {data.terms}</div>}
        </div>
        <SignatureBlock profile={profile} />
      </div>

      <InvoiceFooter pageNumber={1} totalPages={1} />
    </div>
  );
};
