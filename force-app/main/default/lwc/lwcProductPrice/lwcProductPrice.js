import { LightningElement, api } from 'lwc';

export default class LwcProductPrice extends LightningElement {
    @api recordId;
    fields = {
        Quantity__c : 0,
        Profit__c : 0,
        Unit_Cost_GTQ__c : 0,
        Unit_Cost_USD__c : 0,
        Dollar_Cost__c : 0,
        Taxes__c : 0,
        Internal_Shipping__c : 0,
        External_Shipping__c : 0,
        External_Shipping_USD__c : 0,
        Unit_Price_GTQ__c : 0,
    }

    fieldChange(event){
        this.fields[event.target.fieldName] = Number(event.target.value);

        if(event.target.fieldName === "Unit_Cost_GTQ__c" || event.target.fieldName === "Dollar_Cost__c"){
            this.fields.Unit_Cost_USD__c = this.fields.Dollar_Cost__c <= 0 ? 0 : this.fields.Unit_Cost_GTQ__c / this.fields.Dollar_Cost__c;
            this.setInputValue("Unit_Cost_USD__c", this.fields.Unit_Cost_USD__c);
        }

        if(event.target.fieldName === "Unit_Cost_USD__c"){
            this.fields.Unit_Cost_GTQ__c = this.fields.Unit_Cost_USD__c * this.fields.Dollar_Cost__c;
            this.setInputValue("Unit_Cost_GTQ__c", this.fields.Unit_Cost_GTQ__c);
        }

        if(event.target.fieldName === "Unit_Price_GTQ__c"){
            this.calculateProfit();
        } else {
            this.calculatePrice();
        }
    }

    calculateProfit(){
        const cost = this.getCost();
        const result = ((this.fields.Quantity__c * this.fields.Unit_Price_GTQ__c / cost) - 1) * 100;
        this.fields.Profit__c = cost === 0 ? 0 : result;
        this.setInputValue("Profit__c", this.fields.Profit__c);
    }

    calculatePrice(){
        const cost = this.getCost();
        const result = cost * (1 + this.fields.Profit__c / 100) /  this.fields.Quantity__c;
        this.fields.Unit_Price_GTQ__c = this.fields.Quantity__c === 0 ? 0 : result;
        this.setInputValue("Unit_Price_GTQ__c", this.fields.Unit_Price_GTQ__c);
    }

    getCost(){
        let cost = this.fields.Quantity__c * this.fields.Unit_Cost_GTQ__c;
        cost += this.fields.Taxes__c + this.fields.Internal_Shipping__c + this.fields.External_Shipping__c;
        cost += this.fields.External_Shipping_USD__c * this.fields.Dollar_Cost__c;
        return cost;
    }
    
    setInputValue(search, value){
        let inputs = this.template.querySelectorAll('lightning-input-field');
        inputs.forEach(element => {
            if (element.fieldName === search){
                element.value = value.toFixed(2);
            }
        });
    }

    success(){
        this.dispatchEvent(new CustomEvent('success'));
    }

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}