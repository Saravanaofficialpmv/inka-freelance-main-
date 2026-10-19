import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { InvoicePayload } from '../types/invoice';
import { TemplateId } from '../types/template';
import { getTemplate } from '../registry/templateRegistry';

// Core CSS bundled directly for standalone offline rendering
const BASE_PRINT_CSS = `
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

@page {
  size: A4 portrait;
  margin: 10mm;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  color: #111827;
  background-color: #FFFFFF;
  line-height: 1.4;
  -webkit-print-color-adjust: exact !important;
  print-color-adjust: exact !important;
}

.invoice-page {
  width: 100%;
  max-width: 190mm;
  margin: 0 auto;
  background: #FFFFFF;
}

/* Flexbox utilities */
.flex { display: flex; }
.flex-col { flex-direction: column; }
.items-center { align-items: center; }
.items-start { align-items: flex-start; }
.items-end { align-items: flex-end; }
.justify-between { justify-content: space-between; }
.justify-center { justify-content: center; }
.justify-end { justify-content: flex-end; }
.flex-1 { flex: 1 1 0%; }
.flex-shrink-0 { flex-shrink: 0; }
.gap-1 { gap: 4px; }
.gap-2 { gap: 8px; }
.gap-3 { gap: 12px; }
.gap-4 { gap: 16px; }

/* Grid utilities */
.grid { display: grid; }
.grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.grid-cols-4 { grid-template-columns: repeat(4, minmax(0, 1fr)); }
.grid-cols-12 { grid-template-columns: repeat(12, minmax(0, 1fr)); }
.col-span-2 { grid-column: span 2 / span 2; }
.col-span-3 { grid-column: span 3 / span 3; }
.col-span-7 { grid-column: span 7 / span 7; }

/* Spacing */
.m-0 { margin: 0; }
.mb-1 { margin-bottom: 4px; }
.mb-2 { margin-bottom: 8px; }
.mb-3 { margin-bottom: 12px; }
.mb-4 { margin-bottom: 16px; }
.mt-0\\.5 { margin-top: 2px; }
.mt-1 { margin-top: 4px; }
.mt-2 { margin-top: 8px; }
.mt-3 { margin-top: 12px; }
.my-1 { margin-top: 4px; margin-bottom: 4px; }
.my-2 { margin-top: 8px; margin-bottom: 8px; }
.my-3 { margin-top: 12px; margin-bottom: 12px; }
.p-1 { padding: 4px; }
.p-1\\.5 { padding: 6px; }
.p-2 { padding: 8px; }
.p-2\\.5 { padding: 10px; }
.p-3 { padding: 12px; }
.p-4 { padding: 16px; }
.py-0\\.5 { padding-top: 2px; padding-bottom: 2px; }
.py-1 { padding-top: 4px; padding-bottom: 4px; }
.py-1\\.5 { padding-top: 6px; padding-bottom: 6px; }
.py-2 { padding-top: 8px; padding-bottom: 8px; }
.py-2\\.5 { padding-top: 10px; padding-bottom: 10px; }
.py-3 { padding-top: 12px; padding-bottom: 12px; }
.py-4 { padding-top: 16px; padding-bottom: 16px; }
.px-1 { padding-left: 4px; padding-right: 4px; }
.px-2 { padding-left: 8px; padding-right: 8px; }
.px-2\\.5 { padding-left: 10px; padding-right: 10px; }
.px-3 { padding-left: 12px; padding-right: 12px; }
.px-4 { padding-left: 16px; padding-right: 16px; }
.pt-1 { padding-top: 4px; }
.pt-2 { padding-top: 8px; }
.pt-3 { padding-top: 12px; }
.pb-1 { padding-bottom: 4px; }
.pb-2 { padding-bottom: 8px; }
.pb-3 { padding-bottom: 12px; }
.pb-4 { padding-bottom: 16px; }
.pl-2 { padding-left: 8px; }
.pl-4 { padding-left: 16px; }
.pr-4 { padding-right: 16px; }

/* Width / Height */
.w-full { width: 100%; }
.w-7\\/12 { width: 58.333333%; }
.w-5\\/12 { width: 41.666667%; }
.w-7 { width: 28px; }
.h-7 { height: 28px; }
.w-8 { width: 32px; }
.h-8 { height: 32px; }
.w-9 { width: 36px; }
.h-9 { height: 36px; }
.w-12 { width: 48px; }
.h-12 { height: 48px; }
.w-44 { width: 176px; }
.max-w-sm { max-width: 384px; }
.max-w-lg { max-width: 512px; }

/* Typography */
.font-sans { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
.font-mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
.font-normal { font-weight: 400; }
.font-medium { font-weight: 500; }
.font-semibold { font-weight: 600; }
.font-bold { font-weight: 700; }
.font-extrabold { font-weight: 800; }
.font-black { font-weight: 900; }
.italic { font-style: italic; }
.not-italic { font-style: normal; }
.uppercase { text-transform: uppercase; }
.tracking-tight { letter-spacing: -0.025em; }
.tracking-wide { letter-spacing: 0.025em; }
.tracking-wider { letter-spacing: 0.05em; }
.tracking-widest { letter-spacing: 0.1em; }
.text-left { text-align: left; }
.text-center { text-align: center; }
.text-right { text-align: right; }
.line-through { text-decoration: line-through; }
.truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.whitespace-pre-line { white-space: pre-line; }
.leading-tight { line-height: 1.25; }
.leading-snug { line-height: 1.375; }

/* Font sizes */
.text-xs { font-size: 9px; line-height: 1.2; }
.text-sm { font-size: 11px; line-height: 1.3; }
.text-base { font-size: 13px; line-height: 1.4; }
.text-lg { font-size: 15px; line-height: 1.4; }
.text-xl { font-size: 18px; line-height: 1.3; }

/* Colors */
.text-white { color: #FFFFFF; }
.text-gray-400 { color: #9CA3AF; }
.text-gray-500 { color: #6B7280; }
.text-gray-600 { color: #4B5563; }
.text-gray-700 { color: #374151; }
.text-gray-800 { color: #1F2937; }
.text-gray-900 { color: #111827; }
.text-gray-950 { color: #030712; }
.text-blue-100 { color: #DBEAFE; }
.text-blue-600 { color: #2563EB; }
.text-blue-700 { color: #1D4ED8; }
.text-blue-900 { color: #1E3A8A; }
.text-green-700 { color: #15803D; }
.text-green-900 { color: #14532D; }
.text-red-600 { color: #DC2626; }

/* Backgrounds */
.bg-white { background-color: #FFFFFF; }
.bg-gray-50 { background-color: #F9FAFB; }
.bg-gray-100 { background-color: #F3F4F6; }
.bg-blue-50 { background-color: #EFF6FF; }
.bg-green-50 { background-color: #F0FDF4; }
.bg-pink-50 { background-color: #FDF2F8; }

/* Borders */
.border { border: 1px solid #E5E7EB; }
.border-2 { border-width: 2px; }
.border-t { border-top: 1px solid #E5E7EB; }
.border-b { border-bottom: 1px solid #E5E7EB; }
.border-l { border-left: 1px solid #E5E7EB; }
.border-r { border-right: 1px solid #E5E7EB; }
.border-dashed { border-style: dashed; }
.border-gray-100 { border-color: #F3F4F6; }
.border-gray-200 { border-color: #E5E7EB; }
.border-gray-300 { border-color: #D1D5DB; }
.border-gray-400 { border-color: #9CA3AF; }
.border-gray-800 { border-color: #1F2937; }
.border-gray-900 { border-color: #111827; }
.border-blue-100 { border-color: #DBEAFE; }
.border-blue-900 { border-color: #1E3A8A; }
.border-green-300 { border-color: #86EFAC; }
.border-pink-100 { border-color: #FCE7F3; }

.rounded { border-radius: 4px; }
.rounded-lg { border-radius: 8px; }
.rounded-xl { border-radius: 12px; }
.rounded-full { border-radius: 9999px; }

/* Tables */
.inv-table {
  width: 100%;
  border-collapse: collapse;
}

.inv-table th, .inv-table td {
  padding: 4px 6px;
  vertical-align: middle;
}

.inv-table-bordered {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid #9CA3AF;
}

.inv-table-bordered th, .inv-table-bordered td {
  border: 1px solid #CBD5E1;
  padding: 4px 6px;
  vertical-align: middle;
}
`;

/**
 * Renders an invoice template to a fully self-contained HTML document.
 * This HTML string can be fed directly into Printing.convertHtml() or rendered in a WebView.
 */
export function renderInvoiceToHtml(templateId: TemplateId | string, data: InvoicePayload): string {
  const Component = getTemplate(templateId);
  const content = renderToStaticMarkup(React.createElement(Component, { data }));

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice - ${data.invoiceNumber}</title>
  <style>
    ${BASE_PRINT_CSS}
  </style>
</head>
<body>
  <div id="invoice-root">
    ${content}
  </div>
</body>
</html>`;
}
