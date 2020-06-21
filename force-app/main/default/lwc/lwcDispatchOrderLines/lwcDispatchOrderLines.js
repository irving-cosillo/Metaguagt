import { LightningElement, api } from 'lwc';
import getDispatchOrderLines from '@salesforce/apex/ClassDispatchOrder.getDispatchOrderLines';

export default class LwcDispatchOrderLines extends LightningElement {
    @api recordId;

    data;
    columns = [
        {label: 'Código', fieldName: 'Product_Name__c', type: 'text', initialWidth: 100},
        {label: 'Descripción', fieldName: 'Product_Description__c', type: 'text', wrapText : true},
        {label: 'Cantidad', fieldName: 'Quantity__c', type: 'number'},
        {label: 'Stock', fieldName: 'Stock__c', type: 'number'},
    ];

    connectedCallback(){
        getDispatchOrderLines({dispatchOrderId : this.recordId}).then( response => {
            this.data = response;
        })
    }
}