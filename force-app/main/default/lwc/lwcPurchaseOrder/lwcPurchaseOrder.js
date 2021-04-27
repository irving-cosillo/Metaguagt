import { LightningElement, api } from 'lwc';
import getPurchaseOrderLines from '@salesforce/apex/ClassPurchaseOrder.getPurchaseOrderLines';

export default class LwcPurchaseOrder extends LightningElement {
    @api recordId;
    
    data;
    columns = [
        {label: 'Código', fieldName: 'Product__c', type: 'text', initialWidth: 100},
        {label: 'Descripción', fieldName: 'Product_Name__c', type: 'text', wrapText : true},
        {label: 'Tiempo de Entrega', fieldName: 'Delivery_Time__c', type: 'text'},
        {label: 'C. Pedida', fieldName: 'Quantity__c', type: 'number'},
        {label: 'C. Pendiente de Despacho', fieldName: 'Dispatch_Pending_Quantity__c', type: 'number'},
        {label: 'C. Despachada', fieldName: 'Dispatched_Quantity__c', type: 'number'},
    ];

    connectedCallback(){
        getPurchaseOrderLines({purchaseOrderId : this.recordId}).then( response => {
            this.data = response;
        })
    }
}