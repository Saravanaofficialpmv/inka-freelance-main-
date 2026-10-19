import React from 'react';
import { BusinessProfileData } from '../types/invoice';

interface BankDetailsProps {
  profile: BusinessProfileData;
  className?: string;
  horizontal?: boolean;
}

export const BankDetails: React.FC<BankDetailsProps> = ({
  profile,
  className = '',
  horizontal = false,
}) => {
  const hasBank = profile.accountNo || profile.ifscCode || profile.bankName;

  if (!hasBank) return null;

  return (
    <div className={`text-xs ${className}`} style={{ fontSize: '8px', lineHeight: '1.45' }}>
      <div className="font-bold text-gray-900" style={{ fontSize: '8.5px', marginBottom: '1px' }}>
        Bank Details:
      </div>
      <table style={{ borderCollapse: 'collapse' }}>
        <tbody>
          {profile.bankName && (
            <tr>
              <td className="text-gray-600 font-medium pr-2">Bank:</td>
              <td className="font-bold text-gray-900">{profile.bankName}</td>
            </tr>
          )}
          {profile.accountNo && (
            <tr>
              <td className="text-gray-600 font-medium pr-2">Account #:</td>
              <td className="font-bold font-mono text-gray-950">{profile.accountNo}</td>
            </tr>
          )}
          {profile.ifscCode && (
            <tr>
              <td className="text-gray-600 font-medium pr-2">IFSC:</td>
              <td className="font-bold font-mono text-gray-950">{profile.ifscCode}</td>
            </tr>
          )}
          {profile.branchName && (
            <tr>
              <td className="text-gray-600 font-medium pr-2">Branch:</td>
              <td className="text-gray-800">{profile.branchName}</td>
            </tr>
          )}
          {profile.upiId && (
            <tr>
              <td className="text-gray-600 font-medium pr-2">UPI ID:</td>
              <td className="font-semibold text-gray-900">{profile.upiId}</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};
