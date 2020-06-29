import { LightningElement, api } from 'lwc';

export default class LwcInvoiceContainer extends LightningElement {
    @api recordId;
    @api objectName;

    purchaseOrderId;

    POChanged(event){
        this.purchaseOrderId = event.target.value;
    }

    save(){
        this.template.querySelector('c-lwc-invoice').save();
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}