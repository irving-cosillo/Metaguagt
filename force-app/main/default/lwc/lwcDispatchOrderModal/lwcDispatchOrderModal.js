import { LightningElement, api } from 'lwc';

export default class LwcDispatchOrderModal extends LightningElement {
    @api recordId;
    @api objectName;

    save(){
        this.template.querySelector('c-lwc-dispatch-order').save();
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}