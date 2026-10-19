import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { GstBreakdown } from '../components/GstBreakdown';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const LegendTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const corporateColor = '#0F2C59'; // Deep Navy / Corporate ITC Slate

  // Mock IRN or actual IRN if present in metadata
  const irnDisplay = data.notes?.includes('IRN:') 
    ? data.notes 
    : '4a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b';

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Top e-Invoice Header Banner ── */}
      <div className="border border-gray-400 mb-2">
        <div className="flex justify-between items-center px-3 py-1.5 text-white" style={{ backgroundColor: corporateColor }}>
          <div className="font-extrabold tracking-wider text-xs uppercase">
            e-INVOICE / TAX INVOICE
          </div>
          <div className="text-xs font-semibold tracking-wide">
            ORIGINAL FOR RECIPIENT
          </div>
        </div>

        {/* IRN Bar */}
        <div className="px-3 py-1 bg-gray-100 border-b border-gray-300 font-mono text-gray-700 flex items-center justify-between" style={{ fontSize: '7.5px' }}>
          <div>
            <strong className="text-gray-900">IRN: </strong>
            <span className="truncate inline-block max-w-lg align-bottom">{irnDisplay}</span>
          </div>
          <div>
            <strong>Ack No: </strong><span>11234567890</span> | <strong>Date: </strong><span>{data.issueDate}</span>
          </div>
        </div>

        {/* Company & Document Details with e-Invoice QR code */}
        <div className="grid grid-cols-12 p-3 gap-2" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
          {/* Company details (7 cols) */}
          <div className="col-span-7 flex items-start gap-3">
            {profile.logoUrl && (
              <img
                src={profile.logoUrl}
                alt={profile.businessName}
                style={{ maxHeight: '48px', maxWidth: '110px', objectFit: 'contain' }}
              />
            )}
            <div>
              <div className="font-black text-sm text-gray-950 uppercase">{profile.businessName}</div>
              {profile.gstNumber && (
                <div className="font-bold text-gray-900">
                  {profile.taxLabel || 'GSTIN'}: <span className="font-mono">{profile.gstNumber}</span>
                </div>
              )}
              <div className="text-gray-700">{profile.address}</div>
              {profile.phone && <div>Tel: {profile.phone}</div>}
              {profile.email && <div>Email: {profile.email}</div>}
            </div>
          </div>

          {/* Invoice Metadata (3 cols) */}
          <div className="col-span-3 border-l border-gray-300 pl-2">
            <div><span className="text-gray-600">Invoice No: </span><span className="font-bold text-gray-950">{data.invoiceNumber}</span></div>
            <div><span className="text-gray-600">Dated: </span><span className="font-medium">{data.issueDate}</span></div>
            {data.dueDate && <div><span className="text-gray-600">Due Date: </span><span>{data.dueDate}</span></div>}
            {data.placeOfSupply && (
              <div><span className="text-gray-600">Place of Supply: </span><span className="font-bold">{data.placeOfSupply}</span></div>
            )}
            {data.ewayBillNumber && (
              <div><span className="text-gray-600">E-Way Bill: </span><span className="font-mono">{data.ewayBillNumber}</span></div>
            )}
          </div>

          {/* e-Invoice QR Code placeholder (2 cols) */}
          <div className="col-span-2 flex flex-col items-center justify-center border-l border-gray-300 pl-2">
            {profile.upiId ? (
              <PaymentQrCode upiId={profile.upiId} payeeName={profile.businessName} amount={data.totalAmount} size={50} />
            ) : (
              <div className="w-12 h-12 bg-gray-100 border border-gray-400 flex items-center justify-center text-center font-bold text-gray-500" style={{ fontSize: '7px' }}>
                e-INV QR
              </div>
            )}
            <span className="text-gray-500 font-bold mt-1" style={{ fontSize: '6.5px' }}>GOVT e-INVOICE</span>
          </div>
        </div>
      </div>

      {/* ── Boxed Parties (Bill To & Ship To) ── */}
      <div className="grid grid-cols-2 border border-gray-400 mb-2" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
        <div className="p-2.5 border-r border-gray-400">
          <div className="font-bold text-gray-800 uppercase pb-1 mb-1 border-b border-gray-200" style={{ fontSize: '7.5px', color: corporateColor }}>
            Details of Receiver | Billed to:
          </div>
          <div className="font-bold text-gray-950 text-sm">{client.name}</div>
          {client.gstNumber && (
            <div className="font-semibold text-gray-800">
              GSTIN: <span className="font-mono">{client.gstNumber}</span>
            </div>
          )}
          {client.phone && <div>Phone: {client.phone}</div>}
          <div className="text-gray-700 whitespace-pre-line mt-0.5">{client.address}</div>
        </div>

        <div className="p-2.5">
          <div className="font-bold text-gray-800 uppercase pb-1 mb-1 border-b border-gray-200" style={{ fontSize: '7.5px', color: corporateColor }}>
            Details of Consignee | Shipped to:
          </div>
          <div className="font-bold text-gray-950">{data.shipTo?.name || client.name}</div>
          <div className="text-gray-700 whitespace-pre-line mt-0.5">
            {data.shipTo?.address || client.shippingAddress || client.address}
          </div>
        </div>
      </div>

      {/* ── Structured Grid Items Table ── */}
      <table className="inv-table-bordered my-2" style={{ fontSize: '8px', width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: corporateColor, color: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '4%', padding: '5px 3px' }}>#</th>
            <th className="text-left" style={{ width: '40%', padding: '5px 6px' }}>Description of Goods</th>
            <th className="text-center" style={{ width: '12%', padding: '5px 4px' }}>HSN/SAC</th>
            <th className="text-center" style={{ width: '8%', padding: '5px 3px' }}>Qty</th>
            <th className="text-right" style={{ width: '12%', padding: '5px 4px' }}>Rate</th>
            <th className="text-right" style={{ width: '12%', padding: '5px 4px' }}>Taxable Amt</th>
            <th className="text-right" style={{ width: '12%', padding: '5px 6px' }}>Total</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => (
            <tr key={idx} style={{ borderBottom: '1px solid #CBD5E1' }}>
              <td className="text-center text-gray-600 py-1.5">{idx + 1}</td>
              <td className="py-1.5 px-2">
                <div className="font-bold text-gray-950">{item.name}</div>
                {item.description && (
                  <div className="text-gray-600 text-xs mt-0.5 leading-tight" style={{ fontSize: '7.5px' }}>
                    {item.description}
                  </div>
                )}
              </td>
              <td className="text-center font-mono text-gray-700 py-1.5">{item.hsnSac || '-'}</td>
              <td className="text-center py-1.5">{item.quantity} {item.unit || ''}</td>
              <td className="text-right py-1.5 px-1">{formatINR(item.rate)}</td>
              <td className="text-right py-1.5 px-1">{formatINR(item.taxableAmount ?? item.total)}</td>
              <td className="text-right font-bold text-gray-950 py-1.5 px-2">{formatINR(item.total)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* ── Separate GST Breakdown Table ── */}
      <div className="my-2">
        <GstBreakdown data={data} headerColor={corporateColor} />
      </div>

      {/* ── Summary & Totals / Bank Details ── */}
      <div className="grid grid-cols-2 border border-gray-400 mt-2" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
        <div className="p-3 border-r border-gray-400 flex flex-col justify-between">
          <div>
            <div className="font-bold text-gray-700 uppercase mb-1" style={{ fontSize: '7.5px' }}>Total in Words:</div>
            <div className="font-semibold text-gray-950 italic mb-2">
              {data.totalInWords || convertToIndianWords(data.totalAmount)}
            </div>
            <BankDetails profile={profile} />
          </div>

          {profile.upiId && (
            <div className="mt-3 flex items-center gap-3 pt-2 border-t border-gray-200">
              <PaymentQrCode upiId={profile.upiId} payeeName={profile.businessName} amount={data.totalAmount} size={54} />
              <div style={{ fontSize: '7.5px' }} className="text-gray-600">
                <div className="font-bold text-gray-900">UPI Payment</div>
                <div>{profile.upiId}</div>
              </div>
            </div>
          )}
        </div>

        <div className="p-3 flex flex-col justify-between">
          <table className="w-full text-right" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
            <tbody>
              <tr>
                <td className="py-1 text-gray-600">Taxable Subtotal:</td>
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
                  <td className="py-1 text-gray-600">Total CGST:</td>
                  <td className="py-1 font-semibold text-gray-900">{formatINR(data.cgstAmount)}</td>
                </tr>
              )}
              {data.sgstAmount !== undefined && data.sgstAmount > 0 && (
                <tr>
                  <td className="py-1 text-gray-600">Total SGST:</td>
                  <td className="py-1 font-semibold text-gray-900">{formatINR(data.sgstAmount)}</td>
                </tr>
              )}
              {data.igstAmount !== undefined && data.igstAmount > 0 && (
                <tr>
                  <td className="py-1 text-gray-600">Total IGST:</td>
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
              <tr style={{ borderTop: '1px solid #111827', borderBottom: '1px solid #111827' }}>
                <td className="py-1.5 font-bold text-gray-950 uppercase">Total Amount:</td>
                <td className="py-1.5 font-extrabold text-gray-950 text-sm" style={{ color: corporateColor }}>
                  {formatINR(data.totalAmount)}
                </td>
              </tr>
            </tbody>
          </table>

          <div className="mt-3 pt-2 border-t border-gray-200">
            <SignatureBlock profile={profile} />
          </div>
        </div>
      </div>

      <InvoiceFooter pageNumber={1} totalPages={1} />
    </div>
  );
};
