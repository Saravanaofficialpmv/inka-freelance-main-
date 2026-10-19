import React from 'react';
import { ClientData, ShippingPartyData } from '../types/invoice';

interface BillingPartiesProps {
  client: ClientData;
  shipTo?: ShippingPartyData;
  showShipping?: boolean;
  className?: string;
  variant?: 'inline' | 'two-column' | 'boxed';
}

export const BillingParties: React.FC<BillingPartiesProps> = ({
  client,
  shipTo,
  showShipping = true,
  className = '',
  variant = 'two-column',
}) => {
  const hasShipping = showShipping && (shipTo?.address || client.shippingAddress);
  const shippingAddress = shipTo?.address || client.shippingAddress;
  const shippingName = shipTo?.name || client.name;
  const shippingPhone = shipTo?.phone || client.phone;

  if (variant === 'boxed') {
    return (
      <div className={`grid grid-cols-2 border border-gray-900 ${className}`} style={{ fontSize: '8.5px' }}>
        <div className="p-2 border-r border-gray-900 leading-snug">
          <div className="font-bold text-gray-700 text-xs uppercase" style={{ fontSize: '8px', marginBottom: '2px' }}>
            Customer Details:
          </div>
          <div className="font-bold text-gray-950 text-sm" style={{ fontSize: '9.5px' }}>
            {client.name}
          </div>
          {client.gstin && <div className="font-semibold text-gray-900">GSTIN: {client.gstin}</div>}
          <div className="text-gray-500 font-medium" style={{ marginTop: '2px' }}>Billing address:</div>
          <div className="text-gray-800">{client.address}</div>
          {client.phone && <div>Ph: {client.phone}</div>}
        </div>

        <div className="p-2 leading-snug">
          <div className="font-bold text-gray-700 text-xs uppercase" style={{ fontSize: '8px', marginBottom: '2px' }}>
            Shipping Address:
          </div>
          {hasShipping ? (
            <>
              {shippingName && shippingName !== client.name && (
                <div className="font-bold text-gray-950">{shippingName}</div>
              )}
              <div className="text-gray-800">{shippingAddress}</div>
              {shippingPhone && <div>Ph: {shippingPhone}</div>}
            </>
          ) : (
            <div className="text-gray-400 italic">Same as billing address</div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className={`flex justify-between items-start gap-4 ${className}`} style={{ fontSize: '8.5px', lineHeight: '1.4' }}>
      {/* Bill To Column */}
      <div className="flex-1">
        <div className="font-bold text-gray-700 uppercase" style={{ fontSize: '8px' }}>
          Bill To:
        </div>
        <div className="font-bold text-gray-950 text-sm" style={{ fontSize: '10px' }}>
          {client.name}
        </div>
        {client.gstin && (
          <div className="font-semibold text-gray-900">GSTIN: {client.gstin}</div>
        )}
        {client.phone && <div className="text-gray-600">Ph: {client.phone}</div>}
        <div className="text-gray-700 mt-0.5">{client.address}</div>
        {client.placeOfSupply && (
          <div className="text-gray-600 mt-0.5">
            Place of Supply: <span className="font-semibold text-gray-900">{client.placeOfSupply}</span>
          </div>
        )}
      </div>

      {/* Ship To Column */}
      {showShipping && (
        <div className="flex-1">
          <div className="font-bold text-gray-700 uppercase" style={{ fontSize: '8px' }}>
            Ship To:
          </div>
          {hasShipping ? (
            <>
              {shippingName && (
                <div className="font-bold text-gray-950 text-sm" style={{ fontSize: '10px' }}>
                  {shippingName}
                </div>
              )}
              {shippingPhone && <div className="text-gray-600">Ph: {shippingPhone}</div>}
              <div className="text-gray-700 mt-0.5">{shippingAddress}</div>
            </>
          ) : (
            <div className="text-gray-400 italic">Same as billing address</div>
          )}
        </div>
      )}
    </div>
  );
};
