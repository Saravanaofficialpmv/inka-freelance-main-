export interface BusinessProfileData {
  businessName: string;
  tagline?: string;
  address: string;
  phone: string;
  email: string;
  website?: string;
  logoUrl?: string;
  gstNumber?: string;
  panNumber?: string;
  taxLabel?: string;
  accountHolderName?: string;
  accountNo?: string;
  accountNumber?: string;
  ifscCode?: string;
  bankName?: string;
  branchName?: string;
  upiId?: string;
  signatureUrl?: string;
  currency?: string;
}

export interface ClientData {
  id?: string;
  name: string;
  company?: string;
  email?: string;
  phone?: string;
  address: string;
  gstin?: string;
  gstNumber?: string;
  pan?: string;
  billingAddress?: string;
  shippingAddress?: string;
  placeOfSupply?: string;
  state?: string;
  stateCode?: string;
}

export interface ShippingPartyData {
  name?: string;
  address?: string;
  phone?: string;
  city?: string;
  state?: string;
  pincode?: string;
  gstin?: string;
}

export interface InvoiceItemData {
  id: string;
  name: string;
  description?: string;
  hsnSac?: string;
  quantity: number;
  unit?: string;
  price?: number;
  rate: number;
  mrp?: number;
  sellingPrice?: number;
  discount?: number;
  taxPercentage?: number;
  taxRate?: number;
  taxAmount?: number;
  taxableValue?: number;
  taxableAmount?: number;
  cgstAmount?: number;
  sgstAmount?: number;
  igstAmount?: number;
  total: number;
  imageUrl?: string;
  imageUrls?: string[];
}

export interface GstSummaryRow {
  hsnSac: string;
  taxableValue?: number;
  taxableAmount?: number;
  cgstRate?: number;
  cgstAmount?: number;
  sgstRate?: number;
  sgstAmount?: number;
  igstRate?: number;
  igstAmount?: number;
  totalTaxAmount?: number;
  totalTax?: number;
}

export interface InvoicePayload {
  version?: string;
  templateId: string;
  invoiceNumber: string;
  issueDate: string;
  dueDate: string;
  status?: string;
  notes?: string;
  terms?: string;
  termsAndConditions?: string[];
  placeOfSupply?: string;
  stateCode?: string;
  dispatchFrom?: string;
  shipFrom?: ShippingPartyData;
  shipTo?: ShippingPartyData;
  ewayBillNumber?: string;
  vehicleNumber?: string;
  irn?: string;
  ackNumber?: string;
  client: ClientData;
  profile: BusinessProfileData;
  items: InvoiceItemData[];
  subtotal: number;
  discount: number;
  discountAmount?: number;
  taxPercentage: number;
  taxAmount: number;
  taxableAmount?: number;
  cgstAmount?: number;
  sgstAmount?: number;
  igstAmount?: number;
  deliveryCharges?: number;
  packagingCharges?: number;
  serviceCharges?: number;
  serviceSac?: string;
  roundOff?: number;
  total: number;
  totalAmount: number;
  amountPaid?: number;
  amountPayable?: number;
  isPaid?: boolean;
  paidDate?: string;
  paymentMode?: string;
  totalItemsCount?: number;
  totalQuantity?: number;
  gstBreakdown?: GstSummaryRow[];
  upiQrData?: string;
  eInvoiceQrData?: string;
  amountInWords?: string;
  totalInWords?: string;
}
