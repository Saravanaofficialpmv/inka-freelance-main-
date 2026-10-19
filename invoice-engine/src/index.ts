import { renderInvoiceToHtml } from './print/renderToHtml';
import { TEMPLATES, getTemplate } from './registry/templateRegistry';
import { InvoicePayload } from './types/invoice';
import { TemplateId } from './types/template';

export * from './types/invoice';
export * from './types/template';
export * from './registry/templateRegistry';
export * from './print/renderToHtml';

// Bridge for browser, WebView, or headless execution
declare global {
  interface Window {
    InkaInvoiceEngine?: {
      renderToHtml: (templateId: string, data: InvoicePayload) => string;
      getTemplates: () => typeof TEMPLATES;
    };
  }
}

if (typeof window !== 'undefined') {
  window.InkaInvoiceEngine = {
    renderToHtml: renderInvoiceToHtml,
    getTemplates: () => TEMPLATES,
  };
}
