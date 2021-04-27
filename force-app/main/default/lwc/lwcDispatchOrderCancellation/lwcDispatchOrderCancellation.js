import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cancelDispatchOrder from '@salesforce/apex/ClassDispatchOrder.cancelDispatchOrder';

export default class LwcDispatchOrderCancellation extends LightningElement {
    @api recordId;

    cancellationReason = '';
    isLoading = false;

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    save(){
        this.isLoading = true;
        cancelDispatchOrder({ dispatchOrderId: this.recordId}).then( () => {
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'La factura fue anulada con éxito',
                variant: 'success'
            }));
        }).catch( error => {
            error = error && error.body && error.body.message ? error.body.message : error;
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: error,
                variant: 'error'
            }));
        }).finally(() => {
            this.isLoading = false;
            this.cancel();
        });
    }
}