import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class LwcBatchProducts extends LightningElement {
    @track data = [];
    @track selectedRows = [];
    @track hasSelectedRows = false;
    @track hasData = false;

    _collapsed;
    @track collapseLabel = "Ocultar Panel";
    @api get collapsed (){
        return this._collapsed;
    }
    set collapsed (value){
        this._collapsed = value;
        this.collapseLabel = value ? "Mostrar Panel" : "Ocultar Panel";
    }

    communFields = {
        Dollar_Cost__c : 0,
        Taxes__c : 0,
        Internal_Shipping__c : 0,
        External_Shipping__c : 0,
        External_Shipping_USD__c : 0
    };

    columns = [
        {label: 'Codigo', fieldName: 'Name', type: 'text', initialWidth: 100},
        {label: 'Nombre', fieldName: 'Description__c', type: 'text', wrapText : true, initialWidth: 200},
        {label: 'Cantidad', fieldName: 'Quantity', type: 'number', editable: true},
        {label: '% Ganancia', fieldName: 'Profit', type: 'number', editable: true},
        {label: 'Costo (Q)', fieldName: 'Cost_GTQ', type: 'currency', editable: true},
        {label: 'Costo ($)', fieldName: 'Cost_USD', type: 'currency', editable: true, 
            typeAttributes: { currencyCode: 'USD' }},
        {label: '% Flete', fieldName: 'Shipping', type: 'number', editable: true },
        {label: '% Impuestos', fieldName: 'Taxes', type: 'number', editable: true},
        {label: 'P. Venta', fieldName: 'Price', type: 'currency', editable: true}
    ];

    @api changeCommunField(event){
        const {fieldName, value} = event.detail;
        this.communFields[fieldName] = Number(value);
        this.recalculateTable();
    }

    @api addProducts(products){
        let data = [...this.data];
        products.forEach(product => {
            if (!this.data.find( item => item.Name === product.Name)){
                product.Quantity = 1;
                product.Profit = 0;
                product.Cost_GTQ = 0;
                product.Cost_USD = 0;
                product.Shipping = 0;
                product.Taxes = 0;
                data.push(product);
            }
        });

        this.data = data;
        this.hasData = true;
        this.recalculateTable();
    }
    
    assignPercentages(){ 
        let totalQuantity = 0;
        let percent = 0;

        this.data.forEach( product => {
            totalQuantity += product.Quantity;
        });   
        
        this.data = this.data.map(product => {
            percent = this.fix(product.Quantity * 100 / totalQuantity);
            product.Taxes = percent;
            product.Shipping = percent;
            return product;
        });
    }

    fix(number){
        return Number((number*1).toFixed(2));
    }

    cellChange(event) {
        let data = JSON.parse(JSON.stringify(this.data));
        const draftValue = event.detail.draftValues[0];
        const rowIndex = data.findIndex(x => x.Id === draftValue.Id);
        this.template.querySelector("lightning-datatable").draftValues = [];

        let invalid = false;
        Object.keys(draftValue).forEach(key => { 
            if( draftValue.hasOwnProperty('Quantity') && Number(draftValue[key]) <= 0){
                invalid = true;
            }
            if (!draftValue.hasOwnProperty('Profit') && Number(draftValue[key]) < 0 ) {
                    invalid = true;
            }
        })
        
        if (!invalid){
            Object.assign(data[rowIndex], draftValue); 

            if(draftValue.hasOwnProperty('Quantity')){
                data[rowIndex].Quantity = Math.round(data[rowIndex].Quantity);
            }

            if(draftValue.hasOwnProperty('Cost_GTQ')){
                data[rowIndex].Cost_USD = this.communFields.Dollar_Cost__c <= 0 ? 0 : 
                                            this.fix(data[rowIndex].Cost_GTQ / this.communFields.Dollar_Cost__c);
            }

            if(draftValue.hasOwnProperty('Cost_USD')){
                data[rowIndex].Cost_GTQ = this.fix(data[rowIndex].Cost_USD * this.communFields.Dollar_Cost__c);
            }

            if(draftValue.hasOwnProperty("Price")){
                data[rowIndex].Profit = this.calculateProfit(data[rowIndex]);
            } else {
                data[rowIndex].Price = this.calculatePrice(data[rowIndex]);
            }
            this.data = data;
        }
    }

    calculatePrice(product){
        const cost = this.getCost(product);
        const result = this.fix(cost * (1 + Number(product.Profit) /100) / Number(product.Quantity));
        return Number(product.Quantity__c) === 0 ? 0 : result;
    }

    calculateProfit(product){
        const cost = this.getCost(product);
        const result = this.fix(((Number(product.Quantity) * Number(product.Price) / cost) - 1 ) * 100);
        return cost === 0 ? 0 : result;
    }

    getCost(product){
        const commun = this.communFields;     
        let shipping = commun.Internal_Shipping__c + commun.External_Shipping__c;
        shipping += commun.External_Shipping_USD__c * commun.Dollar_Cost__c;
        let cost = Number(product.Quantity) * Number(product.Cost_GTQ);
        cost += Number(product.Shipping) * shipping / 100;
        cost += Number(product.Taxes) * commun.Taxes__c / 100;
        return cost;
    }

    recalculateTable(){
        let data = JSON.parse(JSON.stringify(this.data));
        this.data = data.map( product => {
            product.Cost_USD = this.communFields.Dollar_Cost__c <= 0 ? 0 : 
                               this.fix(product.Cost_GTQ / this.communFields.Dollar_Cost__c);
            product.Price = this.calculatePrice(product);
            return product;
        });
    }

    collapsePanel(){
        this.dispatchEvent(new CustomEvent("collapsepanel"));
    }

    rowSelection(event){
        this.selectedRows = event.target.selectedRows;
        this.hasSelectedRows = this.selectedRows.length > 0 ? true : false;
    }

    removeSelectedRows(){
        let data = [];  
        this.data.forEach(row => {
            if(!this.selectedRows.find(item => item === row.Id)){
                data.push(row);
            }
        });

        const percent = this.fix((100 / data.length));
        this.data = data.map(product => {
            product.Taxes = percent;
            product.Shipping = percent;
            return product;
        });

        this.hasSelectedRows = false;
        this.hasData = this.data.length > 0 ? true : false;
        this.updatePercents();

        if(this.collapsed && !this.hasData){
            this.collapsePanel();
        }
    }

    errorMessage(message){
        this.dispatchEvent( new ShowToastEvent({
            title: '',
            message: message,
            variant: 'error'
        }));
    }

    dataIsValid(){
        const data =  [...this.data];
        let result = true;
        let taxesTotal = 0;
        let shippingTotal = 0;
        let negativePrice = false;

        data.forEach( row => {
            taxesTotal += Number(row.Taxes);
            shippingTotal += Number(row.Shipping);
            negativePrice = negativePrice || Number(row.Price) < 0;
        });

        if(negativePrice){
            this.errorMessage('No pueden ingresarse productos con precios negativos.');
            result = false;
        }

        if(this.communFields.Dollar_Cost__c < 0){
            this.errorMessage('La tasa de dollar no puede ser menor a 0.');
            result = false;
        }

        if(this.communFields.Taxes__c < 0){
            this.errorMessage('Los impuestos aduanales no pueden ser menor a 0.');
            result = false;
        }

        if(this.communFields.Internal_Shipping__c < 0){
            this.errorMessage('El flete interno no puede ser menor a 0.');
            result = false;
        }

        if(this.communFields.External_Shipping__c < 0){
            this.errorMessage('El flete externo en Q no puede ser menor a 0.');
            result = false;
        }

        if(this.communFields.External_Shipping_USD__c < 0){
            this.errorMessage('El flete externo en $ no puede ser menor a 0.');
            result = false;
        }

        if(shippingTotal < 99.99){
            this.errorMessage('El total de la columna % flete debe de sumar 100%.');
            result = false;
        }

        if(taxesTotal < 99.99){
            this.errorMessage('El total de la columna % impuestos debe de sumar 100%.');
            result = false;
        }

        return result;
    }

    save(){
        if(this.dataIsValid()){
            this.dispatchEvent(new CustomEvent("save",{
                detail : {
                    data : this.data,
                    communFields : this.communFields
                }
            }));

            this.data = [];
            this.hasData = false;
            this.communFields = {
                Dollar_Cost__c : 0,
                Taxes__c : 0,
                Internal_Shipping__c : 0,
                External_Shipping__c : 0,
                External_Shipping_USD__c : 0
            };
        }        
    }
}