import { LightningElement, api } from 'lwc';

export default class LwcBatchInput extends LightningElement {
    changeCommunField(event){
        this.dispatchEvent( 
            new CustomEvent("changecommunfield", {
                detail : {
                    fieldName : event.target.fieldName,
                    value : event.target.value
                }
            })
        );
    }

    @api clear(){
        let inputs = this.template.querySelectorAll('lightning-input-field');
        inputs.forEach(input => {
            input.value = '';
        });
    }
}