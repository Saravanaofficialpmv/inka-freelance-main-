import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const ServiceTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const magentaAccent = '#E1306C'; // Hot Magenta / Instagram Agency Vibrant Pink

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Creative Service Header ── */}
      <div className="flex justify-between items-start pb-4 border-b-2" style={{ borderColor: magentaAccent }}>
        <div className="flex items-start gap-3">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '46px', maxWidth: '120px', objectFit: 'contain' }}
            />
          )}
          <div>
            <h1 className="text-xl font-black tracking-tight text-gray-950">
              {profile.businessName}
            </h1>
            {profile.gstNumber && (
              <div className="font-bold text-gray-700" style={{ fontSize: '8.5px' }}>
                {profile.taxLabel || 'GSTIN'}: <span className="font-mono text-gray-950">{profile.gstNumber}</span>
              </div>
            )}
            <div className="text-gray-600 mt-0.5" style={{ fontSize: '8px', lineHeight: '1.3' }}>
              {profile.address && <div>{profile.address}</div>}
              {profile.phone && <div>Tel: {profile.phone}</div>}
              {profile.email && <div>Email: {profile.email}</div>}
            </div>
          </div>
        </div>

        <div className="text-right" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
          <div className="text-sm font-black uppercase tracking-wider" style={{ color: magentaAccent }}>
            SERVICE TAX INVOICE
          </div>
          <div className="font-bold text-gray-500 mb-1" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
          <div><span className="text-gray-500">Invoice Ref: </span><span className="font-bold text-gray-950 font-mono">{data.invoiceNumber}</span></div>
          <div><span className="text-gray-500">Invoice Date: </span><span>{data.issueDate}</span></div>
          {data.dueDate && <div><span className="text-gray-500">Payment Due: </span><span className="font-semibold text-gray-900">{data.dueDate}</span></div>}
          {data.placeOfSupply && (
            <div><span className="text-gray-500">Place of Supply: </span><span className="font-semibold">{data.placeOfSupply}</span></div>
          )}
        </div>
      </div>

      {/* ── Client / Service Recipient Block ── */}
      <div className="my-3 p-3 bg-pink-50/40 rounded-lg border border-pink-100 flex justify-between items-start" style={{ fontSize: '8.5px' }}>
        <div>
          <div className="font-extrabold uppercase tracking-wider mb-1" style={{ fontSize: '7.5px', color: magentaAccent }}>
            Client / Bill To:
          </div>
          <div className="font-bold text-sm text-gray-950">{client.name}</div>
          {client.gstNumber && (
            <div className="font-semibold text-gray-800">
              GSTIN: <span className="font-mono">{client.gstNumber}</span>
            </div>
          )}
          <div className="text-gray-700 whitespace-pre-line mt-0.5">{client.address}</div>
          {client.phone && <div>Phone: {client.phone}</div>}
          {client.email && <div>Email: {client.email}</div>}
        </div>

        <div className="text-right">
          <div className="font-extrabold uppercase tracking-wider mb-1 text-gray-500" style={{ fontSize: '7.5px' }}>
            Engagement Details
          </div>
          <div className="text-gray-700">Category: Consultancy & Professional Services</div>
          <div className="text-gray-700">SAC Code: 9983 / 9954</div>
        </div>
      </div>

      {/* ── Services Table with Hot Magenta Header ── */}
      <table className="inv-table my-3" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: magentaAccent, color: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '5%', padding: '6px 4px' }}>#</th>
            <th className="text-left" style={{ width: '45%', padding: '6px 8px' }}>Service Scope & Deliverables</th>
            <th className="text-center" style={{ width: '12%', padding: '6px 4px' }}>SAC Code</th>
            <th className="text-right" style={{ width: '14%', padding: '6px 6px' }}>Fee Rate</th>
            <th className="text-center" style={{ width: '8%', padding: '6px 4px' }}>Units/Qty</th>
            <th className="text-right" style={{ width: '16%', padding: '6px 8px' }}>Amount</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => (
            <tr key={idx} style={{ borderBottom: '1px solid #F3E8FF' }}>
              <td className="text-center text-gray-500 py-2.5">{idx + 1}</td>
              <td className="py-2.5 px-2">
                <div className="font-bold text-gray-950">{item.name}</div>
                {item.description && (
                  <div className="text-gray-600 text-xs mt-0.5 leading-snug" style={{ fontSize: '7.5px' }}>
                    {item.description}
                  </div>
                )}
              </td>
              <td className="text-center font-mono text-gray-700 py-2.5">{item.hsnSac || '998311'}</td>
              <td className="text-right font-medium py-2.5 px-2">{formatINR(item.rate)}</td>
              <td className="text-center py-2.5 font-medium">{item.quantity} {item.unit || 'units'}</td>
              <td className="text-right font-bold text-gray-950 py-2.5 px-2">{formatINR(item.total)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* ── Summary & Totals / Bank Details ── */}
      <div className="flex justify-between items-start my-3 pt-2">
        <div className="w-7/12 pr-4" style={{ fontSize: '8px' }}>
          <div className="p-2.5 bg-gray-50 border border-gray-200 rounded mb-2">
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
              <tr style={{ borderTop: `2px solid ${magentaAccent}`, borderBottom: `2px solid ${magentaAccent}` }}>
                <td className="py-2 font-black text-gray-950 text-sm uppercase">Total Payable:</td>
                <td className="py-2 font-black text-base" style={{ color: magentaAccent }}>{formatINR(data.totalAmount)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Signature & Agency Notes ── */}
      <div className="flex justify-between items-end my-3 pt-3 border-t border-gray-200">
        <div style={{ fontSize: '7.5px' }} className="text-gray-500 max-w-sm">
          {data.notes && <div><strong>Deliverable Note:</strong> {data.notes}</div>}
          {data.terms && <div className="mt-0.5"><strong>Payment Terms:</strong> {data.terms}</div>}
        </div>
        <SignatureBlock profile={profile} />
      </div>

      <InvoiceFooter pageNumber={1} totalPages={1} />
    </div>
  );
};
