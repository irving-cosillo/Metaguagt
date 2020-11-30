import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPurchaseOrderInfo from '@salesforce/apex/ClassInvoice.getPurchaseOrderInfo';
import createInvoice from '@salesforce/apex/ClassInvoice.createInvoice';
import OrderNumber from '@salesforce/schema/Order.OrderNumber';

export default class LwcInvoice extends LightningElement {
    @api recordId;

    quoteId;
    accountId;
    accountNIT;
    Is_EInvoice__c = true;
    isCambiaria = false;
    isVariableAmount = false;
    info;

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
                    this.info = info;
                    this.invoice.Currency_Code__c = info.purchaseOrder.Currency_Code__c;
                    this.invoice.Email__c = info.companyEmail;
                    this.quoteId = info.quote.Id;
                    this.accountId = info.purchaseOrder.Account__c;
                    this.accountNIT = info.purchaseOrder.Account__r.NIT__c;
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
        const nit = this.accountNIT;
        let invoice = {...this.invoice};
        invoice.Dispatch_Orders__c = this.stringify(invoice.Dispatch_Orders__c);
        invoice.Partial_Payments__c = this.stringify(invoice.Partial_Payments__c);
        invoice.Date__c = new Date(invoice.Date__c);
        invoice.Is_EInvoice__c = invoice.Is_EInvoice__c === "Si";
        if (!this.isInvalid()){
            const xml = this.generateXML();
            createInvoice({invoice, nit, xml}).then( Id => {
                console.log('Invoice Id: ', Id);
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
            console.error(result);
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

    //----------------------------------- XML Generation -----------------------------------------

    generateXML(){
        const invoice = {...this.invoice};
        const info = {... this.info};

        let type = '';
        if ( invoice.Type__c === 'Estandard' ) {
            type = 'FACT'
        } else if ( invoice.Type__c === 'Cambiaria' ) {
            type = 'FACM'
        }

        const dispatchOrderAdenda = invoice.Dispatch_Orders__c && this.dispatchOrderOptions ?
            invoice.Dispatch_Orders__c.map(order => {
                return this.dispatchOrderOptions.find(item => item.value === order).label
            }).join(", ") : '';
        const contado = info.quote.Credit__c ? '' : 'x';
        const credito = info.quote.Credit__c ? 'x' : '';;
        let xml =
        `
            <dte:GTDocumento xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:dte="http://www.sat.gob.gt/dte/fel/0.2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Version="0.1" xsi:schemaLocation="http://www.sat.gob.gt/dte/fel/0.2.0">
            <dte:SAT ClaseDocumento="dte">
            <dte:DTE ID="DatosCertificados">
                <dte:DatosEmision ID="DatosEmision">
                <dte:DatosGenerales CodigoMoneda="${invoice.Currency_Code__c}" FechaHoraEmision="${invoice.Date__c}" Tipo="${type}"></dte:DatosGenerales>
                <dte:Emisor AfiliacionIVA="GEN" CodigoEstablecimiento="1" CorreoEmisor="demo@demo.com.gt" NITEmisor="${info.companyNIT}" NombreComercial="${info.companyName}" NombreEmisor="${info.companyLegalName}">
                    <dte:DireccionEmisor>
                    <dte:Direccion>${info.companyAddress}</dte:Direccion>
                    <dte:CodigoPostal>01001</dte:CodigoPostal>
                    <dte:Municipio>GUATEMALA</dte:Municipio>
                    <dte:Departamento>GUATEMALA</dte:Departamento>
                    <dte:Pais>GT</dte:Pais>
                    </dte:DireccionEmisor>
                </dte:Emisor>
                <dte:Receptor CorreoReceptor="${info.companyEmail}" IDReceptor="${this.accountNIT}" NombreReceptor="{nombreReceptor}">
                    <dte:DireccionReceptor>
                    <dte:Direccion>{direccionReceptor}</dte:Direccion>
                    <dte:CodigoPostal></dte:CodigoPostal>
                    <dte:Municipio></dte:Municipio>
                    <dte:Departamento></dte:Departamento>
                    <dte:Pais></dte:Pais>
                    </dte:DireccionReceptor>
                </dte:Receptor>
                <dte:Frases>
                    <dte:Frase CodigoEscenario="1" TipoFrase="1"></dte:Frase>
                    <dte:Frase CodigoEscenario="1" TipoFrase="2"></dte:Frase>
                </dte:Frases>
                <dte:Items>
                    {items}
                </dte:Items>
                <dte:Totales>
                    <dte:TotalImpuestos>
                    <dte:TotalImpuesto NombreCorto="IVA" TotalMontoImpuesto="{iva}"></dte:TotalImpuesto>
                    </dte:TotalImpuestos>
                    <dte:GranTotal>{total}</dte:GranTotal>
                </dte:Totales>
        `;

        if (type === 'FACM' && invoice.Partial_Payments__c && invoice.Partial_Payments__c.length){
            xml += '<dte:Complementos>';
            invoice.Partial_Payments__c.forEach(payment => {
                xml +=
                `
                    <dte:Complemento IDComplemento="Cambiaria" NombreComplemento="Cambiaria" URIComplemento="http://www.sat.gob.gt/fel/cambiaria.xsd">
                    <cfc:AbonosFacturaCambiaria xmlns:cfc="http://www.sat.gob.gt/dte/fel/CompCambiaria/0.1.0" Version="1" xsi:schemaLocation="http://www.sat.gob.gt/dte/fel/CompCambiaria/0.1.0 C:\Users\Desktop\SAT_FEL_FINAL_V1\Esquemas\GT_Complemento_Cambiaria-0.1.0.xsd">
                        <cfc:Abono>
                        <cfc:NumeroAbono>${payment.paymentName}</cfc:NumeroAbono>
                        <cfc:FechaVencimiento>${payment.paymentDate}</cfc:FechaVencimiento>
                        <cfc:MontoAbono>${payment.paymentAmount}</cfc:MontoAbono>
                        </cfc:Abono>
                    </cfc:AbonosFacturaCambiaria>
                    </dte:Complemento>
                `;
            });
            xml += '</dte:Complementos>';
        }

        xml +=
        `
                </dte:DatosEmision>
            </dte:DTE>
            <dte:Adenda>
                <Vendedor>${info.purchaseOrder.Quote__r.Sales_User__c}</Vendedor>
                <OrdenDeCompra>${info.purchaseOrder.Order_Id__c}</OrdenDeCompra>
                <OrdenDeEnvio>${dispatchOrderAdenda}</OrdenDeEnvio>
                <Contado>${contado}</Contado>
                <Credito><${credito}/Credito>
            </dte:Adenda>
            </dte:SAT>
        </dte:GTDocumento>
        `;

        return xml;
    }
}