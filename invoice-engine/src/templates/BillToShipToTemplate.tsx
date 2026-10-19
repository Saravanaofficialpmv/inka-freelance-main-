import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR, formatQty } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { FourPartiesGrid } from '../components/ShippingParties';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const BillToShipToTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;
  const isInterState = data.placeOfSupply && !data.placeOfSupply.toLowerCase().includes('same');

  return (
    <div className="invoice-page">
      {/* ── Top Header ── */}
      <div className="flex justify-between items-start mb-3">
        <div className="flex items-start gap-3">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '48px', maxWidth: '110px', objectFit: 'contain' }}
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
              {profile.phone && <div>Mobile: {profile.phone}</div>}
              {profile.email && <div>Email: {profile.email}</div>}
              {profile.website && <div>Website: {profile.website}</div>}
            </div>
          </div>
        </div>

        <div className="text-right" style={{ fontSize: '8.5px', lineHeight: '1.35' }}>
          <div className="font-extrabold tracking-wider text-gray-950" style={{ fontSize: '13px' }}>
            TAX INVOICE
          </div>
          <div className="font-semibold text-gray-500 mb-1" style={{ fontSize: '7.5px' }}>
            ORIGINAL FOR RECIPIENT
          </div>
          <div><span className="text-gray-600 font-medium">Invoice #: </span><span className="font-bold">{data.invoiceNumber}</span></div>
          <div><span className="text-gray-600 font-medium">Invoice Date: </span><span>{data.issueDate}</span></div>
          <div><span className="text-gray-600 font-medium">Due Date: </span><span>{data.dueDate}</span></div>
        </div>
      </div>

      {/* ── 4 Parties Grid: Bill From, Bill To, Ship From, Ship To ── */}
      <div className="border-t border-b border-gray-300 py-2.5 my-2">
        <FourPartiesGrid
          profile={profile}
          client={client}
          shipFrom={data.shipFrom}
          shipTo={data.shipTo}
          placeOfSupply={data.placeOfSupply}
        />
      </div>

      {/* ── 8-Column Bordered Table ── */}
      <table className="inv-table inv-table-bordered my-2" style={{ fontSize: '8px' }}>
        <thead>
          <tr style={{ backgroundColor: '#FFFFFF' }}>
            <th className="text-center" style={{ width: '4%' }}>#</th>
            <th className="text-left" style={{ width: '38%' }}>Item</th>
            <th className="text-center" style={{ width: '12%' }}>HSN/SAC</th>
            <th className="text-right" style={{ width: '11%' }}>Rate/Item</th>
            <th className="text-center" style={{ width: '6%' }}>Qty</th>
            <th className="text-right" style={{ width: '11%' }}>Taxable Value</th>
            <th className="text-right" style={{ width: '10%' }}>Tax Amount</th>
            <th className="text-right" style={{ width: '11%' }}>Amount</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => {
            const itemPrice = item.rate ?? item.price ?? 0;
            const taxable = item.taxableValue || item.quantity * itemPrice;
            const rate = item.taxPercentage || data.taxPercentage || 18;
            const tax = item.taxAmount || taxable * (rate / 100);
            return (
              <tr key={idx}>
                <td className="text-center">{idx + 1}</td>
                <td>
                  <div className="font-bold text-gray-950">{item.name}</div>
                  {item.description && (
                    <div className="text-gray-600" style={{ fontSize: '7.5px' }}>{item.description}</div>
                  )}
                </td>
                <td className="text-center font-mono">{item.hsnSac || '-'}</td>
                <td className="text-right font-mono">{formatINR(itemPrice, false)}</td>
                <td className="text-center font-mono">{item.quantity}</td>
                <td className="text-right font-mono">{formatINR(taxable, false)}</td>
                <td className="text-right font-mono">
                  {formatINR(tax, false)} <span className="text-gray-500">({rate}%)</span>
                </td>
                <td className="text-right font-mono font-bold">{formatINR(item.total, false)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {/* ── Financial Summary & Payment Box ── */}
      <div className="flex justify-between items-start mt-2 pt-1 border-t border-gray-300">
        <div style={{ width: '38%' }}>
          <BankDetails profile={profile} />
        </div>

        <div className="text-center" style={{ width: '24%' }}>
          {profile.upiId && (
            <PaymentQrCode
              upiId={profile.upiId}
              payeeName={profile.businessName}
              amount={data.total}
              invoiceNumber={data.invoiceNumber}
              size={64}
            />
          )}
        </div>

        <div style={{ width: '36%' }}>
          <table className="w-full text-xs" style={{ fontSize: '8.5px', lineHeight: '1.45' }}>
            <tbody>
              <tr>
                <td className="text-gray-600 font-medium">Taxable Amount</td>
                <td className="text-right font-mono font-semibold">{formatINR(data.subtotal)}</td>
              </tr>
              <tr>
                <td className="text-gray-600 font-medium">
                  {isInterState ? `IGST ${data.taxPercentage.toFixed(1)}%` : `GST ${data.taxPercentage.toFixed(1)}%`}
                </td>
                <td className="text-right font-mono font-semibold">{formatINR(data.taxAmount)}</td>
              </tr>
              {data.discount > 0 && (
                <tr>
                  <td className="text-gray-600 font-medium">Discount</td>
                  <td className="text-right font-mono text-emerald-700">-{formatINR(data.discount)}</td>
                </tr>
              )}
              {data.roundOff !== undefined && data.roundOff !== 0 && (
                <tr>
                  <td className="text-gray-600 font-medium">Round Off</td>
                  <td className="text-right font-mono">{data.roundOff > 0 ? `+${data.roundOff}` : data.roundOff}</td>
                </tr>
              )}
            </tbody>
          </table>

          {/* Bordered Total Box */}
          <div className="border border-gray-900 flex justify-between items-center px-3 py-1.5 mt-1.5 font-bold">
            <span style={{ fontSize: '10px' }}>Total</span>
            <span className="font-mono" style={{ fontSize: '12px' }}>{formatINR(data.total)}</span>
          </div>

          {data.isPaid && (
            <div className="flex justify-end items-center gap-1.5 text-emerald-700 font-bold mt-1" style={{ fontSize: '9px' }}>
              <span className="paid-badge-dot"></span>
              <span>Amount Paid</span>
            </div>
          )}
        </div>
      </div>

      {/* ── Total Items & Amount in Words ── */}
      <div className="text-xs text-gray-700 mt-2 pt-2 border-t border-gray-200" style={{ fontSize: '8px' }}>
        <div>Total Items / Qty : {data.totalItemsCount || items.length} / {formatQty(data.totalQuantity || items.reduce((s, i) => s + i.quantity, 0))}</div>
        <div className="mt-0.5">
          <span className="font-medium text-gray-600">Total amount (in words): </span>
          <span className="font-semibold text-gray-900">{data.amountInWords || convertToIndianWords(data.total)}</span>
        </div>
      </div>

      {/* ── Signature & Notes ── */}
      <div className="mt-4">
        <SignatureBlock businessName={profile.businessName} signatureUrl={profile.signatureUrl} />
      </div>

      <InvoiceFooter notes={data.notes} terms={data.termsAndConditions} />
    </div>
  );
};
