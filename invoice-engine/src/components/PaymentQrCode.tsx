import React from 'react';
import { generateUpiUri, QrCodeImage } from '../utils/qrCode';

interface PaymentQrCodeProps {
  upiId?: string;
  payeeName: string;
  amount?: number;
  invoiceNumber?: string;
  size?: number;
  className?: string;
  qrDataOverride?: string;
}

export const PaymentQrCode: React.FC<PaymentQrCodeProps> = ({
  upiId,
  payeeName,
  amount = 0,
  invoiceNumber = '',
  size = 72,
  className = '',
  qrDataOverride,
}) => {
  const qrData =
    qrDataOverride ||
    (upiId ? generateUpiUri(upiId, payeeName, amount || 0, invoiceNumber) : '');

  if (!qrData) return null;

  return (
    <div className={`text-center ${className}`}>
      <div className="font-bold text-gray-900 mb-0.5" style={{ fontSize: '8px' }}>
        Pay using UPI:
      </div>
      <QrCodeImage data={qrData} size={size} />
    </div>
  );
};
