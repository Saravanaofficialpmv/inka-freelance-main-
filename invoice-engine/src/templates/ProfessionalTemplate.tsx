import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const ProfessionalTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const brandColor = '#1E3A8A'; // Deep Professional Blue / Indigo

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Top Header Title ── */}
      <div className="flex justify-between items-center pb-2 border-b-2 border-blue-900 mb-2">
        <div className="flex items-center gap-3">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '42px', maxWidth: '110px', objectFit: 'contain' }}
            />
          )}
          <div>
            <h1 className="text-base font-black tracking-tight text-gray-950 uppercase">
              {profile.businessName}
            </h1>
            {profile.gstNumber && (
              <div className="font-bold text-gray-800" style={{ fontSize: '8px' }}>
                {profile.taxLabel || 'GSTIN'}: <span className="font-mono">{profile.gstNumber}</span>
              </div>
            )}
          </div>
        </div>

        <div className="text-right">
          <div className="text-base font-black text-blue-900 tracking-wider uppercase">
            TAX INVOICE
          </div>
          <div className="font-bold text-gray-500" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
        </div>
      </div>

      {/* ── 3-Column Info Header (Seller, Buyer, Logistics/Metadata) ── */}
      <div className="grid grid-cols-3 border border-gray-300 rounded mb-2 text-xs" style={{ fontSize: '8px', lineHeight: '1.35' }}>
        {/* Col 1: Seller */}
        <div className="p-2 border-r border-gray-300">
          <div className="font-bold text-blue-900 uppercase pb-1 mb-1 border-b border-gray-200" style={{ fontSize: '7.5px' }}>
            Supplier Details:
          </div>
          <div className="font-bold text-gray-950">{profile.businessName}</div>
          <div className="text-gray-700">{profile.address}</div>
          {profile.phone && <div>Tel: {profile.phone}</div>}
          {profile.email && <div>Email: {profile.email}</div>}
        </div>

        {/* Col 2: Buyer (Bill to) */}
        <div className="p-2 border-r border-gray-300">
          <div className="font-bold text-blue-900 uppercase pb-1 mb-1 border-b border-gray-200" style={{ fontSize: '7.5px' }}>
            Billed To (Receiver):
          </div>
          <div className="font-bold text-gray-950">{client.name}</div>
          {client.gstNumber && (
            <div className="font-semibold text-gray-800">
              GSTIN: <span className="font-mono">{client.gstNumber}</span>
            </div>
          )}
          <div className="text-gray-700 whitespace-pre-line">{client.address}</div>
          {client.phone && <div>Ph: {client.phone}</div>}
        </div>

        {/* Col 3: Invoice Metadata & Consignee */}
        <div className="p-2 bg-gray-50">
          <div className="font-bold text-blue-900 uppercase pb-1 mb-1 border-b border-gray-200" style={{ fontSize: '7.5px' }}>
            Invoice & Dispatch Info:
          </div>
          <div><span className="text-gray-500">Invoice No: </span><span className="font-bold text-gray-950">{data.invoiceNumber}</span></div>
          <div><span className="text-gray-500">Date: </span><span className="font-medium">{data.issueDate}</span></div>
          {data.dueDate && <div><span className="text-gray-500">Due Date: </span><span>{data.dueDate}</span></div>}
          {data.placeOfSupply && (
            <div><span className="text-gray-500">Place of Supply: </span><span className="font-semibold">{data.placeOfSupply}</span></div>
          )}
          {data.ewayBillNumber && (
            <div><span className="text-gray-500">E-Way Bill: </span><span className="font-mono">{data.ewayBillNumber}</span></div>
          )}
          <div className="mt-1 pt-1 border-t border-gray-200 text-gray-700">
            <span className="font-bold text-gray-900">Ship To: </span>
            <span>{data.shipTo?.address || client.shippingAddress || client.address}</span>
          </div>
        </div>
      </div>

      {/* ── Table with Deep Professional Blue Header ── */}
      <table className="inv-table my-2" style={{ fontSize: '8px', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: brandColor, color: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '4%', padding: '5px 3px' }}>#</th>
            <th className="text-left" style={{ width: '42%', padding: '5px 6px' }}>Description of Goods / Services</th>
            <th className="text-center" style={{ width: '12%', padding: '5px 3px' }}>HSN/SAC</th>
            <th className="text-center" style={{ width: '8%', padding: '5px 3px' }}>Qty</th>
            <th className="text-right" style={{ width: '12%', padding: '5px 4px' }}>Unit Rate</th>
            <th className="text-center" style={{ width: '8%', padding: '5px 3px' }}>GST %</th>
            <th className="text-right" style={{ width: '14%', padding: '5px 6px' }}>Total</th>
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
              <td className="text-center py-1.5 text-gray-700">{item.taxRate !== undefined ? `${item.taxRate}%` : '-'}</td>
              <td className="text-right font-bold text-gray-950 py-1.5 px-2">{formatINR(item.total)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* ── Summary & Totals / Bank Details ── */}
      <div className="flex justify-between items-start my-2 pt-1">
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
                <PaymentQrCode upiId={profile.upiId} payeeName={profile.businessName} amount={data.totalAmount} size={56} />
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
              <tr style={{ borderTop: '2px solid #1E3A8A', borderBottom: '2px solid #1E3A8A' }}>
                <td className="py-1.5 font-black text-gray-950 text-sm uppercase">Total:</td>
                <td className="py-1.5 font-black text-blue-900 text-base">{formatINR(data.totalAmount)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Dual Signature Section: Receiver & Authorized Signatory ── */}
      <div className="grid grid-cols-2 gap-4 mt-3 pt-3 border-t border-gray-300">
        <div className="flex flex-col justify-end">
          <div className="border-t border-dashed border-gray-400 w-44 pt-1 text-center font-bold text-gray-700" style={{ fontSize: '7.5px' }}>
            Receiver's Signature & Seal
          </div>
        </div>

        <div className="flex justify-end">
          <SignatureBlock profile={profile} />
        </div>
      </div>

      <InvoiceFooter pageNumber={1} totalPages={1} />
    </div>
  );
};
