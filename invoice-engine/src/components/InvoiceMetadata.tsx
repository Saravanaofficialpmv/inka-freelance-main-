import React from 'react';

interface MetadataProps {
  invoiceNumber: string;
  issueDate: string;
  dueDate?: string;
  placeOfSupply?: string;
  ewayBillNumber?: string;
  vehicleNumber?: string;
  layout?: 'stacked' | 'grid' | 'inline';
  className?: string;
}

export const InvoiceMetadata: React.FC<MetadataProps> = ({
  invoiceNumber,
  issueDate,
  dueDate,
  placeOfSupply,
  ewayBillNumber,
  vehicleNumber,
  layout = 'stacked',
  className = '',
}) => {
  if (layout === 'grid') {
    return (
      <div className={`grid grid-cols-2 gap-2 text-xs ${className}`} style={{ fontSize: '8.5px' }}>
        <div>
          <span className="text-gray-500 font-medium">Invoice #: </span>
          <span className="font-bold text-gray-900">{invoiceNumber}</span>
        </div>
        <div>
          <span className="text-gray-500 font-medium">Invoice Date: </span>
          <span className="text-gray-900">{issueDate}</span>
        </div>
        {dueDate && (
          <div>
            <span className="text-gray-500 font-medium">Due Date: </span>
            <span className="text-gray-900">{dueDate}</span>
          </div>
        )}
        {placeOfSupply && (
          <div>
            <span className="text-gray-500 font-medium">Place of Supply: </span>
            <span className="text-gray-900 font-semibold">{placeOfSupply}</span>
          </div>
        )}
        {ewayBillNumber && (
          <div>
            <span className="text-gray-500 font-medium">Eway Bill #: </span>
            <span className="text-gray-900">{ewayBillNumber}</span>
          </div>
        )}
        {vehicleNumber && (
          <div>
            <span className="text-gray-500 font-medium">Vehicle Number: </span>
            <span className="text-gray-900">{vehicleNumber}</span>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className={`text-right text-xs ${className}`} style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
      <div>
        <span className="text-gray-500 font-medium">Invoice #: </span>
        <span className="font-bold text-gray-900">{invoiceNumber}</span>
      </div>
      <div>
        <span className="text-gray-500 font-medium">Invoice Date: </span>
        <span className="text-gray-800">{issueDate}</span>
      </div>
      {dueDate && (
        <div>
          <span className="text-gray-500 font-medium">Due Date: </span>
          <span className="text-gray-800">{dueDate}</span>
        </div>
      )}
      {placeOfSupply && (
        <div>
          <span className="text-gray-500 font-medium">Place of Supply: </span>
          <span className="text-gray-900 font-semibold">{placeOfSupply}</span>
        </div>
      )}
    </div>
  );
};
