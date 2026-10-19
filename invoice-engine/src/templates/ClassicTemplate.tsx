import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const ClassicTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const navyColor = '#003399';

  return (
    <div className="invoice-page">
      {/* ── Top Header ── */}
      <div className="flex justify-between items-start mb-3">
        <div className="flex items-start gap-3">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '42px', maxWidth: '120px', objectFit: 'contain' }}
            />
          )}
          <div>
            <h1 className="font-bold text-gray-950" style={{ fontSize: '15px' }}>{profile.businessName}</h1>
            {profile.gstNumber && (
              <div className="font-semibold text-gray-900" style={{ fontSize: '8.5px' }}>
                {profile.taxLabel || 'GSTIN'} {profile.gstNumber}
              </div>
            )}
            <div className="text-gray-700" style={{ fontSize: '8px', lineHeight: '1.3' }}>
              {profile.address && <div>{profile.address}</div>}
              {profile.phone && <div>Mobile {profile.phone}</div>}
            </div>
          </div>
        </div>

        <div className="text-right" style={{ fontSize: '8.5px', lineHeight: '1.35' }}>
          <div className="font-extrabold tracking-wider" style={{ fontSize: '13px', color: navyColor }}>
            TAX INVOICE
          </div>
          <div className="font-semibold text-gray-500 mb-1" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
          <div><span className="text-gray-500">Invoice #: </span><span className="font-bold text-gray-900">{data.invoiceNumber}</span></div>
          <div><span className="text-gray-500">Invoice Date: </span><span>{data.issueDate}</span></div>
          <div><span className="text-gray-500">Due Date: </span><span>{data.dueDate}</span></div>
        </div>
      </div>

      {/* ── 2-Column Parties ── */}
      <div className="flex justify-between items-start border-t border-gray-200 pt-2 pb-2 my-2 text-xs" style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
        <div className="flex-1">
          <div className="text-gray-600 font-medium">Bill To:</div>
          <div className="font-bold text-gray-950 text-sm">{client.name}</div>
          {client.phone && <div>Ph: {client.phone}</div>}
          <div className="text-gray-700">{client.address}</div>
          {data.placeOfSupply && (
            <div className="mt-1">
              <span className="text-gray-600">Place of Supply: </span>
              <span className="font-bold text-gray-950">{data.placeOfSupply}</span>
            </div>
          )}
        </div>

        <div className="flex-1">
          <div className="text-gray-600 font-medium">Ship to:</div>
          <div className="text-gray-700">
            {data.shipTo?.address || client.shippingAddress || client.address}
          </div>
        </div>
      </div>

      {/* ── Table with Solid Deep Navy Header ── */}
      <table className="inv-table my-2" style={{ fontSize: '8.5px', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: navyColor, color: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '5%', padding: '6px 4px' }}>#</th>
            <th className="text-left" style={{ width: '45%', padding: '6px 6px' }}>Item</th>
            <th className="text-center" style={{ width: '15%', padding: '6px 4px' }}>HSN/SAC</th>
            <th className="text-right" style={{ width: '15%', padding: '6px 6px' }}>Rate/Item</th>
            <th className="text-center" style={{ width: '8%', padding: '6px 4px' }}>Qty</th>
            <th className="text-right" style={{ width: '12%', padding: '6px 6px' }}>Amount</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => (
            <tr key={idx} style={{ borderBottom: '1px solid #E2E8F0' }}>
              <td className="text-center text-gray-600 py-2">{idx + 1}</td>
              <td className="py-2">
                <div className="font-bold text-gray-950">{item.name}</div>
                {item.description && (
                  <div className="text-gray-600 mt-0.5 leading-tight" style={{ fontSize: '7.5px' }}>
                    {item.description}
                  </div>
                )}
              </td>
              <td className="text-center font-mono text-gray-700 py-2">{item.hsnSac || '-'}</td>
              <td className="text-right font-mono py-2">{formatINR(item.price, false)}</td>
              <td className="text-center font-mono py-2">{item.quantity}</td>
              <td className="text-right font-mono font-bold text-gray-950 py-2">{formatINR(item.total, false)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* ── Financial Summary ── */}
      <div className="flex justify-end mt-2">
        <div style={{ width: '42%' }}>
          <table className="w-full text-xs" style={{ fontSize: '8.5px', lineHeight: '1.5' }}>
            <tbody>
              <tr>
                <td className="text-gray-600 font-medium">Taxable Amount</td>
                <td className="text-right font-mono font-bold text-gray-900">{formatINR(data.subtotal)}</td>
              </tr>
              <tr>
                <td className="text-gray-600 font-medium">IGST {(data.taxPercentage ?? 18).toFixed(1)}%</td>
                <td className="text-right font-mono font-bold text-gray-900">{formatINR(data.taxAmount)}</td>
              </tr>
              {data.roundOff !== undefined && data.roundOff !== 0 && (
                <tr>
                  <td className="text-gray-600 font-medium">Round Off</td>
                  <td className="text-right font-mono text-gray-800">{data.roundOff > 0 ? `+${data.roundOff}` : data.roundOff}</td>
                </tr>
              )}
              <tr style={{ borderTop: '1px solid #111827', borderBottom: '1px solid #111827' }}>
                <td className="font-extrabold text-sm py-1.5" style={{ fontSize: '11px' }}>Total</td>
                <td className="text-right font-mono font-extrabold text-sm py-1.5" style={{ fontSize: '12px' }}>
                  {formatINR(data.total)}
                </td>
              </tr>
              {data.amountPayable !== undefined && (
                <tr>
                  <td className="text-gray-600 font-medium pt-1">Amount Payable:</td>
                  <td className="text-right font-mono font-bold text-gray-900 pt-1">{formatINR(data.amountPayable)}</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Items & Amount in Words ── */}
      <div className="text-xs text-gray-700 mt-1 mb-3 pb-1 border-b border-gray-200" style={{ fontSize: '7.5px' }}>
        <div>Total Items / Qty : {data.totalItemsCount || items.length} / {items.reduce((s, i) => s + i.quantity, 0)}</div>
        <div className="mt-0.5">
          <span className="font-medium text-gray-600">Total amount (in words): </span>
          <span className="font-semibold text-gray-900">{data.amountInWords || convertToIndianWords(data.total)}</span>
        </div>
      </div>

      {/* ── Bottom Section: Pay using UPI + Bank Details + Stamp ── */}
      <div className="flex justify-between items-start mt-2">
        <div style={{ width: '22%' }}>
          {profile.upiId && (
            <PaymentQrCode
              upiId={profile.upiId}
              payeeName={profile.businessName}
              amount={data.total}
              invoiceNumber={data.invoiceNumber}
              size={68}
            />
          )}
        </div>

        <div style={{ width: '45%' }}>
          <BankDetails profile={profile} />
        </div>

        <div style={{ width: '30%' }}>
          <SignatureBlock businessName={profile.businessName} signatureUrl={profile.signatureUrl} />
        </div>
      </div>

      <InvoiceFooter notes={data.notes} terms={data.termsAndConditions} />
    </div>
  );
};
