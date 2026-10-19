import React from 'react';
import { TemplateId, TemplateMetadata, TemplateProps } from '../types/template';
import { BillToShipToTemplate } from '../templates/BillToShipToTemplate';
import { ClassicTemplate } from '../templates/ClassicTemplate';
import { CompactTemplate } from '../templates/CompactTemplate';
import { ElegantTemplate } from '../templates/ElegantTemplate';
import { ElegantImagesTemplate } from '../templates/ElegantImagesTemplate';
import { EvergreenTemplate } from '../templates/EvergreenTemplate';
import { GenzTemplate } from '../templates/GenzTemplate';
import { LegendTemplate } from '../templates/LegendTemplate';
import { ModernTemplate } from '../templates/ModernTemplate';
import { MrpDiscountTemplate } from '../templates/MrpDiscountTemplate';
import { ProfessionalTemplate } from '../templates/ProfessionalTemplate';
import { ServiceTemplate } from '../templates/ServiceTemplate';
import { Service2Template } from '../templates/Service2Template';
import { VintageTemplate } from '../templates/VintageTemplate';

export const TEMPLATES: TemplateMetadata[] = [
  {
    id: 'template_billto_shipto',
    name: 'Logistics 4-Party',
    description: 'Detailed GST invoice with separate Bill From, Bill To, Ship From, and Ship To sections.',
    referenceFile: 'template_billto_shipto.jpg',
    component: BillToShipToTemplate,
    category: 'GST Tax Invoice',
  },
  {
    id: 'template_classic',
    name: 'Classic Corporate',
    description: 'Boxed invoice layout with navy header, structured customer details, and round stamp seal.',
    referenceFile: 'template_classic.jpg',
    component: ClassicTemplate,
    category: 'Classic Corporate',
  },
  {
    id: 'template_compact',
    name: 'Compact Retail',
    description: 'Compact grid receipt-inspired invoice with vertical borders and full HSN/SAC GST breakdown table.',
    referenceFile: 'template_compact.jpg',
    component: CompactTemplate,
    category: 'Retail',
  },
  {
    id: 'template_elegant',
    name: 'Elegant Minimalist',
    description: 'Clean branded invoice with solid jet black header, crisp typography, and formal signature.',
    referenceFile: 'template_elegant.jpg',
    component: ElegantTemplate,
    category: 'Classic Corporate',
  },
  {
    id: 'template_elegant_images',
    name: 'Elegant Product Visual',
    description: 'Minimalist product invoice featuring embedded product imagery thumbnails in item rows.',
    referenceFile: 'template_elegant_images.jpg',
    component: ElegantImagesTemplate,
    category: 'Classic Corporate',
  },
  {
    id: 'template_evergreen',
    name: 'Evergreen Corporate',
    description: 'Structured corporate invoice with forest green header and full 8-column GST tax breakdown.',
    referenceFile: 'template_evergreen.jpg',
    component: EvergreenTemplate,
    category: 'GST Tax Invoice',
  },
  {
    id: 'template_genz',
    name: 'Gen-Z Modern',
    description: 'Vibrant royal blue header with card containers, product photo gallery, and modern typography.',
    referenceFile: 'template_genz.jpg',
    component: GenzTemplate,
    category: 'Service & Tech',
  },
  {
    id: 'template_legend',
    name: 'Legend B2B e-Invoice',
    description: 'Official B2B e-Invoice structure with IRN, Ack No, Government e-Invoice QR and GST breakdown.',
    referenceFile: 'template_legend.jpg',
    component: LegendTemplate,
    category: 'B2B e-Invoice',
  },
  {
    id: 'template_modern',
    name: 'Modern Document',
    description: 'Amazon-style clean invoice with right-aligned seller info, 7-column table, and UPI QR code.',
    referenceFile: 'template_modern.jpg',
    component: ModernTemplate,
    category: 'GST Tax Invoice',
  },
  {
    id: 'template_mrp_discount',
    name: 'Retail MRP & Discount',
    description: 'Supermarket retail invoice with MRP, Offer Rate, Quantity, and highlighted Total Savings banner.',
    referenceFile: 'template_mrp_discount.jpg',
    component: MrpDiscountTemplate,
    category: 'Retail',
  },
  {
    id: 'template_professional',
    name: 'Professional 3-Column',
    description: 'Traditional business invoice with 3-column supplier/buyer/dispatch header and dual receiver signature.',
    referenceFile: 'template_professional.jpg',
    component: ProfessionalTemplate,
    category: 'Classic Corporate',
  },
  {
    id: 'template_service',
    name: 'Creative Agency Service',
    description: 'Vibrant hot magenta consulting layout tailored for digital agencies, deliverables, and SAC codes.',
    referenceFile: 'template_service.jpg',
    component: ServiceTemplate,
    category: 'Service & Tech',
  },
  {
    id: 'template_service_2',
    name: 'IT Consulting & Tech',
    description: 'LTIMindtree-inspired enterprise IT consulting invoice with hourly rates and client acceptance block.',
    referenceFile: 'template_service_2.jpg',
    component: Service2Template,
    category: 'Service & Tech',
  },
  {
    id: 'template_vintage',
    name: 'Vintage Industrial',
    description: 'Tata Motors-inspired heavy industries boxed grid invoice with classic blue header and full tax table.',
    referenceFile: 'template_vintage.jpg',
    component: VintageTemplate,
    category: 'Classic Corporate',
  },
];

export const templateMap = new Map<TemplateId, TemplateMetadata>(
  TEMPLATES.map((tmpl) => [tmpl.id, tmpl])
);

export function getTemplate(id: string): React.ComponentType<TemplateProps> {
  const match = templateMap.get(id as TemplateId);
  if (match) {
    return match.component;
  }
  // Safe default fallback
  return ClassicTemplate;
}
