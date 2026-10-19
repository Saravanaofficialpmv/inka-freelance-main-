import React from 'react';
import { InvoicePayload } from './invoice';

export type TemplateId =
  | 'template_billto_shipto'
  | 'template_classic'
  | 'template_compact'
  | 'template_elegant'
  | 'template_elegant_images'
  | 'template_evergreen'
  | 'template_genz'
  | 'template_legend'
  | 'template_modern'
  | 'template_mrp_discount'
  | 'template_professional'
  | 'template_service'
  | 'template_service_2'
  | 'template_vintage';

export interface TemplateProps {
  data: InvoicePayload;
}

export interface TemplateMetadata {
  id: TemplateId;
  name: string;
  description: string;
  referenceFile: string;
  component: React.ComponentType<TemplateProps>;
  category: 'GST Tax Invoice' | 'Retail' | 'B2B e-Invoice' | 'Service & Tech' | 'Classic Corporate';
}
