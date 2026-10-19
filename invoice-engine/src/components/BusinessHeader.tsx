import React from 'react';
import { BusinessProfileData } from '../types/invoice';

interface BusinessHeaderProps {
  profile: BusinessProfileData;
  title?: string;
  copyType?: string;
  className?: string;
  logoPosition?: 'left' | 'right' | 'center';
  showContact?: boolean;
}

export const BusinessHeader: React.FC<BusinessHeaderProps> = ({
  profile,
  title = 'TAX INVOICE',
  copyType = 'ORIGINAL FOR RECIPIENT',
  className = '',
  logoPosition = 'left',
  showContact = true,
}) => {
  return (
    <div className={`flex justify-between items-start ${className}`}>
      {/* Left: Logo & Business Info */}
      <div className="flex items-start gap-3">
        {profile.logoUrl && logoPosition === 'left' && (
          <img
            src={profile.logoUrl}
            alt={profile.businessName}
            style={{ maxHeight: '48px', maxWidth: '120px', objectFit: 'contain' }}
          />
        )}
        <div>
          <h1 className="text-lg font-bold text-gray-900 tracking-tight" style={{ fontSize: '15px' }}>
            {profile.businessName}
          </h1>
          {profile.gstNumber && (
            <div className="text-xs font-semibold text-gray-800" style={{ fontSize: '9px', marginTop: '1px' }}>
              {profile.taxLabel || 'GSTIN'} {profile.gstNumber}
            </div>
          )}
          {showContact && (
            <div className="text-xs text-gray-600 leading-tight" style={{ fontSize: '8.5px', marginTop: '2px', maxWidth: '280px' }}>
              {profile.address && <div>{profile.address}</div>}
              {(profile.phone || profile.email) && (
                <div>
                  {profile.phone && `Mobile: ${profile.phone}`}
                  {profile.phone && profile.email && '  '}
                  {profile.email && `Email: ${profile.email}`}
                </div>
              )}
              {profile.website && <div>Website: {profile.website}</div>}
            </div>
          )}
        </div>
      </div>

      {/* Right: TAX INVOICE Title & Copy Notice */}
      <div className="text-right">
        {profile.logoUrl && logoPosition === 'right' && (
          <img
            src={profile.logoUrl}
            alt={profile.businessName}
            style={{ maxHeight: '42px', maxWidth: '120px', objectFit: 'contain', marginBottom: '6px' }}
          />
        )}
        <div className="font-extrabold tracking-wider text-gray-900" style={{ fontSize: '13px' }}>
          {title}
        </div>
        <div className="font-semibold text-gray-500 tracking-wider" style={{ fontSize: '7.5px' }}>
          {copyType}
        </div>
      </div>
    </div>
  );
};
