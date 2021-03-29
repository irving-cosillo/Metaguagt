public class EntityInvoiceResponse {
    @AuraEnabled
    public Boolean resultado;
    @AuraEnabled
    public String fecha;
    @AuraEnabled
    public String origen;
    @AuraEnabled
    public String descripcion;
    @AuraEnabled
    public EntityInvoiceResponse.ControlEmision control_emision;
    @AuraEnabled
    public Boolean alertas_infile;
    //Falta descripcion_alertas_infile
    @AuraEnabled
    public Boolean alertas_sat;
    //Falta descripcion_alertas_sat
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
    public Integer numero;
    @AuraEnabled
    public String xml_certificado;

    public class ControlEmision {
        @AuraEnabled
        public String Saldo;
        @AuraEnabled
        public String Creditos;
    }

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
