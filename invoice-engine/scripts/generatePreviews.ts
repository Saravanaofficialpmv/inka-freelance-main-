import { renderInvoiceToHtml } from '../src/print/renderToHtml.ts';
import { TEMPLATES } from '../src/registry/templateRegistry.ts';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const BRAVE_PATH = '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser';
const ROOT_DIR = process.cwd();
const OUTPUT_DIR = path.resolve(ROOT_DIR, 'assets/templates');
const TEMP_DIR = path.resolve(ROOT_DIR, 'temp_previews');

if (!fs.existsSync(TEMP_DIR)) {
  fs.mkdirSync(TEMP_DIR, { recursive: true });
}

// ── Realistic Data Profiles per Template Design Specification ──
const BASE_PROFILE = {
  businessName: 'Inka Technologies Pvt Ltd',
  tagline: 'Enterprise Billing & Logistics Solutions',
  address: 'Plot No. 42, Bandra Kurla Complex, Bandra East, Mumbai, Maharashtra 400051',
  phone: '+91 98765 43210',
  email: 'billing@inka.app',
  gstNumber: '27AAACI1234A1Z5',
  panNumber: 'AAACI1234A',
  taxLabel: 'GSTIN',
  bankName: 'HDFC Bank Ltd',
  accountNumber: '50200012345678',
  ifscCode: 'HDFC0000042',
  branchName: 'BKC Executive Branch',
  upiId: 'inka.technologies@hdfcbank',
  currency: 'INR',
  signatureUrl: '',
  logoUrl: '',
};

const BASE_CLIENT = {
  name: 'Apex Global Logistics Pvt Ltd',
  company: 'Apex Retail Division',
  address: 'Warehouse #7, Industrial Area, Phase II, Pune, Maharashtra 411019',
  phone: '+91 91234 56789',
  email: 'procurement@apexlogistics.in',
  gstNumber: '27AABCA5678B1Z2',
  shippingAddress: 'Central Hub Pune, Plot 14, Hinjewadi Phase 1, Pune 411057',
};

