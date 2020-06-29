import { LightningElement, api } from 'lwc';

export default class LwcInvoiceModal extends LightningElement {
    @api recordId;
    @api objectName;

    save(){
        this.template.querySelector('c-lwc-invoice').save();
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}