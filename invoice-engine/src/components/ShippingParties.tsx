import React from 'react';
import { BusinessProfileData, ClientData, ShippingPartyData } from '../types/invoice';

interface FourPartiesProps {
  profile: BusinessProfileData;
  client: ClientData;
  shipFrom?: ShippingPartyData;
  shipTo?: ShippingPartyData;
  placeOfSupply?: string;
  className?: string;
}

export const FourPartiesGrid: React.FC<FourPartiesProps> = ({
  profile,
  client,
  shipFrom,
  shipTo,
  placeOfSupply,
  className = '',
}) => {
  return (
    <div className={`grid grid-cols-2 gap-x-6 gap-y-3 text-xs leading-snug ${className}`} style={{ fontSize: '8.5px' }}>
      {/* Bill From */}
      <div>
        <div className="font-bold text-gray-900" style={{ fontSize: '8.5px' }}>Bill From:</div>
        <div className="font-bold text-gray-950">{profile.businessName}</div>
        <div className="text-gray-700">{profile.address}</div>
      </div>

      {/* Bill To */}
      <div>
        <div className="font-bold text-gray-900" style={{ fontSize: '8.5px' }}>Bill To:</div>
        <div className="font-bold text-gray-950">{client.name}</div>
        <div className="text-gray-700">{client.address}</div>
        {client.phone && <div>Ph: {client.phone}</div>}
      </div>

      {/* Ship From */}
      <div>
        <div className="font-bold text-gray-900" style={{ fontSize: '8.5px' }}>Ship From:</div>
        <div className="text-gray-700">{shipFrom?.address || profile.address}</div>
        {placeOfSupply && (
          <div className="font-bold text-gray-900 mt-1">
            Place of Supply: <span className="font-bold">{placeOfSupply}</span>
          </div>
        )}
      </div>

      {/* Ship To */}
      <div>
        <div className="font-bold text-gray-900" style={{ fontSize: '8.5px' }}>Ship To:</div>
        <div className="text-gray-700">{shipTo?.address || client.shippingAddress || client.address}</div>
        {(shipTo?.phone || client.phone) && <div>Ph: {shipTo?.phone || client.phone}</div>}
      </div>
    </div>
  );
};
