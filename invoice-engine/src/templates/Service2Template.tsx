import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const Service2Template: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const corporateTeal = '#004B6E'; // LTIMindtree Corporate Dark Teal / Slate

  return (
    <div className="invoice-page font-sans text-gray-900">
      {/* ── Top Corporate Consulting Header ── */}
      <div className="flex justify-between items-start pb-3 border-b-2 border-gray-800">
        <div className="flex items-start gap-3">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '46px', maxWidth: '120px', objectFit: 'contain' }}
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
            <div className="text-gray-600 mt-0.5" style={{ fontSize: '8px', lineHeight: '1.3' }}>
              {profile.address && <div>{profile.address}</div>}
              {profile.phone && <div>Tel: {profile.phone}</div>}
              {profile.email && <div>Email: {profile.email}</div>}
            </div>
          </div>
        </div>

        <div className="text-right" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
          <div className="text-sm font-black tracking-wider uppercase" style={{ color: corporateTeal }}>
            CONSULTING TAX INVOICE
          </div>
          <div className="font-bold text-gray-500 mb-1" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
          <div><span className="text-gray-500">Invoice No: </span><span className="font-bold text-gray-950 font-mono">{data.invoiceNumber}</span></div>
          <div><span className="text-gray-500">Date of Invoice: </span><span className="font-medium">{data.issueDate}</span></div>
          {data.dueDate && <div><span className="text-gray-500">Due Date: </span><span>{data.dueDate}</span></div>}
          {data.placeOfSupply && (
            <div><span className="text-gray-500">Place of Supply: </span><span className="font-semibold">{data.placeOfSupply}</span></div>
          )}
        </div>
      </div>

      {/* ── Client & Project Details (2-Column Boxed) ── */}
      <div className="grid grid-cols-2 border border-gray-300 rounded my-2 text-xs" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
        <div className="p-2.5 border-r border-gray-300">
          <div className="font-bold text-gray-500 uppercase tracking-wider mb-1" style={{ fontSize: '7.5px' }}>
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

        <div className="p-2.5 bg-gray-50">
          <div className="font-bold text-gray-500 uppercase tracking-wider mb-1" style={{ fontSize: '7.5px' }}>
            Billing Particulars:
          </div>
          <div><span className="text-gray-600">Service Category: </span><span className="font-medium">IT Consulting & Software Services</span></div>
          <div><span className="text-gray-600">SAC Code: </span><span className="font-mono font-medium">998314</span></div>
          {data.notes && <div><span className="text-gray-600">Engagement Ref: </span><span>{data.notes}</span></div>}
        </div>
      </div>

      {/* ── Structured Service Table ── */}
      <table className="inv-table my-2" style={{ fontSize: '8px', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: corporateTeal, color: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '4%', padding: '5px 3px' }}>#</th>
            <th className="text-left" style={{ width: '44%', padding: '5px 6px' }}>Professional Service / Milestone</th>
            <th className="text-center" style={{ width: '12%', padding: '5px 3px' }}>SAC</th>
            <th className="text-right" style={{ width: '12%', padding: '5px 4px' }}>Rate / Hr</th>
            <th className="text-center" style={{ width: '8%', padding: '5px 3px' }}>Hours/Qty</th>
            <th className="text-center" style={{ width: '6%', padding: '5px 3px' }}>GST %</th>
            <th className="text-right" style={{ width: '14%', padding: '5px 6px' }}>Total Amount</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => (
            <tr key={idx} style={{ borderBottom: '1px solid #E2E8F0' }}>
              <td className="text-center text-gray-500 py-2">{idx + 1}</td>
              <td className="py-2 px-2">
                <div className="font-bold text-gray-950">{item.name}</div>
                {item.description && (
                  <div className="text-gray-600 text-xs mt-0.5 leading-tight" style={{ fontSize: '7.5px' }}>
                    {item.description}
                  </div>
                )}
              </td>
              <td className="text-center font-mono text-gray-700 py-2">{item.hsnSac || '998314'}</td>
              <td className="text-right font-medium py-2 px-1">{formatINR(item.rate)}</td>
              <td className="text-center py-2 font-medium">{item.quantity} {item.unit || 'hrs'}</td>
              <td className="text-center py-2 text-gray-700">{item.taxRate !== undefined ? `${item.taxRate}%` : '-'}</td>
              <td className="text-right font-bold text-gray-950 py-2 px-2">{formatINR(item.total)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* ── Summary & Totals / Bank Details ── */}
      <div className="flex justify-between items-start my-2 pt-1">
        <div className="w-7/12 pr-4" style={{ fontSize: '8px' }}>
          <div className="p-2 bg-gray-50 border border-gray-200 rounded mb-2">
            <span className="font-bold text-gray-700 uppercase" style={{ fontSize: '7.5px' }}>Amount Chargeable in Words:</span>
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
              <tr style={{ borderTop: `2px solid ${corporateTeal}`, borderBottom: `2px solid ${corporateTeal}` }}>
                <td className="py-1.5 font-bold text-gray-950 uppercase">Total Payable:</td>
                <td className="py-1.5 font-extrabold text-sm" style={{ color: corporateTeal }}>{formatINR(data.totalAmount)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Dual Signatures: Client Acceptance & Authorized Signatory ── */}
      <div className="grid grid-cols-2 gap-4 mt-3 pt-3 border-t border-gray-300">
        <div className="flex flex-col justify-end">
          <div className="border-t border-dashed border-gray-400 w-44 pt-1 text-center font-bold text-gray-700" style={{ fontSize: '7.5px' }}>
            Client Acceptance Signature
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
