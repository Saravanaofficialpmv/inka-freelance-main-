import React from 'react';
import { BusinessProfileData } from '../types/invoice';

interface SignatureBlockProps {
  businessName?: string;
  signatureUrl?: string;
  profile?: BusinessProfileData;
  hasStamp?: boolean;
  className?: string;
  showReceiverSignature?: boolean;
}

export const SignatureBlock: React.FC<SignatureBlockProps> = ({
  businessName,
  signatureUrl,
  profile,
  hasStamp = true,
  className = '',
  showReceiverSignature = false,
}) => {
  const effectiveName = businessName || profile?.businessName || '';
  const effectiveSignatureUrl = signatureUrl || profile?.signatureUrl;

  return (
    <div className={`flex justify-between items-end ${className}`}>
      {showReceiverSignature ? (
        <div className="text-left" style={{ fontSize: '8px' }}>
          <div className="text-gray-800">Receiver's Signature:</div>
          <div className="border-b border-gray-400 w-36 mt-8"></div>
        </div>
      ) : (
        <div></div>
      )}

      <div className="text-right flex flex-col items-end" style={{ minWidth: '130px' }}>
        <div className="text-gray-600 font-semibold text-xs" style={{ fontSize: '8px', marginBottom: '2px' }}>
          For {effectiveName}
        </div>

        {/* Signature image or circular stamp */}
        <div
          className="flex items-center justify-center my-1"
          style={{ height: '48px', minWidth: '80px' }}
        >
          {effectiveSignatureUrl ? (
            <img
              src={effectiveSignatureUrl}
              alt="Signature"
              style={{ maxHeight: '44px', maxWidth: '120px', objectFit: 'contain' }}
            />
          ) : hasStamp ? (
            <div className="stamp-container">
              <span>Signature</span>
            </div>
          ) : (
            <div style={{ height: '36px' }}></div>
          )}
        </div>

        <div className="text-gray-600 text-xs font-medium" style={{ fontSize: '7.5px' }}>
          Authorized Signatory
        </div>
      </div>
    </div>
  );
};