function getInvoiceDataForTemplate(templateId: string) {
  switch (templateId) {
    case 'template_billto_shipto':
      return {
        templateId,
        invoiceNumber: 'INV-2024-LOG-0014',
        issueDate: '19/10/2024',
        dueDate: '03/11/2024',
        placeOfSupply: '27-Maharashtra',
        stateCode: '27',
        ewayBillNumber: '841029485712',
        profile: {
          ...BASE_PROFILE,
          businessName: 'INKA LOGISTICS PVT LTD',
          tagline: 'Freight & Supply Chain Networks',
        },
        client: BASE_CLIENT,
        shipTo: {
          name: 'Apex Distribution Center Pune',
          address: 'Plot 14, Hinjewadi Phase 1, Pune 411057',
          gstin: '27AABCA5678B1Z2',
          state: 'Maharashtra',
        },
        items: [
          { id: '1', name: 'Industrial Barcode Scanner X-200', hsnSac: '847190', quantity: 5, rate: 8500, taxRate: 18, taxableAmount: 42500, cgstAmount: 3825, sgstAmount: 3825, total: 50150 },
          { id: '2', name: 'Thermal Receipt Rolls (80mm x 50m)', hsnSac: '481190', quantity: 10, rate: 1200, taxRate: 12, taxableAmount: 12000, cgstAmount: 720, sgstAmount: 720, total: 13440 },
          { id: '3', name: 'Cloud POS Integration & Onboarding', hsnSac: '998314', quantity: 1, rate: 15000, taxRate: 18, taxableAmount: 15000, cgstAmount: 1350, sgstAmount: 1350, total: 17700 },
        ],
        subtotal: 69500,
        discount: 2000,
        taxPercentage: 18,
        taxableAmount: 67500,
        cgstAmount: 5895,
        sgstAmount: 5895,
        igstAmount: 0,
        taxAmount: 11790,
        total: 79290,
        totalAmount: 79290,
        totalInWords: 'INR Seventy-Nine Thousand Two Hundred Ninety Rupees Only',
        notes: 'Goods received in good order. Subject to Mumbai Jurisdiction.',
        terms: 'Payment due within 15 days of invoice date. 18% p.a. interest applicable on overdue amounts.',
      };

    case 'template_classic':
      return {
        templateId,
        invoiceNumber: 'CORP-2024-9912',
        issueDate: '19/10/2024',
        dueDate: '02/11/2024',
        placeOfSupply: '27-Maharashtra',
        profile: {
          ...BASE_PROFILE,
          businessName: 'INKA CORPORATION',
          tagline: 'Enterprise Technology & Infrastructure',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Reliance Digital Systems Ltd',
          company: 'Reliance Enterprise Division',
          address: 'Reliance Corporate Park, Thane-Belapur Road, Navi Mumbai 400701',
        },
        items: [
          { id: '1', name: '4K Commercial Display Panel 55"', hsnSac: '852852', quantity: 2, rate: 45000, taxRate: 18, taxableAmount: 90000, cgstAmount: 8100, sgstAmount: 8100, total: 106200 },
          { id: '2', name: 'Heavy Duty Articulated Wall Bracket', hsnSac: '830249', quantity: 2, rate: 2500, taxRate: 18, taxableAmount: 5000, cgstAmount: 450, sgstAmount: 450, total: 5900 },
          { id: '3', name: 'On-Site Enterprise Mounting & Calibration', hsnSac: '998713', quantity: 1, rate: 5000, taxRate: 18, taxableAmount: 5000, cgstAmount: 450, sgstAmount: 450, total: 5900 },
        ],
        subtotal: 100000,
        taxAmount: 18000,
        cgstAmount: 9000,
        sgstAmount: 9000,
        total: 118000,
        totalAmount: 118000,
        totalInWords: 'INR One Lakh Eighteen Thousand Rupees Only',
        notes: 'Includes 3-year enterprise warranty and 24/7 priority support.',
        terms: 'All payments to be made in favor of Inka Corporation.',
      };

    case 'template_compact':
      return {
        templateId,
        invoiceNumber: 'RCPT-88214',
        issueDate: '19/10/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'SUPER MART RETAIL STORES',
          address: 'Shop 12-14, Linking Road, Bandra West, Mumbai 400050',
          phone: '+91 22 2640 1234',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Walk-In Customer (Cash/UPI)',
          phone: '+91 98201 55555',
          address: 'Bandra West, Mumbai 400050',
        },
        items: [
          { id: '1', name: 'Organic Royal Basmati Rice 5kg', hsnSac: '1006', quantity: 2, rate: 650, mrp: 750, taxRate: 5, taxableAmount: 1300, total: 1365 },
          { id: '2', name: 'Cold Pressed Virgin Mustard Oil 1L', hsnSac: '1515', quantity: 3, rate: 280, mrp: 340, taxRate: 5, taxableAmount: 840, total: 882 },
          { id: '3', name: 'Monsooned Malabar Arabica 500g', hsnSac: '0901', quantity: 1, rate: 450, mrp: 520, taxRate: 5, taxableAmount: 450, total: 472.5 },
        ],
        subtotal: 2590,
        discount: 320,
        taxAmount: 136.25,
        cgstAmount: 68.12,
        sgstAmount: 68.13,
        total: 2726,
        totalAmount: 2726,
        totalInWords: 'INR Two Thousand Seven Hundred Twenty-Six Rupees Only',
        notes: 'Thank you for shopping at Super Mart! Visit again.',
        terms: 'Return within 7 days with original receipt.',
      };

    case 'template_elegant':
      return {
        templateId,
        invoiceNumber: 'NK-2024-90214',
        issueDate: '19/10/2024',
        dueDate: '26/10/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'NIKE ATHLETICS INDIA',
          tagline: 'Performance Footwear & Sportswear',
          address: 'DLF Cyber City, Tower 10, Building B, Gurugram, Haryana 122002',
          gstNumber: '06AABCN1234D1Z9',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Rahul Deshmukh',
          phone: '+91 98201 12345',
          address: 'Flat 402, Sea Green Apartments, Bandra West, Mumbai 400050',
          shippingAddress: 'Flat 402, Sea Green Apartments, Bandra West, Mumbai 400050',
        },
        items: [
          { id: '1', name: 'Air Zoom Pegasus 40 Running Shoes', hsnSac: '640411', quantity: 1, rate: 11895, taxRate: 18, taxableAmount: 11895, total: 14036.1 },
          { id: '2', name: 'Dri-FIT Breathe Training Tee (Black)', hsnSac: '610910', quantity: 2, rate: 2495, taxRate: 12, taxableAmount: 4990, total: 5588.8 },
          { id: '3', name: 'Pro Elite Compression Running Shorts', hsnSac: '610463', quantity: 1, rate: 3295, taxRate: 12, taxableAmount: 3295, total: 3690.4 },
        ],
        subtotal: 20180,
        taxAmount: 3130.3,
        total: 23315,
        totalAmount: 23315,
        totalInWords: 'INR Twenty-Three Thousand Three Hundred Fifteen Rupees Only',
        notes: '30-day hassle free exchange at any official Nike retail store.',
        terms: 'Original tax invoice required for warranty or replacement.',
      };

    case 'template_elegant_images':
      return {
        templateId,
        invoiceNumber: 'LFS-2024-4412',
        issueDate: '19/10/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'LIFESTYLE STUDIOS PVT LTD',
          tagline: 'High-Fidelity Audio & Premium Tech Accessories',
        },
        client: BASE_CLIENT,
        items: [
          { id: '1', name: 'Air-Max Pro Wireless Headphones (Midnight)', hsnSac: '851830', quantity: 1, rate: 14995, taxRate: 18, taxableAmount: 14995, total: 17694.1 },
          { id: '2', name: 'Tech Weatherproof Commuter Windrunner', hsnSac: '620193', quantity: 1, rate: 8495, taxRate: 12, taxableAmount: 8495, total: 9514.4 },
          { id: '3', name: 'Modular Travel Backpack 30L Waterproof', hsnSac: '420292', quantity: 1, rate: 4295, taxRate: 18, taxableAmount: 4295, total: 5068.1 },
        ],
        subtotal: 27785,
        taxAmount: 4491.6,
        total: 32276.6,
        totalAmount: 32276.6,
        totalInWords: 'INR Thirty-Two Thousand Two Hundred Seventy-Six Rupees Only',
        notes: 'Serial numbers registered for standard 2-year warranty.',
        terms: 'Goods once sold subject to replacement policy.',
      };

    case 'template_evergreen':
      return {
        templateId,
        invoiceNumber: 'HUL/2024/0912',
        issueDate: '19/10/2024',
        dueDate: '03/11/2024',
        placeOfSupply: '27-Maharashtra',
        profile: {
          ...BASE_PROFILE,
          businessName: 'HINDUSTAN UNILEVER LIMITED',
          tagline: 'FMCG Distribution & Institutional Sales',
          address: 'Unilever House, B.D. Sawant Marg, Chakala, Andheri East, Mumbai 400099',
          gstNumber: '27AAACH1234F1Z0',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Metro Mega Distribution Hub',
          address: 'Plot 18, MIDC Industrial Area, Turbhe, Navi Mumbai 400705',
          gstNumber: '27AABCM8812K1Z6',
        },
        items: [
          { id: '1', name: 'Dove Daily Moisture Shampoo 650ml (Case of 24)', hsnSac: '330510', quantity: 24, rate: 450, taxRate: 18, taxableAmount: 10800, cgstAmount: 972, sgstAmount: 972, total: 12744 },
          { id: '2', name: 'Lifebuoy Total Germ Protection 5L Jar', hsnSac: '340120', quantity: 10, rate: 750, taxRate: 18, taxableAmount: 7500, cgstAmount: 675, sgstAmount: 675, total: 8850 },
          { id: '3', name: 'Surf Excel Matic Front Load Liquid 4L', hsnSac: '340220', quantity: 8, rate: 850, taxRate: 18, taxableAmount: 6800, cgstAmount: 612, sgstAmount: 612, total: 8024 },
        ],
        subtotal: 25100,
        cgstAmount: 2259,
        sgstAmount: 2259,
        taxAmount: 4518,
        total: 29618,
        totalAmount: 29618,
        totalInWords: 'INR Twenty-Nine Thousand Six Hundred Eighteen Rupees Only',
        notes: 'Statutory declaration: Contents verified and certified true.',
        terms: 'Subject to Greater Mumbai jurisdiction. Net 15 days credit terms.',
      };

    case 'template_genz':
      return {
        templateId,
        invoiceNumber: 'GZ-2024-8841',
        issueDate: '19/10/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'STUDIO GEN-Z MEDIA',
          tagline: 'Modern Audio & Lifestyle Gear',
          address: 'Creator Loft 4B, Indiranagar 100ft Road, Bengaluru, Karnataka 560038',
          gstNumber: '29AAACG9912Z1Z1',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Aarav Mehta',
          phone: '+91 99887 66554',
          address: 'Koramangala 4th Block, Bengaluru 560034',
        },
        items: [
          { id: '1', name: 'Wireless Studio ANC Headphones', hsnSac: '851830', quantity: 1, rate: 9999, taxRate: 18, taxableAmount: 9999, total: 11798.8 },
          { id: '2', name: 'Smart Fitness Band AMOLED Pro', hsnSac: '851762', quantity: 2, rate: 4499, taxRate: 18, taxableAmount: 8998, total: 10617.6 },
        ],
        subtotal: 18997,
        taxAmount: 3419.46,
        total: 22416.46,
        totalAmount: 22416.46,
        totalInWords: 'INR Twenty-Two Thousand Four Hundred Sixteen Rupees Only',
        notes: 'Drop your unboxing on IG and tag @StudioGenZ to get 10% off your next order!',
        terms: '1 year replacement warranty.',
      };

    case 'template_legend':
      return {
        templateId,
        invoiceNumber: 'ITC/B2B/2024/771',
        issueDate: '19/10/2024',
        dueDate: '02/11/2024',
        placeOfSupply: '19-West Bengal',
        notes: 'IRN: 4a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        profile: {
          ...BASE_PROFILE,
          businessName: 'ITC LIMITED - FOODS DIVISION',
          tagline: 'B2B Enterprise Distribution',
          address: 'Virginia House, 37 J.L. Nehru Road, Kolkata, West Bengal 700071',
          gstNumber: '19AAACI1234G1Z2',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Metro Cash & Carry India Pvt Ltd',
          address: 'Survey 26/3, Industrial Area, Yeshwanthpur, Bengaluru 560022',
          gstNumber: '29AABCM1234L1Z9',
        },
        items: [
          { id: '1', name: 'Aashirvaad Superior MP Sharbati Atta 10kg', hsnSac: '110100', quantity: 50, rate: 420, taxRate: 5, taxableAmount: 21000, cgstAmount: 525, sgstAmount: 525, total: 22050 },
          { id: '2', name: 'Sunfeast Dark Fantasy Choco Fills 300g (Pack of 24)', hsnSac: '190531', quantity: 100, rate: 120, taxRate: 18, taxableAmount: 12000, cgstAmount: 1080, sgstAmount: 1080, total: 14160 },
        ],
        subtotal: 33000,
        cgstAmount: 1605,
        sgstAmount: 1605,
        taxAmount: 3210,
        total: 36210,
        totalAmount: 36210,
        totalInWords: 'INR Thirty-Six Thousand Two Hundred Ten Rupees Only',
        terms: 'Authorized e-Invoice registered with NIC portal.',
      };

    case 'template_modern':
      return {
        templateId,
        invoiceNumber: 'INV-AMZ-99214',
        issueDate: '19/10/2024',
        dueDate: '02/11/2024',
        placeOfSupply: '27-Maharashtra',
        profile: {
          ...BASE_PROFILE,
          businessName: 'CLOUDTAIL INDIA PVT LTD',
          tagline: 'Authorized Retail Partner',
          address: 'Building 4, Mindspace IT Park, Airoli, Navi Mumbai 400708',
          gstNumber: '27AAACC4321H1Z4',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Vikramaditya Rao',
          phone: '+91 98200 99887',
          address: 'Flat 12B, Hiranandani Gardens, Powai, Mumbai 400076',
          shippingAddress: 'Flat 12B, Hiranandani Gardens, Powai, Mumbai 400076',
        },
        items: [
          { id: '1', name: 'Echo Dot 5th Gen with Clock & Alexa (Deep Blue)', hsnSac: '851821', quantity: 1, rate: 4499, taxRate: 18, taxableAmount: 4499, cgstAmount: 404.91, sgstAmount: 404.91, total: 5308.82 },
          { id: '2', name: 'Fire TV Stick 4K Max with Wi-Fi 6 Support', hsnSac: '852871', quantity: 1, rate: 5999, taxRate: 18, taxableAmount: 5999, cgstAmount: 539.91, sgstAmount: 539.91, total: 7078.82 },
          { id: '3', name: 'Kindle Paperwhite 16GB with 6.8" Display', hsnSac: '847130', quantity: 1, rate: 13999, taxRate: 18, taxableAmount: 13999, cgstAmount: 1259.91, sgstAmount: 1259.91, total: 16518.82 },
        ],
        subtotal: 24497,
        cgstAmount: 2204.73,
        sgstAmount: 2204.73,
        taxAmount: 4409.46,
        total: 28906.46,
        totalAmount: 28906.46,
        totalInWords: 'INR Twenty-Eight Thousand Nine Hundred Six Rupees Only',
        notes: 'Thank you for shopping on Amazon.in.',
        terms: 'All disputes subject to Mumbai jurisdiction.',
      };

    case 'template_mrp_discount':
      return {
        templateId,
        invoiceNumber: 'DMRT-POS-0914',
        issueDate: '19/10/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'SUPER DISCOUNT MART LTD',
          tagline: 'Best Value Supermarket',
          address: 'Plot 12, Link Road, Goregaon West, Mumbai 400104',
          gstNumber: '27AABCD3456K1Z9',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Pooja Sharma (Member ID: DM-8812)',
          phone: '+91 98199 44332',
          address: 'Goregaon West, Mumbai 400104',
        },
        items: [
          { id: '1', name: 'Cadbury Bournvita Nutrition Jar 1kg', hsnSac: '180690', quantity: 2, mrp: 450, rate: 380, taxRate: 18, taxableAmount: 760, total: 896.8 },
          { id: '2', name: 'Fortune Sunlite Refined Sunflower Oil 5L', hsnSac: '151219', quantity: 1, mrp: 890, rate: 720, taxRate: 5, taxableAmount: 720, total: 756 },
          { id: '3', name: 'India Gate Classic Basmati Rice 5kg', hsnSac: '100630', quantity: 2, mrp: 600, rate: 480, taxRate: 5, taxableAmount: 960, total: 1008 },
        ],
        subtotal: 2440,
        discount: 550,
        taxAmount: 220.8,
        total: 2660.8,
        totalAmount: 2660.8,
        totalInWords: 'INR Two Thousand Six Hundred Sixty Rupees Only',
        notes: 'YOU SAVED ₹550.00 ON THIS TRANSACTION! 🎉',
        terms: 'Goods exchange within 15 days with original bill.',
      };

    case 'template_professional':
      return {
        templateId,
        invoiceNumber: 'MCC-COMM-8812',
        issueDate: '19/10/2024',
        dueDate: '02/11/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'MARICO COMMERCIAL CORP',
          tagline: 'Consumer Goods & Edible Oils Division',
          address: 'Grande Palladium, 7th Floor, 175 CST Road, Kalina, Mumbai 400098',
          gstNumber: '27AAACM1234L1Z7',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Prime Retailers Private Limited',
          address: 'Shop 101, Central Commercial Complex, Thane West 400601',
          gstNumber: '27AABCP5678M1Z8',
        },
        items: [
          { id: '1', name: 'Parachute Pure Coconut Oil 500ml (Carton 48)', hsnSac: '151311', quantity: 48, rate: 185, taxRate: 5, taxableAmount: 8880, cgstAmount: 222, sgstAmount: 222, total: 9324 },
          { id: '2', name: 'Saffola Gold Pro Healthy Blend Oil 5L Jar', hsnSac: '151790', quantity: 12, rate: 920, taxRate: 5, taxableAmount: 11040, cgstAmount: 276, sgstAmount: 276, total: 11592 },
        ],
        subtotal: 19920,
        cgstAmount: 498,
        sgstAmount: 498,
        taxAmount: 996,
        total: 20916,
        totalAmount: 20916,
        totalInWords: 'INR Twenty Thousand Nine Hundred Sixteen Rupees Only',
        notes: 'Dispatch via MH-04-AB-1234. Driver: Suresh Mane.',
        terms: 'Certified that particulars given above are true and correct.',
      };

    case 'template_service':
      return {
        templateId,
        invoiceNumber: 'PX-AGY-2024-091',
        issueDate: '19/10/2024',
        dueDate: '03/11/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'PIXEL & POST CREATIVE AGENCY',
          tagline: 'Digital Strategy, Performance Marketing & Production',
          address: 'Design Villa, Off Khar Danda Road, Khar West, Mumbai 400052',
          gstNumber: '27AAACP9012N1Z4',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Urban Lifestyle Brands India',
          address: 'Floor 5, High Street Phoenix, Lower Parel, Mumbai 400013',
          gstNumber: '27AABCU1234D1Z2',
        },
        items: [
          { id: '1', name: 'Brand Strategy & Campaign Direction (Phase 1)', hsnSac: '998311', quantity: 1, rate: 45000, taxRate: 18, taxableAmount: 45000, cgstAmount: 4050, sgstAmount: 4050, total: 53100 },
          { id: '2', name: 'Short-Form Reels Production (Set of 8 High-Res)', hsnSac: '998311', quantity: 8, rate: 8000, taxRate: 18, taxableAmount: 64000, cgstAmount: 5760, sgstAmount: 5760, total: 75520 },
          { id: '3', name: 'Monthly Performance Marketing Management & ROAS Audit', hsnSac: '998311', quantity: 1, rate: 25000, taxRate: 18, taxableAmount: 25000, cgstAmount: 2250, sgstAmount: 2250, total: 29500 },
        ],
        subtotal: 134000,
        cgstAmount: 12060,
        sgstAmount: 12060,
        taxAmount: 24120,
        total: 158120,
        totalAmount: 158120,
        totalInWords: 'INR One Lakh Fifty-Eight Thousand One Hundred Twenty Rupees Only',
        notes: 'Project deliverable acceptance confirmed by Urban Lifestyle marketing team.',
        terms: 'Payment due within 15 days of invoice date.',
      };

    case 'template_service_2':
      return {
        templateId,
        invoiceNumber: 'CTC-IT-2024-0412',
        issueDate: '19/10/2024',
        dueDate: '03/11/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'COGNIZANT TECH CONSULTING',
          tagline: 'Enterprise Cloud Architecture & Cybersecurity',
          address: 'Cognizant Campus, Hinjewadi Phase 2, Pune, Maharashtra 411057',
          gstNumber: '27AABCC8812N1Z3',
        },
        client: {
          ...BASE_CLIENT,
          name: 'FinTech Horizon Solutions Pvt Ltd',
          address: 'Tech Park Tower 3, Whitefield, Bengaluru 560066',
          gstNumber: '29AABCF9912K1Z5',
        },
        items: [
          { id: '1', name: 'Enterprise Cloud Migration Sprint 3 Deliverable', hsnSac: '998314', quantity: 40, unit: 'hrs', rate: 2500, taxRate: 18, taxableAmount: 100000, cgstAmount: 9000, sgstAmount: 9000, total: 118000 },
          { id: '2', name: 'Microservices API Development & Load Testing', hsnSac: '998314', quantity: 32, unit: 'hrs', rate: 2500, taxRate: 18, taxableAmount: 80000, cgstAmount: 7200, sgstAmount: 7200, total: 94400 },
          { id: '3', name: 'SOC2 & ISO 27001 Security Audit Review', hsnSac: '998314', quantity: 10, unit: 'hrs', rate: 3000, taxRate: 18, taxableAmount: 30000, cgstAmount: 2700, sgstAmount: 2700, total: 35400 },
        ],
        subtotal: 210000,
        cgstAmount: 18900,
        sgstAmount: 18900,
        taxAmount: 37800,
        total: 247800,
        totalAmount: 247800,
        totalInWords: 'INR Two Lakh Forty-Seven Thousand Eight Hundred Rupees Only',
        notes: 'Timesheet signed and approved by client project manager.',
        terms: 'Net 15 days credit terms.',
      };

    case 'template_vintage':
      return {
        templateId,
        invoiceNumber: 'TM/ENG/2024/0912',
        issueDate: '19/10/2024',
        dueDate: '02/11/2024',
        profile: {
          ...BASE_PROFILE,
          businessName: 'TATA MOTORS INDUSTRIAL DIVISION',
          tagline: 'Heavy Commercial Vehicle & Powertrain Engineering',
          address: 'Bombay House, 24 Homi Mody Street, Fort, Mumbai, Maharashtra 400001',
          gstNumber: '27AAACT1234P1Z4',
        },
        client: {
          ...BASE_CLIENT,
          name: 'Bharat Heavy Engineering Logistics',
          address: 'MIDC Chakan Industrial Area, Phase 3, Pune 410501',
          gstNumber: '27AABCB9012F1Z8',
        },
        items: [
          { id: '1', name: 'Heavy Duty Forged Axle Assembly 16T Heavy Commercial', hsnSac: '870850', quantity: 2, rate: 85000, taxRate: 18, taxableAmount: 170000, cgstAmount: 15300, sgstAmount: 15300, total: 200600 },
          { id: '2', name: 'Pneumatic Brake Kit System Pro (Dual Circuit)', hsnSac: '870830', quantity: 4, rate: 18500, taxRate: 18, taxableAmount: 74000, cgstAmount: 6660, sgstAmount: 6660, total: 87320 },
        ],
        subtotal: 244000,
        cgstAmount: 21960,
        sgstAmount: 21960,
        taxAmount: 43920,
        total: 287920,
        totalAmount: 287920,
        totalInWords: 'INR Two Lakh Eighty-Seven Thousand Nine Hundred Twenty Rupees Only',
        notes: 'Statutory declaration: Certified true and correct under GST Act 2017.',
        terms: 'Subject to Mumbai jurisdiction.',
      };

    default:
      return {
        templateId,
        invoiceNumber: 'INV-2024-001',
        issueDate: '19/10/2024',
        profile: BASE_PROFILE,
        client: BASE_CLIENT,
        items: [
          { id: '1', name: 'Professional Services Consulting', hsnSac: '998311', quantity: 1, rate: 50000, taxRate: 18, taxableAmount: 50000, total: 59000 },
        ],
        subtotal: 50000,
        taxAmount: 9000,
        total: 59000,
        totalAmount: 59000,
        totalInWords: 'INR Fifty-Nine Thousand Rupees Only',
      };
  }
}

