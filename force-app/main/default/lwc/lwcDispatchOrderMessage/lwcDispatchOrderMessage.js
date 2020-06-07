import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import dispatchOrder from '@salesforce/apex/ClassDispatchOrder.dispatchOrder';

export default class LwcDispatchOrderMessage extends LightningElement {
    @api recordId;

    save(){
        dispatchOrder({dispatchOrderId : this.recordId}).then(() => {
            this.dispatchEvent( new ShowToastEvent({
                title: '',
                message: 'La orden fue despachada con éxito.',
                variant: 'success'
            }));
        }).catch(() => {
            this.dispatchEvent( new ShowToastEvent({
                title: '',
                message: 'Error: Por favor contactar al administrador del sistema.',
                variant: 'error'
            }));
        })
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}