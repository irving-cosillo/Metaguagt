import { LightningElement, api } from 'lwc';
import { NumeroALetras } from "c/lwcNumbersToLetters";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class LwcQuoteTable extends LightningElement {
    @api quoteId;
    @api quoteLines;
    @api productsOfLines;

    editable;
    discount;
    currency;
    hasData = false;
    total = 0;
    data = [];
    lineProducts = [];
    selectedRows = [];
    columns;

    columnsWithoutActions = [
        {label: 'Código', fieldName: 'Name', type: 'text', initialWidth: 100},
        {label: 'Descripción', fieldName: 'Description__c', type: 'text', wrapText : true},
        {label: 'Días/Semanas', fieldName: 'Time__c', type: 'number', editable: true},
        {label: 'T. Entrega', fieldName: 'Delivery_Time__c', type: 'text'},
        {label: 'Cantidad', fieldName: 'Quantity__c', type: 'number', editable: true},
        {label: 'Precio', fieldName: 'Price__c', type: 'currency', typeAttributes : {
            currencyCode : this.currency, currencyDisplayAs : 'symbol', maximumFractionDigits : '2'}
        },
        {label: 'Importe', fieldName: 'Subtotal__c', type: 'currency', typeAttributes : {
            currencyCode : this.currency, currencyDisplayAs : 'symbol', maximumFractionDigits : '2'}
        },
    ];

    @api
    get quoteDiscount(){
        return this.discount;
    }
    set quoteDiscount(value){
        this.discount = value ? value : 0;
        this.updateTotal();
    }

    @api
    get currencyCode(){
        return this.currency;
    }
    set currencyCode(value){
        this.currency = value;
        this.setColumnsCurrencyCode();
        this.changeDataCurrency();
        this.updateTotal();
        this.setColumnsCurrencyCode();
    }

    @api
    get converted(){
        return this.editable;
    }
    set converted(value){
        this.editable = !value;
        this.setColumnsCurrencyCode();
    }

    @api getData(){
        return this.data;
    }

    @api add(products){
        let data = [...this.data];
        let lineProducts = [...this.lineProducts];
        products.forEach(product => {
            if (!this.data.find( item => item.Name === product.Name)){
                lineProducts.push(product);
                const priceGTQ = product.Related_Price__c ? product.Related_Price__r.Unit_Price_GTQ__c : null;
                const priceUSD = product.Related_Price__c ? product.Related_Price__r.Unit_Price_USD__c : null;

                data.push({
                    rowId: this.generateId(),
                    Index__c: data.length,
                    Quote__c: this.quoteId,
                    Name: product.Name,
                    Product__c: product.Id,
                    Description__c: product.Description__c,
                    Time__c : 0,
                    Quantity__c: 1,
                    Type__c: "Normal",
                    Delivery_Time__c: "Inmediato",
                    Price__c : this.currency === "GTQ" ? priceGTQ : priceUSD,
                    Product_Price__c : product.Related_Price__c,
                    Product_Price__r : {
                        Unit_Price_GTQ__c : priceGTQ,
                        Unit_Price_USD__c : priceUSD
                    },
                    Subtotal__c: this.currency === "GTQ" ? priceGTQ : priceUSD,
                    Subtotal_GTQ__c: priceGTQ,
                    Subtotal_USD__c: priceUSD,
                    Time_In_Days__c: true,
                    Brand__c: false,
                    Family__c: false,
                    Subfamily__c: false,
                    Unit__c: false,
                    Material__c: false,
                    Dimensions__c: false,
                    Old_Code__c: false,
                });
            }
        });

        this.lineProducts = lineProducts;
        this.data = data;
        this.hasData = true;
        this.updateTotal();
    }

    setColumnsCurrencyCode(){
        let columnsWithoutActions = [...this.columnsWithoutActions];
        columnsWithoutActions.find(column => column.fieldName === "Price__c").typeAttributes.currencyCode = this.currency;
        columnsWithoutActions.find(column => column.fieldName === "Subtotal__c").typeAttributes.currencyCode = this.currency;
        columnsWithoutActions.find(column => column.fieldName === "Time__c").editable = this.editable;
        columnsWithoutActions.find(column => column.fieldName === "Quantity__c").editable = this.editable;
        this.columns = !this.editable ? columnsWithoutActions : columnsWithoutActions.concat({
            type: "action",
            typeAttributes: {
                rowActions: this.getRowActions
            }
        });
    }

    connectedCallback() {
        this.setColumnsCurrencyCode();
        const data = [];
        this.quoteLines.forEach( (item, index) => {
            const product = this.productsOfLines[index];
            console.log(item);
            data.push({
                Id: item.Id,
                rowId: this.generateId(),
                Index__c: item.Index__c,
                Quote__c: this.quoteId,
                Name: product.Name,
                Product__c: product.Id,
                Description__c: item.Description__c,
                Time__c : item.Time__c,
                Quantity__c: item.Quantity__c,
                Type__c: item.Type__c,
                Delivery_Time__c: item.Delivery_Time__c,
                Time_In_Days__c: item.Time_In_Days__c,
                Brand__c: item.Brand__c,
                Family__c: item.Family__c,
                Subfamily__c: item.Subfamily__c,
                Unit__c: item.Unit__c,
                Material__c: item.Material__c,
                Dimensions__c: item.Dimensions__c,
                Old_Code__c: item.Old_Code__c,
                Subtotal_GTQ__c: item.Subtotal_GTQ__c,
                Subtotal_USD__c: item.Subtotal_USD__c,
                Product_Price__c: item.Product_Price__c,
                Product_Price__r : item.Type__c === "Child" ? null : {
                    Unit_Price_GTQ__c : item.Product_Price__r.Unit_Price_GTQ__c,
                    Unit_Price_USD__c : item.Product_Price__r.Unit_Price_USD__c
                },
                Price__c : item.Type__c === "Child" ? null : this.currency === "GTQ" ?
                    item.Product_Price__r.Unit_Price_GTQ__c : item.Product_Price__r.Unit_Price_USD__c,
                Subtotal__c: item.Type__c === "Child" ? null : this.currency === "GTQ" ?
                    item.Subtotal_GTQ__c : item.Subtotal_USD__c
            });
        });

        this.lineProducts = [...this.productsOfLines];
        this.data = data;
        this.hasData = this.data.length > 0;
        this.updateTotal()
    }

    getRowActions(row, doneCallback) {
        let actions = [{ name: "Add_Child", label: "Agregar Entrega Parcial"}];
        if(row.Type__c !== "Father"){
            actions = actions.concat([{
                name: "Time_In_Days__c",
                label: row.Time_In_Days__c ? "Mostrar Tiempo en Semanas" : "Mostrar Tiempo en Días"
            }]);
        }
        if(row.Type__c !== "Child"){
            actions = actions.concat([
                { name: "Old_Code__c", label: row.Old_Code__c ? "Ocultar Código Anterior" : "Mostrar Código Anterior" },
                { name: "Brand__c", label: row.Brand__c ? "Ocultar Marca" : "Mostrar Marca" },
                { name: "Family__c", label: row.Family__c ? "Ocultar Familia" : "Mostrar Familia" },
                { name: "Subfamily__c", label: row.Subfamily__c ? "Ocultar Subfamilia" : "Mostrar Subfamilia" },
                { name: "Unit__c", label: row.Unit__c ? "Ocultar Unidad" : "Mostrar Unidad" },
                { name: "Material__c", label: row.Material__c ? "Ocultar Material" : "Mostrar Material" },
                { name: "Dimensions__c", label: row.Dimensions__c ? "Ocultar Dimensión" : "Mostrar Dimensión" }
            ]);
        }
        doneCallback(actions);
    }

    handleRowAction(event){
        let data = [...this.data];
        const { action, row } = event.detail;
        const index = this.data.findIndex(item => item.rowId === row.rowId);

        if( action.name === "Time_In_Days__c"){
            data = this.setDeliveryTime(data, index, true);
        } else if( action.name === "Add_Child"){
            data = this.addChild(data, index);
        } else {
            data[index][action.name] = !row[action.name];
            const updatedRow = data[index];
            const lineProduct = this.lineProducts[index];
            const brand = updatedRow.Brand__c ? ' ' + lineProduct.Brand__c : '';
            const family = updatedRow.Family__c ? ' ' + lineProduct.Family__c : '';
            const subfamily = updatedRow.Subfamily__c ? ' ' + lineProduct.Subfamily__c : '';
            const unit = updatedRow.Unit__c ? ' ' + lineProduct.Unit__c : '';

            const m = lineProduct.Material__c ? lineProduct.Material__c : '';
            const material = updatedRow.Material__c ? ' ' + m : '';

            const d = lineProduct.Dimensions__c  ? lineProduct.Dimensions__c : '';
            const dimensions = updatedRow.Dimensions__c ? ' ' + d : '';

            data[index].Description__c = lineProduct.Description__c + brand + family + subfamily + unit + material + dimensions;
            if(action.name === 'Old_Code__c' && data[index][action.name]){
                this.dispatchEvent( new ShowToastEvent({
                    title: '',
                    message: 'El código anterior se mostrará únicamente en el PDF.',
                    variant: 'warning'
                }));
            }
        }
        this.data = data;
        this.updateTotal();
    }

    setDeliveryTime(data, index, changeValue){
        data[index].Time_In_Days__c = changeValue ?
            !data[index].Time_In_Days__c : data[index].Time_In_Days__c;
        if (data[index].Time__c <= 0 ){
            data[index].Delivery_Time__c = 'Inmediata';
        } else {
            data[index].Delivery_Time__c = data[index].Time_In_Days__c ?
            Number(data[index].Time__c) + ' día' : Number(data[index].Time__c) + ' semana';
            data[index].Delivery_Time__c += data[index].Time__c > 1 ? 's' : '';
        }
        return data;
    }

    addChild(data, index){
        let lineProducts = [...this.lineProducts];
        const product = lineProducts[index];
        const fatherIndex = data.findIndex(item => item.Name === data[index].Name);
        const childs = this.data.filter(item => item.Type__c === "Child" && item.Name === data[index].Name);
        data[fatherIndex].Type__c = "Father";
        console.log('Adding child');
        console.log('Father product price: ', data[fatherIndex].Product_Price__c);
        console.log({
            Unit_Price_GTQ__c : data[fatherIndex].Product_Price__r.Unit_Price_GTQ__c,
            Unit_Price_USD__c : data[fatherIndex].Product_Price__r.Unit_Price_USD__c
        });
        lineProducts.splice(index + 1, 0, product);
        data.splice(index + 1, 0, {
            rowId: this.generateId(),
            Index__c: -1,
            Quote__c: this.quoteId,
            Name: product.Name,
            Product__c: product.Id,
            Type__c: "Child",
            Description__c: null,
            Time__c : data[fatherIndex].Time__c,
            Delivery_Time__c: data[fatherIndex].Delivery_Time__c,
            Price__c : null,
            Quantity__c: childs.length <= 0 ? data[fatherIndex].Quantity__c : 1,
            Product_Price__c: data[fatherIndex].Product_Price__c,
            Product_Price__r : {
                Unit_Price_GTQ__c : data[fatherIndex].Product_Price__r.Unit_Price_GTQ__c,
                Unit_Price_USD__c : data[fatherIndex].Product_Price__r.Unit_Price_USD__c
            },
            Subtotal_GTQ__c: null,
            Subtotal_USD__c: null,
            Subtotal__c: null,
            Time_In_Days__c: true,
            Brand__c: false,
            Family__c: false,
            Subfamily__c: false,
            Unit__c: false,
            Material__c: false,
            Dimensions__c: false,
            Old_Code__c: false
        });
        this.lineProducts = lineProducts;
        return data;
    }

    updateTotal(){
        let cont = 0;
        let data = [...this.data];
        this.data = data.map((row,index) => {
            if(row.Type__c === "Father"){
                const childs = this.data.filter(item => item.Type__c === "Child" && item.Name === row.Name);
                if(childs.length <= 0){
                    row.Type__c = "Normal";
                    row.Time__c = 0;
                    row.Delivery_Time__c = "Inmediato";
                } else {
                    let quantity = 0;
                    childs.forEach( child => { quantity += Number(child.Quantity__c)});
                    const sameDelivery = childs.every( (val, i, arr) => val.Delivery_Time__c === arr[0].Delivery_Time__c );
                    row.Quantity__c = quantity;
                    row.Subtotal__c = row.Price__c * quantity;
                    row.Subtotal_GTQ__c = row.Product_Price__r.Unit_Price_GTQ__c * quantity;
                    row.Subtotal_USD__c = row.Product_Price__r.Unit_Price_USD__c * quantity;
                    row.Delivery_Time__c = sameDelivery ? childs[0].Delivery_Time__c : "A Convenir";
                    row.Time__c = sameDelivery ? childs[0].Time__c : 0;
                }
            }
            if (row.Type__c === "Normal"){
                row.Subtotal__c = row.Price__c * row.Quantity__c;
                row.Subtotal_GTQ__c = row.Product_Price__r.Unit_Price_GTQ__c * row.Quantity__c;
                row.Subtotal_USD__c = row.Product_Price__r.Unit_Price_USD__c * row.Quantity__c;
            }
            if (row.Type__c === "Child"){
                row.Subtotal__c = null;
                row.Subtotal_GTQ__c = null;
                row.Subtotal_USD__c = null;
            }
            row.Index__c = index;
            cont += Number(row.Subtotal__c);
            return row;
        });
        this.total = cont * (1 - this.discount/100);
    }

    cellChange(event){
        let data = [...this.data];
        const draftValue = event.detail.draftValues[0];
        const index = data.findIndex(x => x.rowId === draftValue.rowId);
        this.template.querySelector("lightning-datatable").draftValues = [];

        let invalid = false;
        Object.keys(draftValue).forEach(key => {
            if (Number(draftValue[key]) < 0 ) {
                invalid = true;
            }
        })

        if (!invalid){
            if(draftValue.hasOwnProperty('Time__c')){
                Object.assign(data[index], draftValue);
                data = this.setDeliveryTime(data, index, false);
            }

            if (data[index].Type__c !== "Father"){
                Object.assign(data[index], draftValue);
            }

            this.data = data;
            this.updateTotal();
        }
    }

    selectRows(event){
        this.selectedRows = event.detail.selectedRows;
        const state = this.selectedRows.length > 0;
        this.dispatchEvent(new CustomEvent('showbutton', {
            detail : {
                state
            }
        }));
    }

    @api getTotalInLetters(){
        return NumeroALetras(this.total, {
            plural: this.currency === "GTQ" ? "QUETZALES" : "DOLARES",
            singular:  this.currency === "GTQ" ? "QUETZAL" : "DOLAR",
            centPlural: "CENTAVOS",
            centSingular: "CENTAVO"
        });
    }

    @api removeSelectedRows(){
        let data = [];
        let lineProducts = [];
        this.data.forEach((row, index) => {
            if(!this.selectedRows.find(item =>
                item.Type__c === "Father" && item.Name === row.Name ||
                item.Type__c !== "Father" && item.rowId === row.rowId )){
                data.push(row);
                lineProducts.push(this.lineProducts[index]);
            }
        });

        this.lineProducts = lineProducts;
        this.data = data;
        this.hasData = data.length > 0;
        this.updateTotal();
    }

    changeDataCurrency(){
        this.data = this.data.map((row, index) =>{
            if (row.Type__c !== "Child"){
                const priceGTQ = row.Product_Price__r.Unit_Price_GTQ__c;
                const priceUSD = row.Product_Price__r.Unit_Price_USD__c;
                row.Subtotal_USD__c = priceUSD * row.Quantity__c;
                row.Subtotal_GTQ__c = priceGTQ * row.Quantity__c;
                row.Price__c = this.currency === "GTQ" ? priceGTQ : priceUSD;
                row.Subtotal__c = this.currency === "GTQ" ? row.Subtotal_GTQ__c : row.Subtotal_USD__c;
            }
            return row;
        });
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