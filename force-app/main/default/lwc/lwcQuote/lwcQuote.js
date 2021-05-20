import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import saveQuote from '@salesforce/apex/ClassQuote.saveQuote';
import getQuote from '@salesforce/apex/ClassQuote.getQuote';
import getQuoteLines from '@salesforce/apex/ClassQuote.getQuoteLines';
import getProductsOfLines from '@salesforce/apex/ClassQuote.getProductsOfLines';
import createPurchaseOrder from '@salesforce/apex/ClassPurchaseOrder.createPurchaseOrder';
import { NavigationMixin } from 'lightning/navigation';

export default class LwcQuote extends NavigationMixin(LightningElement) {
    @api recordId;

    quote;
    quoteLines;
    productsOfLines;

    showModal = false;
    isOrdersModal = false;
    isProductsModal = false;
    isButtonVisible = false;
    modalHeading;
    orderId;
    authorizedContact;

    navigateToRecordViewPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                actionName: 'view'
            }
        });
    }

    connectedCallback(){
        window.console.clear();
        getQuote({quoteId : this.recordId}).then( quote => {
            getQuoteLines({quoteId : this.recordId}).then( quoteLines => {
                getProductsOfLines({quoteId : this.recordId}).then( productsOfLines => {
                    this.productsOfLines = productsOfLines.map(item =>{ return item.Product__r});
                    this.quoteLines = quoteLines;
                    this.quote = quote;
                });
            });
        });
    }

    add(){
        const products = this.template.querySelector("c-lwc-search-product").add();
        this.template.querySelector("c-lwc-quote-table").add(products);
        this.closeModal();
    }

    save(action){
        let data = this.template.querySelector("c-lwc-quote-table").getData();
        const totalInLetters = this.template.querySelector("c-lwc-quote-table").getTotalInLetters();

        let deliveryTime;
        data.forEach((item, index) => {
            if (index === 0){
                deliveryTime = item.Delivery_Time__c;
            } else if( deliveryTime !== item.Delivery_Time__c){
                deliveryTime = "A Convenir";
            }
        });
        this.quote.Total_In_Letters__c = totalInLetters;
        this.quote.Delivery_Time__c = deliveryTime;
        this.showModal = false;
        console.log('data to be saved: ', data);
        data = data.map( row => {
            row.Product_Price__r = undefined;
            return row;
        });
        console.log('data to be saved: ', data);
        

        saveQuote({ quote : this.quote, data}).then(() => {
            if (action !== 'convert'){
                eval("$A.get('e.force:refreshView').fire();");
                this.dispatchEvent( new ShowToastEvent({
                    title: '',
                    message: 'Cotización guardada con éxito.',
                    variant: 'success'
                }));
            } else {
                createPurchaseOrder({quoteId: this.recordId, contactId : this.authorizedContact, orderId : this.orderId}).then( purchaseOrderId => {
                    let quote = {...this.quote};
                    quote.Converted__c = true;
                    this.quote = quote;
                    eval("$A.get('e.force:refreshView').fire();");
                    this.navigateToRecordViewPage(purchaseOrderId);
                    this.dispatchEvent( new ShowToastEvent({
                        title: '',
                        message: 'La cotización fue convertida a orden de trabajo con éxito.',
                        variant: 'success'
                    }));
                }).catch( error => {
                    this.errorMessage(error);
                });
            }
        }).catch(error => {
            this.errorMessage(error);
        })
    }

    convert(){
        this.save('convert');
    }

    discountChange(event){
        let quote = {...this.quote};
        quote.Discount__c = event.target.value;
        this.quote = quote;
    }

    orderIdChange(event){
        this.orderId = event.target.value;
    }

    contactChange(event){
        this.authorizedContact = event.target.value;
    }

    showButton(event){
        this.isButtonVisible = event.detail.state;
    }

    deleteProducts(){
        this.template.querySelector("c-lwc-quote-table").removeSelectedRows();
        this.isButtonVisible = false;
    }

    openProductsModal(){
        this.modalHeading = 'Agregar productos';
        this.isOrdersModal = false;
        this.isProductsModal = true;
        this.showModal = true;
    }

    openOrdersModal(){
        this.modalHeading = 'Orden de Compra';
        this.isOrdersModal = true;
        this.isProductsModal = false;
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    handleSubmit(event){
        window.console.log("submit");
        event.preventDefault();
    }

    changeCurrency(){
        let quote = {...this.quote};
        quote.Currency_Code__c = quote.Currency_Code__c === "GTQ" ? "USD" : "GTQ";
        this.quote = quote;
    }

    errorMessage(error){
        const message = error.body && error.body.message ? error.body.message : error;
        console.error(message);
        this.dispatchEvent( new ShowToastEvent({
            title: '',
            message: 'Error: ' + message,
            variant: 'error'
        }));
    }
}