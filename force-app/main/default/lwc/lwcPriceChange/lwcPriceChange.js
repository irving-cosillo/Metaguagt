import { LightningElement, api } from 'lwc';

export default class LwcPriceChange extends LightningElement {
    @api recordId;
    
    success(){
        this.dispatchEvent(new CustomEvent('success'));
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}