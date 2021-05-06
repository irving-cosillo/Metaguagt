import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cancelInvoiceApex from '@salesforce/apex/ClassInvoice.cancelInvoiceApex';
import processInvoice from '@salesforce/apex/ClassInvoice.processInvoice';
import signInvoice from '@salesforce/apex/ClassInvoice.signInvoice';
import getInvoiceInformation from '@salesforce/apex/ClassInvoice.getInvoiceInformation';

export default class LwcInvoiceCancellation extends LightningElement {
    @api recordId;

    cancellationReason = '';
    isLoading = false;

    cancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    fieldChange(event){
        this.cancellationReason = event.target.value;
    }

    async save(){
        try {
            this.isLoading = true;
            const invoiceId = this.recordId;
            const cancellationReason = this.cancellationReason;
            const info = await getInvoiceInformation({invoiceId});
            console.log('info: ', info);

            const companyInfo = info.companyInfo;
            const xml = this.generateXML(info);
            console.log('xml: ', {xml});

            const xmlEncoded = window.btoa(xml);
            console.log('xmlEncoded: ', {xmlEncoded});

            const isAnulation = true;
            console.log({ xmlEncoded, companyInfo, isAnulation});
            const signInvoiceResponse = await signInvoice({ xmlEncoded, companyInfo, isAnulation});
            console.log('signInvoiceResponse: ', signInvoiceResponse);

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

            const email = companyInfo.Invoice_Email__c;
            const certificateId = this.generateId();
            const processInvoiceResponse = await processInvoice({ xmlSignedEncoded, companyInfo, email, certificateId, isAnulation });
            console.log('Certify Invoice response: ', processInvoiceResponse);
            
            if (!processInvoiceResponse){
                throw '';
            } else if ( processInvoiceResponse.resultado === false ){
                throw {
                    body: {
                        message: processInvoiceResponse.descripcion
                    }
                };
            }
            
            await cancelInvoiceApex({ invoiceId, cancellationReason})
            this.cancel();
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'La factura fue anulada con éxito',
                variant: 'success'
            }));
        } catch(error){
            this.isLoading = false;
            const message = error.body && error.body.message ?  error.body.message : 
            'La factura no pudo ser anulada con éxito, por favor intente de nuevo.';
            console.error(message);
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message,
                variant: 'error'
            }));
        }
    }

    formatDate(date){
        return date.split('-').map((val,i)=> { 
            return i > 0 && val.length === 1 ? '0' + val : val;
        }).join('-') + 'T00:00:00-06:00';
    }

    generateXML(info){
        const today = new Date();
        const todayDate = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
        const anulationDate = this.formatDate(todayDate);
        const emisionDate = this.formatDate(info.invoice.Date__c);

        const nitEmisor = info.companyInfo.Infile_NIT__c;
        const documentNumber = info.invoice.External_UUID__c;
        const accountNIT = info.invoice.Purchase_Order__r.Account__r.NIT__c;

        return `
            <dte:GTAnulacionDocumento xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:dte="http://www.sat.gob.gt/dte/fel/0.1.0" xmlns:n1="http://www.altova.com/samplexml/other-namespace" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Version="0.1" xsi:schemaLocation="http://www.sat.gob.gt/dte/fel/0.1.0">
                <dte:SAT>
                    <dte:AnulacionDTE ID="DatosCertificados">
                        <dte:DatosGenerales FechaEmisionDocumentoAnular="${emisionDate}" FechaHoraAnulacion="${anulationDate}" ID="DatosAnulacion" IDReceptor="${accountNIT}" MotivoAnulacion="${this.cancellationReason}" NITEmisor="${nitEmisor}" NumeroDocumentoAAnular="${documentNumber}"></dte:DatosGenerales>
                    </dte:AnulacionDTE>
                </dte:SAT>
            </dte:GTAnulacionDocumento>
        `;
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