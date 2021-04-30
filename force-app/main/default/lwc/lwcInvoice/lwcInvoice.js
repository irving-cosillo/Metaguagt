import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPurchaseOrderInfo from '@salesforce/apex/ClassInvoice.getPurchaseOrderInfo';
import getClientLegalInformation from '@salesforce/apex/ClassInvoice.getClientLegalInformation';
import getInvoiceWrapper from '@salesforce/apex/ClassInvoice.getInvoiceWrapper';
import signInvoice from '@salesforce/apex/ClassInvoice.signInvoice';
import processInvoice from '@salesforce/apex/ClassInvoice.processInvoice';
import insertInvoiceApex from '@salesforce/apex/ClassInvoice.insertInvoiceApex';

export default class LwcInvoice extends LightningElement {
    @api recordId;

    quoteId;
    accountId;
    accountNIT;
    Is_EInvoice__c = true;
    isCambiaria = false;
    isVariableAmount = false;
    isLoading = false;
    info;
    total = 0.00;
    dispatchOrderLines;

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
                    this.invoice.Email__c = info.companyInfo.Invoice_Email__c;
                    this.quoteId = info.quote.Id;
                    this.accountId = info.purchaseOrder.Account__c;
                    this.dispatchOrderLines = info.dispatchOrderLines;
                    this.accountNIT = info.purchaseOrder.Account__r.NIT__c.replace('-','');
                });
            }
        }
    }

    fieldChange(event){
        let {name, value} = event.target;
        if(name in this.invoice) {
            this.invoice[name] = JSON.parse(JSON.stringify(value));
            if(name === "Category__c"){
                if(value === "Monto Variable"){
                    this.invoice.Dispatch_Orders__c = [];
                } else {
                    this.invoice.Amount__c = null;
                    this.invoice.Description__c = null;
                }
            }
            else if (name === "Amount__c"){
                this.total = value.toFixed(2);
            }
            else if (name === "Type__c" && value === "Estandard"){
                this.invoice.Partial_Payments__c = [];
            }
            else if (name === "Dispatch_Orders__c"){
                this.total = 0.00;
                const selectedOrderIds = JSON.parse(JSON.stringify(value));
                const lines = this.dispatchOrderLines.filter( dispatchOrderLine => selectedOrderIds.find( selectedOrderId => selectedOrderId === dispatchOrderLine.Dispatch_Order__c ));
                lines.forEach( line => {
                    if ( this.invoice.Currency_Code__c === 'GTQ' ){
                        this.total += line.Quantity__c * line.Purchase_Order_Line__r.Quote_Line__r.Product__r.Price_GTQ__c;
                    } else {
                        this.total += line.Quantity__c * line.Purchase_Order_Line__r.Quote_Line__r.Product__r.Price_USD__c;
                    }
                });
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

    @api async save(){
        const nit = this.accountNIT;
        let invoice = {...this.invoice};
        invoice.Dispatch_Orders__c = this.stringify(invoice.Dispatch_Orders__c);
        invoice.Partial_Payments__c = this.stringify(invoice.Partial_Payments__c);
        invoice.Date__c = new Date(invoice.Date__c);
        invoice.Is_EInvoice__c = invoice.Is_EInvoice__c === "Si";
        
        if (this.isInvalid()){
            return;
        }

        try {
            this.isLoading = true;
            const companyInfo = this.info.companyInfo;
            const clientLegalInfo = await getClientLegalInformation({ nit, companyInfo});
            clientLegalInfo.legalName = clientLegalInfo.legalName.replace("{0}", "");
            clientLegalInfo.legalName = clientLegalInfo.legalName.replace("{1}", "");
            clientLegalInfo.legalName = clientLegalInfo.legalName.replace("{2}", "");
            clientLegalInfo.legalName = clientLegalInfo.legalName.replace("{3}", "");
            clientLegalInfo.legalName = clientLegalInfo.legalName.replace("{4}", "");
            console.log('Client Legal Name: ', clientLegalInfo.legalName);
            console.log('Client Legal Address: ', clientLegalInfo.legalAddress);

            const xml = this.generateXML(clientLegalInfo);
            console.log('xml: ', {xml});

            const wrapper = await getInvoiceWrapper({invoice, xml});
            const xmlEncoded = wrapper.xmlEncoded;
            console.log('Wrapper: ', JSON.parse(JSON.stringify(wrapper)));
            
            const isAnulation = false;
            const signInvoiceResponse = await signInvoice({ xmlEncoded, companyInfo, isAnulation});

            if (!signInvoiceResponse){
                throw '';
            } else if ( signInvoiceResponse.resultado === false ){
                throw {
                    body: {
                        message: signInvoiceResponse.descripcion
                    }
                };
            }

            const xmlSignedEncoded = signInvoiceResponse.archivo;
            console.log('xmlSignedEncoded: ', {xmlSignedEncoded});


            
            const certificateId = this.generateId();
            const email = invoice.Email__c;
            const processInvoiceResponse = await processInvoice({ xmlSignedEncoded, companyInfo, email, certificateId, isAnulation });
            console.log('Certify Invoice response: ', processInvoiceResponse);

            if (processInvoiceResponse.cantidad_errores === 0) {
                wrapper.invoice.External_UUID__c = processInvoiceResponse.uuid;
                wrapper.invoice.External_Serie__c = processInvoiceResponse.serie;
                wrapper.invoice.External_Number__c = processInvoiceResponse.numero;
                
                const Id = await insertInvoiceApex({ 
                    invoice : wrapper.invoice,
                    purchaseOrder : wrapper.purchaseOrder,
                    dispatchOrders : wrapper.dispatchOrders
                });
                
                console.log('Invoice Id: ', Id);
                this.dispatchEvent(new ShowToastEvent({
                    title: '',
                    message: 'Factura generada con éxito.',
                    variant: 'success'
                }));
            } else {
                processInvoiceResponse.descripcion_errores.forEach( error => {
                    this.dispatchError(error.mensaje_error);
                });
            }
        } catch (error){
            const message = error.body && error.body.message ?  error.body.message : 'La factura no pudo ser generada con éxito, por favor intente de nuevo.';
            this.dispatchError(message);
        } finally {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('cancel'));
        }
    }

    dispatchError(message){
        console.error(message);
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
        if (this.isCambiaria){
            if( !this.invoice.Partial_Payments__c.length){
                result = "Debe de ingresar al menos un abono.";
            } else {
                const partialPaymentTotal = this.invoice.Partial_Payments__c.reduce((total, payment) => total + parseFloat(payment.paymentAmount), 0) ;
                if ( partialPaymentTotal > this.total) {
                    result = "La suma de los montos de los abonos no puede sobrepasar el monto total de la factura."
                }
            }
        }

        if (result){
            this.dispatchError(result);
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

    generateXML(clientLegalInfo){
        const invoice = {...this.invoice};
        const info = {... this.info};

        let type = '';
        if ( invoice.Type__c === 'Estandard' ) {
            type = 'FACT'
        } else if ( invoice.Type__c === 'Cambiaria' ) {
            type = 'FCAM'
        }

        const dispatchOrderAdenda = invoice.Dispatch_Orders__c && this.dispatchOrderOptions ?
            invoice.Dispatch_Orders__c.map(order => {
                return this.dispatchOrderOptions.find(item => item.value === order).label
            }).join(", ") : '';
        const contado = info.quote.Credit__c ? '' : 'x';
        const credito = info.quote.Credit__c ? 'x' : '';;
        const vendedor = info.purchaseOrder.Quote__r.Sales_User__c ? info.purchaseOrder.Quote__r.Sales_User__c : '';
        const telefono = info.purchaseOrder.Account__r.Phone ? info.purchaseOrder.Account__r.Phone : '';
        const ordenDeCompra = info.purchaseOrder.Order_Id__c ? info.purchaseOrder.Order_Id__c : '';
        const formaDePago = info.purchaseOrder.Quote__r.Payment__c ? info.purchaseOrder.Quote__r.Payment__c : '';

        const invoiceDateTime = invoice.Date__c.split('-').map((val,i)=> { 
            return i > 0 && val.length === 1 ? '0' + val : val;
        }).join('-') + 'T00:00:00-06:00';

        let xml =
        `
<dte:GTDocumento xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:dte="http://www.sat.gob.gt/dte/fel/0.2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Version="0.1" xsi:schemaLocation="http://www.sat.gob.gt/dte/fel/0.2.0">
    <dte:SAT ClaseDocumento="dte">
        <dte:DTE ID="DatosCertificados">
            <dte:DatosEmision ID="DatosEmision">
                <dte:DatosGenerales CodigoMoneda="${invoice.Currency_Code__c}" FechaHoraEmision="${invoiceDateTime}" Tipo="${type}"></dte:DatosGenerales>
                <dte:Emisor AfiliacionIVA="GEN" CodigoEstablecimiento="1" CorreoEmisor="demo@demo.com.gt" NITEmisor="${info.companyInfo.Infile_NIT__c.replace('-','')}" NombreComercial="${info.companyInfo.Label}" NombreEmisor="${info.companyInfo.Legal_Name__c}">
                    <dte:DireccionEmisor>
                        <dte:Direccion>${info.companyInfo.Address__c}</dte:Direccion>
                        <dte:CodigoPostal>01001</dte:CodigoPostal>
                        <dte:Municipio>GUATEMALA</dte:Municipio>
                        <dte:Departamento>GUATEMALA</dte:Departamento>
                        <dte:Pais>GT</dte:Pais>
                    </dte:DireccionEmisor>
                </dte:Emisor>
                <dte:Receptor CorreoReceptor="${invoice.Email__c}" IDReceptor="${this.accountNIT}" NombreReceptor="${clientLegalInfo.legalName}">
                    <dte:DireccionReceptor>
                        <dte:Direccion>${clientLegalInfo.legalAddress}</dte:Direccion>
                        <dte:CodigoPostal>01001</dte:CodigoPostal>
                        <dte:Municipio>GUATEMALA</dte:Municipio>
                        <dte:Departamento>GUATEMALA</dte:Departamento>
                        <dte:Pais>GT</dte:Pais>
                    </dte:DireccionReceptor>
                </dte:Receptor>
                <dte:Frases>
                    <dte:Frase CodigoEscenario="1" TipoFrase="1"></dte:Frase>
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

        if (type === 'FCAM' && invoice.Partial_Payments__c && invoice.Partial_Payments__c.length){
            xml += `
                <dte:Complementos>
                    <dte:Complemento IDComplemento="Cambiaria" NombreComplemento="Cambiaria" URIComplemento="http://www.sat.gob.gt/fel/cambiaria.xsd">
                        <cfc:AbonosFacturaCambiaria xmlns:cfc="http://www.sat.gob.gt/dte/fel/CompCambiaria/0.1.0" Version="1" xsi:schemaLocation="http://www.sat.gob.gt/dte/fel/CompCambiaria/0.1.0 C:\Users\Desktop\SAT_FEL_FINAL_V1\Esquemas\GT_Complemento_Cambiaria-0.1.0.xsd">  
            `;
            invoice.Partial_Payments__c.forEach(payment => {
                xml +=
                `
                            <cfc:Abono>
                                <cfc:NumeroAbono>${payment.paymentName}</cfc:NumeroAbono>
                                <cfc:FechaVencimiento>${payment.paymentDate}</cfc:FechaVencimiento>
                                <cfc:MontoAbono>${payment.paymentAmount}</cfc:MontoAbono>
                            </cfc:Abono>
                `;
            });
            xml += `
                        </cfc:AbonosFacturaCambiaria>
                    </dte:Complemento>
                </dte:Complementos>
            `;
        }

        xml +=
        `
            </dte:DatosEmision>
        </dte:DTE>
        <dte:Adenda>
            <Vendedor>${vendedor}</Vendedor>
            <Telefono>${telefono}</Telefono>
            <OrdenDeCompra>${ordenDeCompra}</OrdenDeCompra>
            <OrdenDeEnvio>${dispatchOrderAdenda}</OrdenDeEnvio>
            <Contado>${contado}</Contado>
            <Credito>${credito}</Credito>
            <FormaDePago>${formaDePago}</FormaDePago>
        </dte:Adenda>
    </dte:SAT>
</dte:GTDocumento>
        `;

        return xml;
    }
}