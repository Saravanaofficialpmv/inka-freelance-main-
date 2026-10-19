import React from 'react';

interface InvoiceFooterProps {
  notes?: string;
  terms?: string[] | string;
  pageNumber?: number;
  totalPages?: number;
  isDigitallySigned?: boolean;
  className?: string;
}

const DEFAULT_TERMS = [
  '1. Goods once sold cannot be taken back or exchanged.',
  '2. We are not the manufacturers, company will stand for warranty as per their terms and conditions.',
  '3. Interest @24% p.a. will be charged for uncleared bills beyond 15 days.',
  '4. Subject to local Jurisdiction.',
];

export const InvoiceFooter: React.FC<InvoiceFooterProps> = ({
  notes = 'Thank you for the Business',
  terms = DEFAULT_TERMS,
  pageNumber = 1,
  totalPages = 1,
  isDigitallySigned = true,
  className = '',
}) => {
  const termsList = Array.isArray(terms) ? terms : [terms];

  return (
    <div className={`mt-3 ${className}`} style={{ fontSize: '7.5px', lineHeight: '1.3' }}>
      {notes && (
        <div className="mb-2">
          <div className="font-bold text-gray-900">Notes:</div>
          <div className="text-gray-700">{notes}</div>
        </div>
      )}

      {termsList.length > 0 && (
        <div className="mb-3 text-gray-600">
          <div className="font-bold text-gray-900">Terms & Conditions:</div>
          {termsList.map((t, idx) => (
            <div key={idx}>{t}</div>
          ))}
        </div>
      )}

      <div className="flex justify-between items-center pt-2 border-t border-gray-200 text-gray-500 font-medium" style={{ fontSize: '7px' }}>
        <div>Page {pageNumber} / {totalPages}</div>
        <div>{isDigitallySigned ? 'This is a digitally signed document.' : ''}</div>
      </div>
    </div>
  );
};
