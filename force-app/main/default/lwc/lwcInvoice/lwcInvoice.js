import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPurchaseOrderInfo from '@salesforce/apex/ClassInvoice.getPurchaseOrderInfo';
import createInvoice from '@salesforce/apex/ClassInvoice.createInvoice';

export default class LwcInvoice extends LightningElement {
    @api recordId;

    quoteId;
    accountId;
    Is_EInvoice__c = true;
    isCambiaria = false;
    isVariableAmount = false;

    invoice = {
        Purchase_Order__c : null,
        Email__c : null,
        Date__c : this.todaysDate(),
        Is_EInvoice__c : 'Si',
        Type__c : 'Estandard',
        Category__c : 'Ordenes de Despacho',
        Amount__c: null,
        Description__c : null,
        Dispatch_Orders__c : [],
        Partial_Payments__c : []
    }

    dispatchOrderOptions = [];

    categoryOptions = [
        { label: 'Ordenes de Despacho', value: 'Ordenes de Despacho' },
        { label: 'Monto Variable', value: 'Monto Variable' },
    ];

    typeOptions = [
        { label: 'Estandard', value: 'Estandard' },
        { label: 'Cambiaria', value: 'Cambiaria' },
    ];

    yesNoOptions = [
        { label: 'Si', value: 'Si' },
        { label: 'No', value: 'No' },
    ];

    renderedCallback(){
        if (this.invoice.Purchase_Order__c !== this.recordId){
            this.invoice.Purchase_Order__c = this.recordId;
            if ( this.recordId ) {
                getPurchaseOrderInfo({ purchaseOrderId : this.recordId }).then(info => {
                    this.dispatchOrderOptions = !info.dispatchOrders ? [] : info.dispatchOrders.map( dispatchOrder => {
                        return { label : dispatchOrder.Name , value : dispatchOrder.Id };
                    });
                    this.invoice.Email__c = info.companyEmail;
                    this.quoteId = info.quote.Id;
                    this.accountId = info.purchaseOrder.Account__c;
                });
            }
        }
    }

    fieldChange(event){
        if(event.target.name in this.invoice) {
            this.invoice[event.target.name] = JSON.parse(JSON.stringify(event.target.value));
            if(event.target.name === "Category__c"){
                if(event.target.value === "Monto Variable"){
                    this.invoice.Dispatch_Orders__c = [];
                } else {
                    this.invoice.Amount__c = null;
                    this.invoice.Description__c = null;
                }
            }
            if (event.target.name === "Type__c" && event.target.value === "Estandard"){
                this.invoice.Partial_Payments__c = [];
            }
        }
        else if(event.target.ariaLabel){
            const index = this.invoice.Partial_Payments__c.findIndex( x => x.Id === event.target.ariaLabel);
            if (index >= 0) {
                this.invoice.Partial_Payments__c[index][event.target.name] = event.target.value;
            }
        }

        this.Is_EInvoice__c = this.invoice.Is_EInvoice__c === 'Si';
        this.isCambiaria = this.invoice.Type__c === 'Cambiaria';
        this.isVariableAmount = this.invoice.Category__c === 'Monto Variable';
    }

    stringify(arr){
        return arr && arr.length > 0 ? JSON.stringify(arr) : null;
    }

    @api save(){
        let invoiceToSend = {...this.invoice};
        invoiceToSend.Dispatch_Orders__c = this.stringify(invoiceToSend.Dispatch_Orders__c);
        invoiceToSend.Partial_Payments__c = this.stringify(invoiceToSend.Partial_Payments__c);
        invoiceToSend.Date__c = new Date(invoiceToSend.Date__c);
        invoiceToSend.Is_EInvoice__c = invoiceToSend.Is_EInvoice__c === "Si";
        if (!this.isInvalid()){
            createInvoice({invoice : invoiceToSend}).then( () => {
                this.dispatchEvent(new ShowToastEvent({
                    title: '',
                    message: 'Factura generada con éxito.',
                    variant: 'success'
                }));
            }).catch( error => {
                window.console.log(error);
                if (error.body && error.body.message) {
                    this.dispatchError(error.body.message);
                } else {
                    this.dispatchError('La factura no pudo ser generada con éxito, por favor intente de nuevo.');
                }
            }).finally(() => {
                this.dispatchEvent(new CustomEvent('cancel'));
            })
        }
    }

    dispatchError(message){
        this.dispatchEvent(new ShowToastEvent({
            title: '',
            message,
            variant: 'error'
        }));
    }

    isInvalid(){
        let result = null;
        if (!this.invoice.Date__c){
            result = "Debe de ingresar una fecha.";
        }
        if (this.Is_EInvoice__c && !this.invoice.Email__c){
            result = "Debe de ingresar un correo electrónico.";
        }
        if (!this.isVariableAmount && this.invoice.Dispatch_Orders__c.length <= 0){
            result = "Debe de elegir por lo menos una orden de compra.";
        }
        if (this.isVariableAmount){
            if (!this.invoice.Amount__c){
                result = "Debe de ingresar un valor para el monto.";
            }
            else if (this.invoice.Amount__c <= 0){
                result = "Debe de ingresar un monto mayor a 0.";
            }
            if (!this.invoice.Description__c){
                result = "Debe de ingresar una descripción.";
            }
        }
        if (result){
            this.dispatchError(result);
            return true;
        } else {
            return false;
        }
    }

    deletePayment(event){
        this.invoice.Partial_Payments__c = this.invoice.Partial_Payments__c.filter( x => x.Id !== event.target.name);
        this.invoice = JSON.parse(JSON.stringify(this.invoice));
    }

    addPayment(){
        this.invoice.Partial_Payments__c.push({
            Id : this.generateId(),
            paymentName : null,
            paymentDate: this.todaysDate(),
            paymentAmount: null
        });
        this.invoice = JSON.parse(JSON.stringify(this.invoice));
    }

    todaysDate(){
        let today = new Date();
        return today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + today.getDate();
    }

    generateId() {
        return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c =>
            (
                c ^
                (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))
            ).toString(16)
        );
    }
}