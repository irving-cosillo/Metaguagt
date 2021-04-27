import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPurchaseOrderLines from '@salesforce/apex/ClassPurchaseOrder.getPurchaseOrderLines';
import createDispatchOrder from '@salesforce/apex/ClassDispatchOrder.createDispatchOrder';

export default class LwcDispatchOrder extends NavigationMixin(LightningElement) {
    @api recordId;
    @api hasPO;
    @api objectName;

    data;
    purchaseOrderId;
    hasData = false;
    columns = [
        //{label: 'Código', fieldName: 'Product__c', type: 'text', initialWidth: 100},
        {label: 'Descripción', fieldName: 'Product_Name__c', type: 'text', wrapText : true},
        {label: 'Tiempo de Entrega', fieldName: 'Delivery_Time__c', type: 'text'},
        {label: 'C. Pedida', fieldName: 'Quantity__c', type: 'number'},
        {label: 'C. Pendiente de Despacho', fieldName: 'Dispatch_Pending_Quantity__c', type: 'number'},
        {label: 'C. Despachada', fieldName: 'Dispatched_Quantity__c', type: 'number'},
        {label: 'Stock', fieldName: 'Stock__c', type: 'number'},
        {label: 'C. a Despachar', fieldName: 'Dispatch_Quantity__c', type: 'number', editable: true},
    ];

    connectedCallback(){
        if(this.hasPO){
            this.purchaseOrderId = this.recordId;
            this.getLines(this.purchaseOrderId);
        }
    }

    POChanged(event){
        this.purchaseOrderId = event.target.value;
        this.getLines(this.purchaseOrderId);
    }

    getLines(purchaseOrderId){
        getPurchaseOrderLines({purchaseOrderId}).then( response => {
            this.data = response;
            this.hasData = response ? true : false;
        });
    }

    cellChange(event){
        let data = [...this.data];
        const draftValue = event.detail.draftValues[0];
        const index = data.findIndex(x => x.Id === draftValue.Id);
        this.template.querySelector("lightning-datatable").draftValues = [];
        Object.assign(data[index], draftValue);
        this.data = data;
    }

    @api save(){
        if(this.isValid()){
            let dispatchOrderLines = [];
            this.data.forEach( line => {
                if(line.Dispatch_Quantity__c){
                    dispatchOrderLines.push({
                        Purchase_Order_Line__c : line.Id,
                        Quantity__c : line.Dispatch_Quantity__c
                    });
                }
            });

            createDispatchOrder({ purchaseOrderId : this.purchaseOrderId, dispatchOrderLines})
            .then( recordId => {
                eval("$A.get('e.force:refreshView').fire();");
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId,
                        actionName: 'view'
                    }
                });
                this.dispatchEvent( new ShowToastEvent({
                    title: '',
                    message: 'Orden de Despacho guardada con éxito.',
                    variant: 'success'
                }));
            }).catch( error => {
                this.dispatchEvent(new CustomEvent('cancel'));
                this.dispatchEvent( new ShowToastEvent({
                    title: '',
                    message: 'Error: ' + error.body.message,
                    variant: 'error'
                }));
            });
        }
    }

    isValid(){
        let isGreater = false;
        let isLower = false;
        let noLines = true;

        this.data.forEach(line => {
            if(line.Dispatch_Quantity__c > line.Quantity__c - line.Dispatch_Pending_Quantity__c ){
                isGreater = true;
            }
            if(line.Dispatch_Quantity__c < 0 ){
                isLower = true;
            }
            if(line.Dispatch_Quantity__c && line.Dispatch_Quantity__c > 0){
                noLines = false;
            }
        });

        if(noLines){
            this.dispatchEvent( new ShowToastEvent({
                title: '',
                message: 'Error:  Debe de ingresar la cantidad de al menos un producto.',
                variant: 'error'
            }));
        }

        if(isGreater){
            this.dispatchEvent( new ShowToastEvent({
                title: '',
                message: 'Error: La cantidad ingresada excede la cantidad pendiente de despachar.',
                variant: 'error'
            }));
        }

        if (isLower){
            this.dispatchEvent( new ShowToastEvent({
                title: '',
                message: 'Error: La cantidad ingresada no puede ser menor a 0.',
                variant: 'error'
            }));
        }

        return !isLower && !isGreater && !noLines;
    }

    cancel(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'list'
            }
        });
    }
}