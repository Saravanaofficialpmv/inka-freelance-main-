const units = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

function convertBelowThousand(n: number): string {
  if (n === 0) return '';
  if (n < 20) return units[n];
  if (n < 100) {
    const unitPart = n % 10 !== 0 ? `-${units[n % 10]}` : '';
    return `${tens[Math.floor(n / 10)]}${unitPart}`;
  }
  const rem = n % 100;
  const remStr = rem !== 0 ? ` And ${convertBelowThousand(rem)}` : '';
  return `${units[Math.floor(n / 100)]} Hundred${remStr}`;
}

/**
 * Converts integer numbers into Indian words (Crores, Lakhs, Thousands).
 * e.g. 38994 -> "INR Thirty-Eight Thousand, Nine Hundred And Ninety-Four Rupees Only."
 */
export function convertToIndianWords(amount: number | undefined | null): string {
  if (amount === undefined || amount === null || isNaN(amount) || amount === 0) {
    return 'INR Zero Rupees Only.';
  }

  const integerPart = Math.floor(Math.abs(amount));
  const decimalPart = Math.round((Math.abs(amount) - integerPart) * 100);

  let remaining = integerPart;
  const parts: string[] = [];

  // Crores (1,00,00,000)
  if (remaining >= 10000000) {
    const cr = Math.floor(remaining / 10000000);
    parts.push(`${convertBelowThousand(cr)} Crore`);
    remaining %= 10000000;
  }

  // Lakhs (1,00,000)
  if (remaining >= 100000) {
    const lk = Math.floor(remaining / 100000);
    parts.push(`${convertBelowThousand(lk)} Lakh`);
    remaining %= 100000;
  }

  // Thousands (1,000)
  if (remaining >= 1000) {
    const th = Math.floor(remaining / 1000);
    parts.push(`${convertBelowThousand(th)} Thousand`);
    remaining %= 1000;
  }

  // Hundreds & below
  if (remaining > 0) {
    parts.push(convertBelowThousand(remaining));
  }

  let result = `INR ${parts.join(', ')} Rupees`;
  if (decimalPart > 0) {
    result += ` And ${convertBelowThousand(decimalPart)} Paise`;
  }
  result += ' Only.';

  return result;
}
