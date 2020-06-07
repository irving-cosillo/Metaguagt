import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBatchLines from '@salesforce/apex/ClassBatch.getBatchLines';
import submitBatch from '@salesforce/apex/ClassBatch.submitBatch';
import saveBatch from '@salesforce/apex/ClassBatch.saveBatch';
import getBatch from '@salesforce/apex/ClassBatch.getBatch';

export default class LwcProductPriceBatch extends LightningElement {
    @api recordId;

    data = [];
    selectedRows = [];

    hasSelectedRows = false;
    hasData = false;
    showModal = false;

    editable;
    modalHeading;
    isEditsModal;
    isProductsModal;
    isConfirmationsModal;

    batch = {};
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
        {label: 'Precio de Venta', fieldName: 'Price', type: 'currency', editable: true},
        {label: '% Ganancia Relativa', fieldName: 'Relative_Profit', type: 'number'},
    ];

    connectedCallback(){
        getBatch({batchId: this.recordId}).then(batch => {
            this.batch = batch;
            this.editable = !batch.Converted__c;

            let columns = [...this.columns];
            columns.find(column => column.fieldName === "Quantity").editable = this.editable;
            columns.find(column => column.fieldName === "Profit").editable = this.editable;
            columns.find(column => column.fieldName === "Cost_GTQ").editable = this.editable;
            columns.find(column => column.fieldName === "Cost_USD").editable = this.editable;
            columns.find(column => column.fieldName === "Shipping").editable = this.editable;
            columns.find(column => column.fieldName === "Taxes").editable = this.editable;
            columns.find(column => column.fieldName === "Price").editable = this.editable;
            this.columns = columns;

            getBatchLines({batchId: this.recordId}).then(lines => {
                let data = [];
                lines.forEach(line => {
                    data.push({
                        Id : line.Product__c,
                        lineId : line.Id,
                        Name : line.Product_Name__c,
                        Description__c : line.Product_Description__c,
                        Quantity : line.Quantity__c,
                        Profit : line.Profit__c,
                        Cost_GTQ : line.Unit_Cost_GTQ__c,
                        Cost_USD : line.Unit_Cost_USD__c,
                        Shipping : line.Shipping__c,
                        Taxes : line.Taxes__c,
                        Price : line.Unit_Price_GTQ__c,
                        Relative_Profit : null
                    });
                });
                this.data = data;
                this.hasData = data.length > 0;
                this.recalculateTable();
            });
        });
    }

    addProducts(products){
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

        this.recalculateTable();
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
                data[rowIndex].Cost_USD = this.batch.Dollar_Cost__c <= 0 ? 0 :
                                            this.fix(data[rowIndex].Cost_GTQ / this.batch.Dollar_Cost__c);
            }

            if(draftValue.hasOwnProperty('Cost_USD')){
                data[rowIndex].Cost_GTQ = this.fix(data[rowIndex].Cost_USD * this.batch.Dollar_Cost__c);
            }

            if(draftValue.hasOwnProperty("Price")){
                data[rowIndex].Profit = this.calculateProfit(data[rowIndex]);
            } else {
                data[rowIndex].Price = this.calculatePrice(data[rowIndex]);
            }

            const profit = (1 - this.getCost(data[rowIndex]) / data[rowIndex].Price) * 100;
            data[rowIndex].Relative_Profit = Math.round(profit * 10) / 10;
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
        let shipping = this.batch.Internal_Shipping__c + this.batch.External_Shipping_GTQ__c;
        shipping += this.batch.External_Shipping_USD__c * this.batch.Dollar_Cost__c;
        let cost = Number(product.Quantity) * Number(product.Cost_GTQ);
        cost += Number(product.Shipping) * shipping / 100;
        cost += Number(product.Taxes) * this.batch.Taxes__c / 100;
        return cost;
    }

    recalculateTable(){
        let data = JSON.parse(JSON.stringify(this.data));
        this.data = data.map( product => {
            product.Cost_USD = this.batch.Dollar_Cost__c <= 0 ? 0 :
                               this.fix(product.Cost_GTQ / this.batch.Dollar_Cost__c);
            product.Price = this.calculatePrice(product);
            const profit = (1 - this.getCost(product) / (product.Price * product.Quantity)) * 100;
            product.Relative_Profit = Math.round(profit * 10) / 10;
            return product;
        });
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
            saveBatch({batch: this.batch, batchLines : this.mapData()}).then( () => {
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

    submit(){
        this.closeModal();
        if(this.dataIsValid()){
            submitBatch({batch: this.batch, batchLines : this.mapData()}).then( () => {
                this.connectedCallback();
                this.dispatchEvent(new ShowToastEvent({
                    title: '',
                    message: 'Lote de precios enviado con éxito.',
                    variant: 'success'
                }));
            }).catch( error => {
                window.console.log(error);
                this.dispatchEvent(new ShowToastEvent({
                    title: '',
                    message: 'Error al enviar los precios en el sistema, por favor intente de nuevo.',
                    variant: 'error'
                }));
            });
        }
    }

    mapData(){
        let prices = [];
        this.data.forEach(product => {
            prices.push({
                Id : product.lineId,
                Quantity__c : product.Quantity * 1,
                Unit_Cost_USD__c : this.fix(product.Cost_USD),
                Unit_Cost_GTQ__c : this.fix(product.Cost_GTQ),
                Shipping__c : this.fix(product.Shipping),
                Taxes__c : this.fix(product.Taxes),
                Profit__c : this.fix(product.Profit),
                Unit_Price_GTQ__c : this.fix(product.Price),
                Product__c : product.Id,
                Price_Batch__c : this.recordId
            });
        });
        return prices;
    }

    edited(){
        this.closeModal();
        getBatch({batchId: this.recordId}).then(batch => {
            this.batch = batch;
            this.recalculateTable();
        });
    }

    add(){
        const products = this.template.querySelector("c-lwc-search-product").add();
        this.addProducts(products);
        this.closeModal();
    }

    openEditsModal(){
        this.modalHeading = 'Editar Lote';
        this.isEditsModal = true;
        this.isProductsModal = false;
        this.isConfirmationsModal = false;
        this.showModal = true;
    }

    openProductsModal(){
        this.modalHeading = 'Agregar Productos';
        this.isEditsModal = false;
        this.isProductsModal = true;
        this.isConfirmationsModal = false;
        this.showModal = true;
    }

    openConfirmationsModal(){
        this.modalHeading = 'Confirmación de Envío';
        this.isEditsModal = false;
        this.isProductsModal = false;
        this.isConfirmationsModal = true;
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }
}