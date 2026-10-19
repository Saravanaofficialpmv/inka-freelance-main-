import React from 'react';
import { TemplateProps } from '../types/template';
import { formatINR, formatQty } from '../utils/currency';
import { convertToIndianWords } from '../utils/numberToWords';
import { PaymentQrCode } from '../components/PaymentQrCode';
import { SignatureBlock } from '../components/SignatureBlock';
import { GstBreakdown } from '../components/GstBreakdown';
import { BankDetails } from '../components/BankDetails';
import { InvoiceFooter } from '../components/InvoiceFooter';

export const CompactTemplate: React.FC<TemplateProps> = ({ data }) => {
  const { profile, client, items } = data;

  const totalQty = items.reduce((s, i) => s + i.quantity, 0);

  return (
    <div className="invoice-page">
      {/* ── Top Bar: TAX INVOICE ── */}
      <div className="flex justify-between items-center border-b border-gray-900 pb-1 mb-2">
        <div className="w-1/3"></div>
        <div className="w-1/3 text-center font-extrabold text-sm tracking-wider text-gray-950">
          TAX INVOICE
        </div>
        <div className="w-1/3 text-right font-semibold text-gray-500" style={{ fontSize: '7.5px' }}>
          ORIGINAL FOR RECIPIENT
        </div>
      </div>

      {/* ── Boxed Metadata Grid ── */}
      <div className="border border-gray-900 grid grid-cols-2 text-xs" style={{ fontSize: '8px' }}>
        {/* Left Box: Business Details */}
        <div className="p-2 border-r border-gray-900">
          {profile.logoUrl && (
            <img
              src={profile.logoUrl}
              alt={profile.businessName}
              style={{ maxHeight: '36px', maxWidth: '110px', objectFit: 'contain', marginBottom: '4px' }}
            />
          )}
          <div className="font-bold text-gray-950 text-sm" style={{ fontSize: '10px' }}>
            {profile.businessName}
          </div>
          {profile.gstNumber && (
            <div className="font-semibold text-gray-900">
              {profile.taxLabel || 'GSTIN'}: {profile.gstNumber}
            </div>
          )}
          <div className="text-gray-700">{profile.address}</div>
          {profile.phone && <div>Mobile: {profile.phone}</div>}
        </div>

        {/* Right Box: Customer & Invoice Details */}
        <div className="p-2 leading-tight">
          <div className="font-bold text-gray-900 mb-0.5">Customer Details:</div>
          <div className="font-bold text-gray-950">{client.name}</div>
          {client.phone && <div>Ph: {client.phone}</div>}
          <div className="text-gray-700 mb-1">Billing Address: {client.address}</div>

          <div className="border-t border-gray-300 pt-1 mt-1 grid grid-cols-2 gap-x-2">
            <div><span className="text-gray-500">Invoice #: </span><span className="font-bold">{data.invoiceNumber}</span></div>
            <div><span className="text-gray-500">Invoice Date: </span><span>{data.issueDate}</span></div>
            <div><span className="text-gray-500">Due Date: </span><span>{data.dueDate}</span></div>
            <div><span className="text-gray-500">Place of Supply: </span><span className="font-bold">{data.placeOfSupply || '29-KARNATAKA'}</span></div>
          </div>
        </div>
      </div>

      {/* ── Boxed Grid Table with Vertical Dividers ── */}
      <table className="inv-table inv-table-bordered mt-2 mb-1" style={{ fontSize: '8px' }}>
        <thead>
          <tr style={{ backgroundColor: '#F8FAFC' }}>
            <th className="text-center" style={{ width: '4%' }}>#</th>
            <th className="text-left" style={{ width: '38%' }}>Item</th>
            <th className="text-center" style={{ width: '12%' }}>HSN / SAC</th>
            <th className="text-center" style={{ width: '7%' }}>Tax</th>
            <th className="text-center" style={{ width: '11%' }}>Qty</th>
            <th className="text-right" style={{ width: '13%' }}>Rate / Item</th>
            <th className="text-right" style={{ width: '15%' }}>Amount</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item, idx) => (
            <tr key={idx}>
              <td className="text-center">{idx + 1}</td>
              <td>
                <div className="font-bold text-gray-950">{item.name}</div>
                {item.description && <div className="text-gray-600 text-xs" style={{ fontSize: '7px' }}>{item.description}</div>}
              </td>
              <td className="text-center font-mono">{item.hsnSac || '392310'}</td>
              <td className="text-center font-mono">{item.taxPercentage || data.taxPercentage || 5}%</td>
              <td className="text-center font-mono">{item.quantity} {item.unit || 'NOS'}</td>
              <td className="text-right font-mono">{formatINR(item.price, false)}</td>
              <td className="text-right font-mono font-semibold">{formatINR(item.total, false)}</td>
            </tr>
          ))}

          {/* Delivery & Charges Rows */}
          {data.deliveryCharges && data.deliveryCharges > 0 && (
            <tr>
              <td></td>
              <td className="italic text-gray-700">Delivery / Shipping Charges</td>
              <td className="text-center font-mono">9968</td>
              <td></td>
              <td></td>
              <td></td>
              <td className="text-right font-mono">{formatINR(data.deliveryCharges, false)}</td>
            </tr>
          )}
          {data.packagingCharges && data.packagingCharges > 0 && (
            <tr>
              <td></td>
              <td className="italic text-gray-700">Packaging Charges</td>
              <td className="text-center font-mono">9967</td>
              <td></td>
              <td></td>
              <td></td>
              <td className="text-right font-mono">{formatINR(data.packagingCharges, false)}</td>
            </tr>
          )}

          {/* Subtotal & Taxes Breakdown */}
          <tr>
            <td colSpan={5} className="border-0"></td>
            <td className="text-right font-medium text-gray-600">Taxable Amount</td>
            <td className="text-right font-mono">{formatINR(data.subtotal, false)}</td>
          </tr>
          <tr>
            <td colSpan={5} className="border-0"></td>
            <td className="text-right font-medium text-gray-600">CGST {((data.taxPercentage ?? 18) / 2).toFixed(1)}%</td>
            <td className="text-right font-mono">{formatINR((data.taxAmount ?? 0) / 2, false)}</td>
          </tr>
          <tr>
            <td colSpan={5} className="border-0"></td>
            <td className="text-right font-medium text-gray-600">SGST {((data.taxPercentage ?? 18) / 2).toFixed(1)}%</td>
            <td className="text-right font-mono">{formatINR((data.taxAmount ?? 0) / 2, false)}</td>
          </tr>
          {data.roundOff !== undefined && data.roundOff !== 0 && (
            <tr>
              <td colSpan={5} className="border-0"></td>
              <td className="text-right font-medium text-gray-600">Round Off</td>
              <td className="text-right font-mono">{data.roundOff > 0 ? `+${data.roundOff}` : data.roundOff}</td>
            </tr>
          )}

          {/* Grand Total Row with Total Qty */}
          <tr style={{ backgroundColor: '#F1F5F9', fontWeight: 'bold' }}>
            <td colSpan={4} className="text-right">Total</td>
            <td className="text-center font-mono">{formatQty(totalQty)}</td>
            <td></td>
            <td className="text-right font-mono text-sm" style={{ fontSize: '10px' }}>
              {formatINR(data.total)}
            </td>
          </tr>
        </tbody>
      </table>

      {/* ── Amount Chargeable in Words ── */}
      <div className="text-xs text-gray-700 my-1 pb-1" style={{ fontSize: '7.5px' }}>
        <span className="text-gray-500 font-medium">Amount Chargeable (in words): </span>
        <span className="font-bold text-gray-900">{data.amountInWords || convertToIndianWords(data.total)} E & O.E</span>
      </div>

      {/* ── Indian GST Tax Summary Table ── */}
      <GstBreakdown
        items={items}
        taxPercentage={data.taxPercentage}
        taxAmount={data.taxAmount}
        isInterState={false}
      />

      {data.isPaid && (
        <div className="flex justify-end items-center gap-1.5 text-emerald-700 font-bold mt-1 text-xs" style={{ fontSize: '8.5px' }}>
          <span className="paid-badge-dot"></span>
          <span>Amount Paid {formatINR(data.total)} {data.paidDate && `via UPI on ${data.paidDate}`}</span>
        </div>
      )}

      {/* ── Bottom Box: Bank Details + UPI QR + Stamp ── */}
      <div className="border border-gray-900 flex justify-between items-start p-2 mt-2">
        <div style={{ width: '40%' }}>
          <BankDetails profile={profile} />
        </div>

        <div style={{ width: '25%' }} className="text-center">
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

        <div style={{ width: '30%' }}>
          <SignatureBlock businessName={profile.businessName} signatureUrl={profile.signatureUrl} />
        </div>
      </div>

      <InvoiceFooter notes={data.notes} terms={data.termsAndConditions} />
    </div>
  );
};
