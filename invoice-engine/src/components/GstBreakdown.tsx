import React from 'react';
import { GstSummaryRow, InvoiceItemData, InvoicePayload } from '../types/invoice';
import { formatINR } from '../utils/currency';

interface GstBreakdownProps {
  data?: InvoicePayload;
  headerColor?: string;
  items?: InvoiceItemData[];
  taxPercentage?: number;
  taxAmount?: number;
  isInterState?: boolean;
  customBreakdown?: GstSummaryRow[];
  className?: string;
  bordered?: boolean;
}

export const GstBreakdown: React.FC<GstBreakdownProps> = ({
  data,
  headerColor,
  items: directItems,
  taxPercentage: directTaxPercentage,
  taxAmount: directTaxAmount,
  isInterState: directIsInterState,
  customBreakdown,
  className = '',
  bordered = true,
}) => {
  const effectiveItems = directItems || data?.items || [];
  const effectiveTaxPercentage = directTaxPercentage || data?.taxPercentage || 18;
  const isInterState =
    directIsInterState !== undefined
      ? directIsInterState
      : data?.igstAmount !== undefined && data.igstAmount > 0;

  // Aggregate items by HSN/SAC if customBreakdown is not provided
  const rows: GstSummaryRow[] =
    customBreakdown ||
    data?.gstBreakdown ||
    (() => {
      const map = new Map<string, { taxable: number; tax: number; rate: number }>();

      effectiveItems.forEach((item) => {
        const hsn = item.hsnSac || 'General';
        const itemTaxable =
          item.taxableAmount ??
          item.taxableValue ??
          item.quantity * (item.rate ?? item.price ?? 0);
        const rate = item.taxRate ?? item.taxPercentage ?? effectiveTaxPercentage;
        const itemTax = item.taxAmount ?? itemTaxable * (rate / 100);

        const existing = map.get(hsn) || { taxable: 0, tax: 0, rate };
        existing.taxable += itemTaxable;
        existing.tax += itemTax;
        map.set(hsn, existing);
      });

      return Array.from(map.entries()).map(([hsnSac, val]) => {
        if (isInterState) {
          return {
            hsnSac,
            taxableValue: val.taxable,
            igstRate: val.rate,
            igstAmount: val.tax,
            totalTaxAmount: val.tax,
          };
        } else {
          const halfRate = val.rate / 2;
          const halfTax = val.tax / 2;
          return {
            hsnSac,
            taxableValue: val.taxable,
            cgstRate: halfRate,
            cgstAmount: halfTax,
            sgstRate: halfRate,
            sgstAmount: halfTax,
            totalTaxAmount: val.tax,
          };
        }
      });
    })();

  const totalTaxable = rows.reduce(
    (s, r) => s + (r.taxableValue ?? r.taxableAmount ?? 0),
    0
  );
  const totalTax = rows.reduce(
    (s, r) => s + (r.totalTaxAmount ?? r.totalTax ?? 0),
    0
  );

  const tableClass = bordered ? 'inv-table inv-table-bordered' : 'inv-table';
  const headerStyle = headerColor
    ? { backgroundColor: headerColor, color: '#FFFFFF' }
    : { backgroundColor: '#F8FAFC' };

  return (
    <div className={`mt-2 ${className}`}>
      <table className={tableClass} style={{ fontSize: '8px', width: '100%' }}>
        <thead>
          <tr style={headerStyle}>
            <th rowSpan={2} className="text-left font-bold" style={{ width: '22%' }}>
              HSN/SAC
            </th>
            <th rowSpan={2} className="text-right font-bold" style={{ width: '22%' }}>
              Taxable Value
            </th>
            {isInterState ? (
              <th colSpan={2} className="text-center font-bold" style={{ width: '36%' }}>
                Integrated Tax
              </th>
            ) : (
              <>
                <th colSpan={2} className="text-center font-bold" style={{ width: '28%' }}>
                  Central Tax
                </th>
                <th colSpan={2} className="text-center font-bold" style={{ width: '28%' }}>
                  State / UT Tax
                </th>
              </>
            )}
            <th rowSpan={2} className="text-right font-bold" style={{ width: '20%' }}>
              Total Tax Amount
            </th>
          </tr>
          <tr style={headerStyle}>
            {isInterState ? (
              <>
                <th className="text-center font-semibold" style={{ fontSize: '7.5px' }}>
                  Rate
                </th>
                <th className="text-right font-semibold" style={{ fontSize: '7.5px' }}>
                  Amount
                </th>
              </>
            ) : (
              <>
                <th className="text-center font-semibold" style={{ fontSize: '7.5px' }}>
                  Rate
                </th>
                <th className="text-right font-semibold" style={{ fontSize: '7.5px' }}>
                  Amount
                </th>
                <th className="text-center font-semibold" style={{ fontSize: '7.5px' }}>
                  Rate
                </th>
                <th className="text-right font-semibold" style={{ fontSize: '7.5px' }}>
                  Amount
                </th>
              </>
            )}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, idx) => (
            <tr key={idx}>
              <td className="text-left font-mono">{row.hsnSac}</td>
              <td className="text-right font-mono">
                {formatINR(row.taxableValue ?? row.taxableAmount ?? 0, false)}
              </td>
              {isInterState ? (
                <>
                  <td className="text-center font-mono">
                    {row.igstRate ? `${row.igstRate}%` : '-'}
                  </td>
                  <td className="text-right font-mono">
                    {formatINR(row.igstAmount ?? 0, false)}
                  </td>
                </>
              ) : (
                <>
                  <td className="text-center font-mono">
                    {row.cgstRate ? `${row.cgstRate}%` : '-'}
                  </td>
                  <td className="text-right font-mono">
                    {formatINR(row.cgstAmount ?? 0, false)}
                  </td>
                  <td className="text-center font-mono">
                    {row.sgstRate ? `${row.sgstRate}%` : '-'}
                  </td>
                  <td className="text-right font-mono">
                    {formatINR(row.sgstAmount ?? 0, false)}
                  </td>
                </>
              )}
              <td className="text-right font-mono font-bold">
                {formatINR(row.totalTaxAmount ?? row.totalTax ?? 0, false)}
              </td>
            </tr>
          ))}
          <tr style={{ backgroundColor: '#F1F5F9', fontWeight: 'bold' }}>
            <td className="text-center">TOTAL</td>
            <td className="text-right font-mono">{formatINR(totalTaxable, false)}</td>
            {isInterState ? (
              <>
                <td></td>
                <td className="text-right font-mono">{formatINR(totalTax, false)}</td>
              </>
            ) : (
              <>
                <td></td>
                <td className="text-right font-mono">{formatINR(totalTax / 2, false)}</td>
                <td></td>
                <td className="text-right font-mono">{formatINR(totalTax / 2, false)}</td>
              </>
            )}
            <td className="text-right font-mono">{formatINR(totalTax, false)}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};
