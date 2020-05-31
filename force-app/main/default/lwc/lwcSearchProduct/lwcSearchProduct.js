import { LightningElement, api } from 'lwc';
import searchProducts from '@salesforce/apex/ClassProduct.getProducts';

export default class LwcSearchProduct extends LightningElement {
    @api buttonHidden;

    data;
    hasSearchResults = false;
    columns = [
        {label: 'Código', fieldName: 'Name', type: 'text', initialWidth: 100},
        {label: 'Nombre', fieldName: 'Description__c', type: 'text', wrapText : true},
        {label: 'Stock', fieldName: 'Stock__c', type: 'number', initialWidth: 70},
    ];

    search(event){
        const input = event.target.value;
        
        searchProducts({ input }).then ( result => {
            this.data = result;
            this.hasSearchResults = result && result.length > 0;
        });
    }

    @api add(){
        this.hasSearchResults = false;
        this.template.querySelector("lightning-input").value = "";
        const products = this.template.querySelector("lightning-datatable").getSelectedRows();
        this.dispatchEvent(
            new CustomEvent("addproducts",{
                detail : {
                    products
                }  
            })
        );
        return products;
    }
}