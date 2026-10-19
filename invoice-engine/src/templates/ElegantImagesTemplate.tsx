import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const ElegantImagesTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const headerColor = '#1F2937'; // Charcoal / Jet Black

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Top Header ── */}
      <div className="flex justify-between items-start pb-3 border-b border-gray-300">
        <div className="flex items-center gap-3">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '46px', maxWidth: '130px', objectFit: 'contain' }}
            />
          )}
          <div>
            <h1 className="font-extrabold tracking-tight text-gray-950" style={{ fontSize: '18px' }}>
              {profile.businessName}
            </h1>
            {profile.gstNumber && (
              <div className="font-semibold text-gray-700" style={{ fontSize: '8.5px' }}>
                {profile.taxLabel || 'GSTIN'}: <span className="font-mono text-gray-900">{profile.gstNumber}</span>
              </div>
            )}
            <div className="text-gray-600 mt-0.5" style={{ fontSize: '8px', lineHeight: '1.35' }}>
              {profile.address && <div>{profile.address}</div>}
              {profile.phone && <div>Tel: {profile.phone}</div>}
              {profile.email && <div>Email: {profile.email}</div>}
            </div>
          </div>
        </div>

        <div className="text-right" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
          <div className="font-black tracking-widest text-gray-950 uppercase" style={{ fontSize: '16px' }}>
            TAX INVOICE
          </div>
          <div className="font-bold text-gray-500 mb-1" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
          <div><span className="text-gray-500">Invoice No: </span><span className="font-bold text-gray-900">{data.invoiceNumber}</span></div>
          <div><span className="text-gray-500">Date: </span><span>{data.issueDate}</span></div>
          {data.dueDate && <div><span className="text-gray-500">Due Date: </span><span>{data.dueDate}</span></div>}
          {data.placeOfSupply && (
            <div><span className="text-gray-500">Place of Supply: </span><span className="font-semibold">{data.placeOfSupply}</span></div>
          )}
        </div>
      </div>

      {/* ── Party Details ── */}
      <div className="grid grid-cols-2 gap-4 py-3 border-b border-gray-200" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
        <div>
          <div className="text-gray-500 uppercase tracking-wider font-bold mb-1" style={{ fontSize: '7.5px' }}>BILL TO</div>
          <div className="font-bold text-gray-950 text-sm">{client.name}</div>
          {client.gstNumber && (
            <div className="font-semibold text-gray-800">
              GSTIN: <span className="font-mono">{client.gstNumber}</span>
            </div>
          )}
          {client.phone && <div>Phone: {client.phone}</div>}
          {client.email && <div>Email: {client.email}</div>}
          <div className="text-gray-700 whitespace-pre-line mt-0.5">{client.address}</div>
        </div>

        <div>
          <div className="text-gray-500 uppercase tracking-wider font-bold mb-1" style={{ fontSize: '7.5px' }}>SHIP TO</div>
          <div className="font-bold text-gray-950">
            {data.shipTo?.name || client.name}
          </div>
          <div className="text-gray-700 whitespace-pre-line mt-0.5">
            {data.shipTo?.address || client.shippingAddress || client.address}
          </div>
          {data.ewayBillNumber && (
            <div className="mt-1 font-semibold text-gray-800">
              E-Way Bill: <span className="font-mono">{data.ewayBillNumber}</span>
            </div>
          )}
        </div>
      </div>

      {/* ── Items Table with Product Image Thumbnail Column ── */}
      <table className="inv-table my-3" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: headerColor, color: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '4%', padding: '6px 4px' }}>#</th>
            <th className="text-center" style={{ width: '8%', padding: '6px 4px' }}>Image</th>
            <th className="text-left" style={{ width: '38%', padding: '6px 8px' }}>Item Description</th>
            <th className="text-center" style={{ width: '12%', padding: '6px 4px' }}>HSN/SAC</th>
            <th className="text-right" style={{ width: '14%', padding: '6px 6px' }}>Rate</th>
            <th className="text-center" style={{ width: '8%', padding: '6px 4px' }}>Qty</th>
            <th className="text-center" style={{ width: '6%', padding: '6px 4px' }}>Tax</th>
            <th className="text-right" style={{ width: '10%', padding: '6px 8px' }}>Amount</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => (
            <tr key={idx} style={{ borderBottom: '1px solid #E5E7EB' }}>
              <td className="text-center text-gray-500 py-2">{idx + 1}</td>
              <td className="text-center py-2 px-1">
                {item.imageUrl ? (
                  <img
                    src={item.imageUrl}
                    alt={item.name}
                    className="w-9 h-9 object-cover rounded border border-gray-200 mx-auto"
                  />
                ) : (
                  <div className="w-8 h-8 rounded bg-gray-100 border border-gray-200 flex items-center justify-center text-gray-400 font-bold mx-auto" style={{ fontSize: '9px' }}>
                    {item.name.charAt(0).toUpperCase()}
                  </div>
                )}
              </td>
              <td className="py-2 px-2">
                <div className="font-bold text-gray-950">{item.name}</div>
                {item.description && (
                  <div className="text-gray-500 text-xs mt-0.5 leading-snug" style={{ fontSize: '7.5px' }}>
                    {item.description}
                  </div>
                )}
              </td>
              <td className="text-center font-mono text-gray-700 py-2">{item.hsnSac || '-'}</td>
              <td className="text-right font-medium py-2 px-2">{formatINR(item.rate)}</td>
              <td className="text-center py-2">{item.quantity} {item.unit || ''}</td>
              <td className="text-center text-gray-700 py-2">
                {item.taxRate !== undefined ? `${item.taxRate}%` : '-'}
              </td>
              <td className="text-right font-bold text-gray-950 py-2 px-2">{formatINR(item.total)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* ── Summary & Totals ── */}
      <div className="flex justify-between items-start my-3 pt-2">
        <div className="w-7/12 pr-4" style={{ fontSize: '8px' }}>
          <div className="p-2.5 bg-gray-50 rounded border border-gray-200 mb-2">
            <span className="font-bold text-gray-700 uppercase" style={{ fontSize: '7.5px' }}>Amount in Words:</span>
            <div className="font-semibold text-gray-900 mt-0.5 italic">
              {data.totalInWords || convertToIndianWords(data.totalAmount)}
            </div>
          </div>

          <div className="flex gap-4 items-start">
            <div className="flex-1">
              <BankDetails profile={profile} />
            </div>
            {profile.upiId && (
              <div className="border border-gray-200 p-2 rounded bg-white">
                <PaymentQrCode upiId={profile.upiId} payeeName={profile.businessName} amount={data.totalAmount} size={64} />
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
              <tr style={{ borderTop: '2px solid #1F2937', borderBottom: '2px solid #1F2937' }}>
                <td className="py-2 font-extrabold text-gray-950 text-sm uppercase">Total:</td>
                <td className="py-2 font-extrabold text-gray-950 text-base">{formatINR(data.totalAmount)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Signature & Stamp ── */}
      <div className="flex justify-between items-end my-3 pt-3 border-t border-gray-200">
        <div style={{ fontSize: '7.5px' }} className="text-gray-500 max-w-sm">
          {data.notes && <div><strong>Notes:</strong> {data.notes}</div>}
          {data.terms && <div className="mt-1"><strong>Terms & Conditions:</strong> {data.terms}</div>}
        </div>
        <SignatureBlock profile={profile} />
      </div>

      <InvoiceFooter pageNumber={1} totalPages={1} />
    </div>
  );
};
