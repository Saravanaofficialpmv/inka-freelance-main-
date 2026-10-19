/**
 * Formats monetary amounts using the Indian currency system (Lakhs & Crores)
 * Example: 190399 -> "₹1,90,399.00"
 */
export function formatINR(amount: number | undefined | null, showSymbol: boolean = true): string {
  if (amount === undefined || amount === null || isNaN(amount)) {
    return showSymbol ? '₹0.00' : '0.00';
  }

  const formatter = new Intl.NumberFormat('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

  const formatted = formatter.format(amount);
  return showSymbol ? `₹${formatted}` : formatted;
}

export function formatQty(qty: number | undefined | null): string {
  if (qty === undefined || qty === null || isNaN(qty)) return '0';
  return Number.isInteger(qty) ? `${qty}` : qty.toFixed(3);
}