async function main() {
  console.log('Rendering 14 high-resolution, pixel-perfect invoice template images...');

  for (const tmpl of TEMPLATES) {
    const data = getInvoiceDataForTemplate(tmpl.id);
    const html = renderInvoiceToHtml(tmpl.id, data);
    const tempHtmlPath = path.join(TEMP_DIR, `${tmpl.id}.html`);
    const tempPngPath = path.join(TEMP_DIR, `${tmpl.id}.png`);
    const finalJpgPath = path.join(OUTPUT_DIR, `${tmpl.id}.jpg`);

    fs.writeFileSync(tempHtmlPath, html, 'utf-8');

    // Screenshot with Brave Headless at 1200x1697 (A4 ratio high-DPI)
    const braveCmd = `"${BRAVE_PATH}" --headless --screenshot="${tempPngPath}" --window-size=1200,1697 --hide-scrollbars "${tempHtmlPath}"`;
    try {
      execSync(braveCmd, { stdio: 'pipe' });
      // Convert to 95% quality JPEG
      const sipsCmd = `sips -s format jpeg -s formatOptions 95 "${tempPngPath}" --out "${finalJpgPath}"`;
      execSync(sipsCmd, { stdio: 'pipe' });

      const stats = fs.statSync(finalJpgPath);
      console.log(`✓ ${tmpl.id}: Generated high-res preview (${(stats.size / 1024).toFixed(1)} KB)`);
    } catch (err: any) {
      console.error(`Error generating ${tmpl.id}:`, err?.message || err);
    }
  }

  // Cleanup temp files
  fs.rmSync(TEMP_DIR, { recursive: true, force: true });
  console.log('All 14 high-resolution template previews generated successfully!');
}

main();
