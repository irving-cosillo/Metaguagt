import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import addBatch from '@salesforce/apex/ClassProduct.addBatch';

export default class LwcProductPriceBatch extends LightningElement {
    @track collapsed = false;

    connectedCallback(){
        window.console.clear();
    }

    changeCommunField(event){
        this.template.querySelector("c-lwc-batch-products").changeCommunField(event);
    }

    addProducts(event){
        this.template.querySelector("c-lwc-batch-products").addProducts(event.detail.products);
    }

    collapsePanel(){
        this.collapsed = !this.collapsed;
    }

    fix(number){
        return Number((number*1).toFixed(2));
    }

    save(event){
        const {data, communFields} = event.detail;
        let prices = [];
        data.forEach(product => {
            prices.push({
                Quantity__c : product.Quantity * 1,
                Dollar_Cost__c : this.fix(communFields.Dollar_Cost__c),
                Unit_Cost_USD__c : this.fix(product.Cost_GTQ),
                Unit_Cost_GTQ__c : this.fix(product.Cost_USD),
                External_Shipping__c : this.fix(product.Shipping * communFields.External_Shipping__c / 100),
                External_Shipping_USD__c : this.fix(product.Shipping * communFields.External_Shipping_USD__c / 100),
                Internal_Shipping__c : this.fix(product.Shipping * communFields.Internal_Shipping__c / 100),
                Taxes__c : this.fix(product.Taxes * communFields.Taxes__c / 100),
                Profit__c : this.fix(product.Profit),
                Name : product.Description__c,
                Unit_Price_GTQ__c : this.fix(product.Price),
                Product__c : product.Id
            });
        });

        this.template.querySelector('c-lwc-batch-input').clear();

        addBatch({prices}).then( () => {
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'Lote de precios guardados con éxito.',
                variant: 'success'
            }));
        }).catch( error => {
            window.console.log(error);
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'Error al guardar los precios en el sistema, por favor intente de nuevo.',
                variant: 'error'
            }));
        });
    }
}