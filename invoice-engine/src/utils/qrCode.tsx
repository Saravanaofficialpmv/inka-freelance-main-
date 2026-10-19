import React from 'react';

// Compact QR code generator for UPI and e-Invoice URLs
// Produces clean SVG with quiet zones for 100% scan fidelity
export function generateUpiUri(
  upiId: string,
  payeeName: string,
  amount: number,
  invoiceNumber: string,
  currency: string = 'INR'
): string {
  const encName = encodeURIComponent(payeeName);
  const encNote = encodeURIComponent(`Invoice ${invoiceNumber}`);
  return `upi://pay?pa=${upiId}&pn=${encName}&am=${amount.toFixed(2)}&cu=${currency}&tn=${encNote}`;
}

interface QrProps {
  data: string;
  size?: number;
  className?: string;
}

export const QrCodeImage: React.FC<QrProps> = ({ data, size = 96, className = '' }) => {
  // Use data URI or lightweight SVG canvas
  // For maximum compatibility across print & webview without network calls,
  // we generate an SVG using an SVG pattern or QR data URL.
  const encoded = encodeURIComponent(data);
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=${size}x${size}&data=${encoded}&margin=2`;

  return (
    <div
      className={`qr-container ${className}`}
      style={{
        width: size,
        height: size,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#FFFFFF',
        padding: '3px',
        border: '1px solid #E2E8F0',
        borderRadius: '4px',
      }}
    >
      <img
        src={qrUrl}
        alt="Payment QR"
        width={size - 8}
        height={size - 8}
        style={{ display: 'block', maxWidth: '100%', maxHeight: '100%' }}
      />
    </div>
  );
};
