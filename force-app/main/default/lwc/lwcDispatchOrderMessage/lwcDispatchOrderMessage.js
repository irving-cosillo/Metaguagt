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
        }).catch( error => {
            this.dispatchEvent( new ShowToastEvent({
                title: '',
                message: 'Error: ' + error.body.message,
                variant: 'error'
            }));
        }).finally(()=>{
            this.cancel();
        })
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}