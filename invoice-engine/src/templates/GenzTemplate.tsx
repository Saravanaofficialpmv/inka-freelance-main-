import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const GenzTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const brandBlue = '#1A73E8'; // Modern Google / Gen Z Royal Blue

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Top Vibrant Header Bar ── */}
      <div
        className="rounded-xl p-4 text-white flex justify-between items-center mb-3 shadow-sm"
        style={{ backgroundColor: brandBlue }}
      >
        <div className="flex items-center gap-3">
          {profile.logoUrl && (
            <div className="bg-white p-1 rounded-lg">
              <img
                src={profile.logoUrl}
                alt={profile.businessName}
                style={{ maxHeight: '40px', maxWidth: '100px', objectFit: 'contain' }}
              />
            </div>
          )}
          <div>
            <h1 className="font-extrabold text-base tracking-tight">{profile.businessName}</h1>
            {profile.gstNumber && (
              <div className="text-blue-100 font-medium" style={{ fontSize: '8px' }}>
                {profile.taxLabel || 'GSTIN'}: <span className="font-mono">{profile.gstNumber}</span>
              </div>
            )}
            <div className="text-blue-100 opacity-90" style={{ fontSize: '7.5px' }}>
              {profile.address && <span>{profile.address} • </span>}
              {profile.phone && <span>Ph: {profile.phone}</span>}
            </div>
          </div>
        </div>

        <div className="text-right">
          <div className="inline-block bg-white text-blue-700 font-extrabold px-2.5 py-0.5 rounded-full text-xs uppercase tracking-wider mb-1">
            TAX INVOICE
          </div>
          <div className="text-blue-100 font-medium" style={{ fontSize: '8px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
        </div>
      </div>

      {/* ── 2 Modern Rounded Info Cards (Metadata & Parties) ── */}
      <div className="grid grid-cols-2 gap-3 mb-3" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
        {/* Bill To Card */}
        <div className="p-3 bg-gray-50 border border-gray-200 rounded-xl">
          <div className="font-bold text-gray-500 uppercase tracking-wider mb-1" style={{ fontSize: '7.5px' }}>
            Billed To
          </div>
          <div className="font-bold text-gray-950 text-sm">{client.name}</div>
          {client.gstNumber && (
            <div className="font-semibold text-gray-800">
              GSTIN: <span className="font-mono">{client.gstNumber}</span>
            </div>
          )}
          {client.phone && <div>Phone: {client.phone}</div>}
          {client.email && <div>Email: {client.email}</div>}
          <div className="text-gray-700 mt-0.5">{client.address}</div>
        </div>

        {/* Invoice Info Card */}
        <div className="p-3 bg-blue-50/50 border border-blue-100 rounded-xl flex flex-col justify-between">
          <div>
            <div className="flex justify-between items-center mb-1">
              <span className="text-gray-500 font-bold uppercase" style={{ fontSize: '7.5px' }}>Invoice Details</span>
              <span className="font-mono font-bold text-blue-700 text-xs">{data.invoiceNumber}</span>
            </div>
            <div className="space-y-0.5">
              <div className="flex justify-between">
                <span className="text-gray-600">Issue Date:</span>
                <span className="font-medium text-gray-900">{data.issueDate}</span>
              </div>
              {data.dueDate && (
                <div className="flex justify-between">
                  <span className="text-gray-600">Due Date:</span>
                  <span className="font-medium text-gray-900">{data.dueDate}</span>
                </div>
              )}
              {data.placeOfSupply && (
                <div className="flex justify-between">
                  <span className="text-gray-600">Place of Supply:</span>
                  <span className="font-bold text-gray-950">{data.placeOfSupply}</span>
                </div>
              )}
            </div>
          </div>

          {data.shipTo?.address && (
            <div className="pt-2 border-t border-blue-100 mt-1">
              <span className="text-gray-500 font-bold" style={{ fontSize: '7px' }}>Ship To: </span>
              <span className="text-gray-700">{data.shipTo.address}</span>
            </div>
          )}
        </div>
      </div>

      {/* ── Dynamic Table with Rounded Styling and Product Images ── */}
      <div className="overflow-hidden rounded-xl border border-gray-200 mb-3">
        <table className="w-full text-left" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ backgroundColor: '#F1F5F9', borderBottom: '1px solid #CBD5E1' }}>
              <th className="text-center py-2 px-1 text-gray-600 font-bold" style={{ width: '4%' }}>#</th>
              <th className="text-center py-2 px-1 text-gray-600 font-bold" style={{ width: '8%' }}>Photo</th>
              <th className="text-left py-2 px-2 text-gray-700 font-bold" style={{ width: '42%' }}>Item / Service</th>
              <th className="text-center py-2 px-1 text-gray-600 font-bold" style={{ width: '12%' }}>HSN/SAC</th>
              <th className="text-right py-2 px-2 text-gray-600 font-bold" style={{ width: '12%' }}>Rate</th>
              <th className="text-center py-2 px-1 text-gray-600 font-bold" style={{ width: '8%' }}>Qty</th>
              <th className="text-right py-2 px-2 text-gray-700 font-bold" style={{ width: '14%' }}>Amount</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item, idx) => (
              <tr key={idx} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="text-center text-gray-500 py-2">{idx + 1}</td>
                <td className="text-center py-2">
                  {item.imageUrl ? (
                    <img
                      src={item.imageUrl}
                      alt={item.name}
                      className="w-8 h-8 rounded-lg object-cover border border-gray-200 mx-auto"
                    />
                  ) : (
                    <div className="w-7 h-7 rounded-lg bg-blue-50 text-blue-600 font-bold flex items-center justify-center mx-auto text-xs">
                      {item.name.charAt(0).toUpperCase()}
                    </div>
                  )}
                </td>
                <td className="py-2 px-2">
                  <div className="font-bold text-gray-950">{item.name}</div>
                  {item.description && (
                    <div className="text-gray-500 text-xs mt-0.5 leading-tight" style={{ fontSize: '7.5px' }}>
                      {item.description}
                    </div>
                  )}
                </td>
                <td className="text-center font-mono text-gray-600 py-2">{item.hsnSac || '-'}</td>
                <td className="text-right py-2 px-2 text-gray-700">{formatINR(item.rate)}</td>
                <td className="text-center py-2 font-medium">{item.quantity} {item.unit || ''}</td>
                <td className="text-right font-bold text-gray-950 py-2 px-2">{formatINR(item.total)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* ── Totals & Payment Grid ── */}
      <div className="grid grid-cols-2 gap-3 mb-3">
        {/* Left: UPI QR & Bank in a rounded card */}
        <div className="p-3 bg-gray-50 border border-gray-200 rounded-xl flex items-start gap-3" style={{ fontSize: '8px' }}>
          {profile.upiId && (
            <div className="bg-white p-1.5 rounded-lg border border-gray-200 flex-shrink-0">
              <PaymentQrCode upiId={profile.upiId} payeeName={profile.businessName} amount={data.totalAmount} size={64} />
            </div>
          )}
          <div className="flex-1">
            <div className="font-bold text-gray-800 uppercase mb-1" style={{ fontSize: '7.5px', color: brandBlue }}>
              Payment Details
            </div>
            <BankDetails profile={profile} />
          </div>
        </div>

        {/* Right: Calculations in a clean card */}
        <div className="p-3 bg-gray-50 border border-gray-200 rounded-xl">
          <table className="w-full text-right" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
            <tbody>
              <tr>
                <td className="py-0.5 text-gray-600">Subtotal:</td>
                <td className="py-0.5 font-semibold text-gray-900">{formatINR(data.subtotal)}</td>
              </tr>
              {data.discountAmount !== undefined && data.discountAmount > 0 && (
                <tr>
                  <td className="py-0.5 text-red-600">Discount:</td>
                  <td className="py-0.5 font-semibold text-red-600">- {formatINR(data.discountAmount)}</td>
                </tr>
              )}
              {data.cgstAmount !== undefined && data.cgstAmount > 0 && (
                <tr>
                  <td className="py-0.5 text-gray-600">CGST:</td>
                  <td className="py-0.5 font-semibold text-gray-900">{formatINR(data.cgstAmount)}</td>
                </tr>
              )}
              {data.sgstAmount !== undefined && data.sgstAmount > 0 && (
                <tr>
                  <td className="py-0.5 text-gray-600">SGST:</td>
                  <td className="py-0.5 font-semibold text-gray-900">{formatINR(data.sgstAmount)}</td>
                </tr>
              )}
              {data.igstAmount !== undefined && data.igstAmount > 0 && (
                <tr>
                  <td className="py-0.5 text-gray-600">IGST:</td>
                  <td className="py-0.5 font-semibold text-gray-900">{formatINR(data.igstAmount)}</td>
                </tr>
              )}
              {data.roundOff !== undefined && data.roundOff !== 0 && (
                <tr>
                  <td className="py-0.5 text-gray-600">Round Off:</td>
                  <td className="py-0.5 font-semibold text-gray-900">
                    {data.roundOff > 0 ? `+${formatINR(data.roundOff)}` : formatINR(data.roundOff)}
                  </td>
                </tr>
              )}
              <tr style={{ borderTop: '1px solid #CBD5E1' }}>
                <td className="pt-2 font-black text-gray-950 uppercase text-xs">Total Amount:</td>
                <td className="pt-2 font-black text-blue-700 text-sm">{formatINR(data.totalAmount)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* Amount in words */}
      <div className="p-2 bg-blue-50/50 rounded-lg border border-blue-100 text-xs italic text-gray-800 mb-3" style={{ fontSize: '8px' }}>
        <strong className="text-gray-900 uppercase not-italic">Amount in Words: </strong>
        {data.totalInWords || convertToIndianWords(data.totalAmount)}
      </div>

      {/* ── Signature Block ── */}
      <div className="flex justify-between items-end pt-2 border-t border-gray-200">
        <div style={{ fontSize: '7.5px' }} className="text-gray-500 max-w-sm">
          {data.notes && <div><strong>Note:</strong> {data.notes}</div>}
          {data.terms && <div className="mt-0.5"><strong>Terms:</strong> {data.terms}</div>}
        </div>
        <SignatureBlock profile={profile} />
      </div>

      <InvoiceFooter pageNumber={1} totalPages={1} />
    </div>
  );
};
