import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const MrpDiscountTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const retailGreen = '#15803D'; // Retail Savings Green
  const brandDark = '#1E293B';

  // Compute total savings (from items mrp vs rate or overall discount)
  let totalMrpSavings = data.discountAmount ?? 0;
  items.forEach((item) => {
    if (item.mrp && item.mrp > item.rate) {
      totalMrpSavings += (item.mrp - item.rate) * item.quantity;
    }
  });

  const totalQuantity = items.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Top Header: Retail Supermarket Store Info ── */}
      <div className="flex justify-between items-start pb-3 border-b-2 border-gray-900">
        <div className="flex items-center gap-3">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '44px', maxWidth: '120px', objectFit: 'contain' }}
            />
          )}
          <div>
            <h1 className="text-lg font-black tracking-tight text-gray-950 uppercase">
              {profile.businessName}
            </h1>
            {profile.gstNumber && (
              <div className="font-bold text-gray-800" style={{ fontSize: '8.5px' }}>
                {profile.taxLabel || 'GSTIN'}: <span className="font-mono">{profile.gstNumber}</span>
              </div>
            )}
            <div className="text-gray-700 mt-0.5" style={{ fontSize: '8px', lineHeight: '1.3' }}>
              {profile.address && <div>{profile.address}</div>}
              {profile.phone && <div>Tel: {profile.phone}</div>}
            </div>
          </div>
        </div>

        <div className="text-right" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
          <div className="text-sm font-extrabold text-gray-950 tracking-wider uppercase">
            RETAIL TAX INVOICE
          </div>
          <div className="font-bold text-gray-500 mb-1" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
          <div><span className="text-gray-600">Bill No: </span><span className="font-mono font-bold text-gray-950">{data.invoiceNumber}</span></div>
          <div><span className="text-gray-600">Bill Date: </span><span>{data.issueDate}</span></div>
          {data.placeOfSupply && (
            <div><span className="text-gray-600">Place of Supply: </span><span className="font-semibold">{data.placeOfSupply}</span></div>
          )}
        </div>
      </div>

      {/* ── Customer Details ── */}
      <div className="flex justify-between items-center py-2 border-b border-gray-300 bg-gray-50 px-3 my-2 rounded" style={{ fontSize: '8.5px' }}>
        <div>
          <span className="text-gray-500 font-bold uppercase" style={{ fontSize: '7.5px' }}>Customer: </span>
          <span className="font-bold text-gray-950">{client.name}</span>
          {client.phone && <span className="text-gray-700 ml-3">Mobile: {client.phone}</span>}
          {client.gstNumber && <span className="text-gray-700 ml-3">GSTIN: <span className="font-mono">{client.gstNumber}</span></span>}
        </div>
        <div className="text-gray-600 text-xs">
          <span>Items: <strong>{items.length}</strong></span>
          <span className="ml-3">Total Qty: <strong>{totalQuantity}</strong></span>
        </div>
      </div>

      {/* ── Retail Item Table with MRP, Rate, and Discount Columns ── */}
      <table className="inv-table my-2" style={{ fontSize: '8px', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: brandDark, color: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '4%', padding: '6px 3px' }}>#</th>
            <th className="text-left" style={{ width: '36%', padding: '6px 6px' }}>Item Description</th>
            <th className="text-center" style={{ width: '10%', padding: '6px 3px' }}>HSN</th>
            <th className="text-right" style={{ width: '10%', padding: '6px 4px' }}>MRP</th>
            <th className="text-right" style={{ width: '10%', padding: '6px 4px' }}>Offer Rate</th>
            <th className="text-center" style={{ width: '8%', padding: '6px 3px' }}>Qty</th>
            <th className="text-right" style={{ width: '10%', padding: '6px 4px' }}>Discount</th>
            <th className="text-right" style={{ width: '12%', padding: '6px 6px' }}>Net Amount</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => {
            const itemMrp = item.mrp ?? item.rate;
            const itemDiscount = item.mrp && item.mrp > item.rate
              ? (item.mrp - item.rate) * item.quantity
              : (item.discount ?? 0);

            return (
              <tr key={idx} style={{ borderBottom: '1px solid #E2E8F0' }}>
                <td className="text-center text-gray-500 py-2">{idx + 1}</td>
                <td className="py-2 px-1">
                  <div className="font-bold text-gray-950">{item.name}</div>
                  {item.description && (
                    <div className="text-gray-500 text-xs mt-0.5" style={{ fontSize: '7.5px' }}>
                      {item.description}
                    </div>
                  )}
                </td>
                <td className="text-center font-mono text-gray-600 py-2">{item.hsnSac || '-'}</td>
                <td className="text-right text-gray-500 py-2 px-1 line-through">{formatINR(itemMrp)}</td>
                <td className="text-right font-semibold text-gray-900 py-2 px-1">{formatINR(item.rate)}</td>
                <td className="text-center py-2 font-medium">{item.quantity} {item.unit || ''}</td>
                <td className="text-right text-green-700 font-medium py-2 px-1">
                  {itemDiscount > 0 ? formatINR(itemDiscount) : '-'}
                </td>
                <td className="text-right font-bold text-gray-950 py-2 px-1">{formatINR(item.total)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {/* ── Highlighted Savings Banner (DMart Retail Style) ── */}
      {totalMrpSavings > 0 && (
        <div className="my-2 p-2 rounded border border-green-300 bg-green-50 flex justify-between items-center text-green-900">
          <div className="font-extrabold uppercase tracking-wide" style={{ fontSize: '9px' }}>
            🎉 Total Savings on this Invoice:
          </div>
          <div className="font-black text-sm" style={{ color: retailGreen }}>
            {formatINR(totalMrpSavings)}
          </div>
        </div>
      )}

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
                  <td className="py-1 text-green-700">Special Discount:</td>
                  <td className="py-1 font-semibold text-green-700">- {formatINR(data.discountAmount)}</td>
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
              <tr style={{ borderTop: '2px solid #1E293B', borderBottom: '2px solid #1E293B' }}>
                <td className="py-2 font-black text-gray-950 text-sm uppercase">Net Payable:</td>
                <td className="py-2 font-black text-gray-950 text-base">{formatINR(data.totalAmount)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Signature Block ── */}
      <div className="flex justify-between items-end my-3 pt-3 border-t border-gray-200">
        <div style={{ fontSize: '7.5px' }} className="text-gray-500 max-w-sm">
          {data.notes && <div><strong>Terms:</strong> {data.notes}</div>}
          <div className="mt-0.5">Goods once sold will not be taken back or exchanged without receipt. Thank you for your business!</div>
        </div>
        <SignatureBlock profile={profile} />
      </div>

      <InvoiceFooter pageNumber={1} totalPages={1} />
    </div>
  );
};
