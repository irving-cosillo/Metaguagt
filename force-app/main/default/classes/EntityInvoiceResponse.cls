public class EntityInvoiceResponse {
    @AuraEnabled
    public Boolean resultado;
    @AuraEnabled
    public String fecha;
    @AuraEnabled
    public String origen;
    @AuraEnabled
    public String descripcion;
    /*
    @AuraEnabled
    public EntityInvoiceResponse.ControlEmision control_emision;
    @AuraEnabled
    public Boolean alertas_infile;
    @AuraEnabled
    public Boolean alertas_sat;
    */
    
    @AuraEnabled
    public Integer cantidad_errores;
    @AuraEnabled
    public List<Error> descripcion_errores;
    @AuraEnabled
    public String informacion_adicional;
    @AuraEnabled
    public String uuid;
    @AuraEnabled
    public String serie;
    @AuraEnabled
    public String numero;
    @AuraEnabled
    public String xml_certificado;

    /*
    public class ControlEmision {
        @AuraEnabled
        public String Saldo;
        @AuraEnabled
        public String Creditos;
    }
    */

    public class Error {
        @AuraEnabled
        public Boolean resultado;
        @AuraEnabled
        public String fuente;
        @AuraEnabled
        public String categoria;
        @AuraEnabled
        public String numeral;
        @AuraEnabled
        public String validacion;
        @AuraEnabled
        public String mensaje_error;
    }
}

/*
String bodyResponse = '';
bodyResponse += '{';
bodyResponse += '    "resultado":false,';
bodyResponse += '    "fecha":"2021-04-16T09:54:54-06:00",';
bodyResponse += '    "origen":"Validaciones XML Segun FEL Reglas y Validaciones Versión 1.4 | Junio 2020 | Acuerdo de Directorio SAT 13-2018",';
bodyResponse += '    "descripcion":"No es posible completar tu solicitud. Nuestro equipo de soporte esta en la mejor disposicion de apoyarte, por favor reportanos este caso. [3]",';
bodyResponse += '    "control_emision":{';
bodyResponse += '        "Saldo":0,';
bodyResponse += '        "Creditos":0';
bodyResponse += '    },';
bodyResponse += '    "alertas_infile":false,';
bodyResponse += '    "descripcion_alertas_infile":[],';
bodyResponse += '    "alertas_sat":false,';
bodyResponse += '    "descripcion_alertas_sat":[],';
bodyResponse += '    "cantidad_errores":1,';
bodyResponse += '    "descripcion_errores":[';
bodyResponse += '        {';
bodyResponse += '           "resultado":false,';
bodyResponse += '            "fuente":"Validaciones del Sistema",';
bodyResponse += '           "categoria":"0",';
bodyResponse += '            "numeral":"0",';
bodyResponse += '            "validacion":"0",';
bodyResponse += '            "mensaje_error":"ERRID: [590aaf72bcb5fc7b89df3e0c79bae7b3] Codigo: [3] Para obtener mas informacion envie un correo a soporte tecnico y en el cuerpo del correo incluya este mensaje de respuesta. Su comunicacion es muy importante para nosotros."';
bodyResponse += '        }';
bodyResponse += '    ],';
bodyResponse += '    "informacion_adicional":"transaccion: , sysid: 590aaf72bcb5fc7b89df3e0c79bae7b3 Nodo: 9d970fbc-b387-4be8-ac00-cef194f3909e",';
bodyResponse += '    "uuid":"",';
bodyResponse += '    "serie":"",';
bodyResponse += '    "numero":"",';
bodyResponse += '    "xml_certificado":""';
bodyResponse += '}';
EntityInvoiceResponse invoiceResponse = (EntityInvoiceResponse) System.JSON.deserialize(bodyResponse, EntityInvoiceResponse.class);
//System.debug(invoiceResponse.cantidad_errores);
*/