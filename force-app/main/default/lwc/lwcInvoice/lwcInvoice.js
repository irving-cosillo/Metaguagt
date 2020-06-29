import { LightningElement, api } from 'lwc';
import getPurchaseOrderInfo from '@salesforce/apex/ClassInvoice.getPurchaseOrderInfo';

export default class LwcInvoice extends LightningElement {
    @api recordId;

    quoteId;
    accountId;
    isEInvoice = true;
    isCambiaria = false;
    isVariableAmount = false;

    invoice = {
        Id : null,
        email : null,
        date : this.todaysDate(),
        isEInvoice : 'yes',
        invoiceType : 'standard',
        invoiceCategory : 'dispatchOrder',
        amount: null,
        description : null,
        dispatchOrders : [],
        partialPayments : []
    }

    dispatchOrderOptions = [];

    invoiceCategoryOptions = [
        { label: 'Ordenes de Despacho', value: 'dispatchOrder' },
        { label: 'Monto variable', value: 'variableAmount' },
    ];

    invoiceTypeOptions = [
        { label: 'Factura', value: 'standard' },
        { label: 'Factura Cambiaria', value: 'cambiaria' },
        { label: 'Factura Especial', value: 'special' },
    ];

    yesNoOptions = [
        { label: 'Si', value: 'yes' },
        { label: 'No', value: 'no' },
    ];

    connectedCallback(){
        this.invoice.email = 'obtenerDeCMT@test.com';
    }

    renderedCallback(){
        if (this.invoice.Id !== this.recordId){
            this.invoice.Id = this.recordId;
            if ( this.recordId ) {
                getPurchaseOrderInfo({ purchaseOrderId : this.recordId }).then(info => {
                    this.dispatchOrderOptions = !info.dispatchOrders ? [] : info.dispatchOrders.map( dispatchOrder => {
                        return { label : dispatchOrder.Name , value : dispatchOrder.Id };
                    });
                    this.quoteId = info.quote.Id;
                    this.accountId = info.purchaseOrder.Account__c;
                });
            }
        }
    }

    fieldChange(event){
        if(this.invoice[event.target.name]) {
            this.invoice[event.target.name] = JSON.parse(JSON.stringify(event.target.value));
        }
        else if(event.target.ariaLabel){
            const index = this.invoice.partialPayments.findIndex( x => x.Id === event.target.ariaLabel);
            if (index >= 0) {
                this.invoice.partialPayments[index][event.target.name] = event.target.value;
            }
        }

        this.isEInvoice = this.invoice.isEInvoice === 'yes';
        this.isCambiaria = this.invoice.invoiceType === 'cambiaria';
        this.isVariableAmount = this.invoice.invoiceCategory === 'variableAmount';
    }

    save(){

    }

    deletePayment(event){
        this.invoice.partialPayments = this.invoice.partialPayments.filter( x => x.Id !== event.target.name);
        this.invoice = JSON.parse(JSON.stringify(this.invoice));
    }

    addPayment(){
        this.invoice.partialPayments.push({
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