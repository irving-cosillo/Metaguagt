import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
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

    searchValue = '';
    @wire (searchProducts, {input : '$searchValue'})
    handleSearch(result){
        const {data, error} = result;
        if (data){
            this.data = data;
            this.hasSearchResults = data && data.length;
        } else if (error) {
            console.error(error);
        }
    }

    search(event){
        this.searchValue = event.target.value;
        refreshApex(this.handleSearch);
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