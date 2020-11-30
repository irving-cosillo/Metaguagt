//Generated by FuseIT WSDL2Apex (http://www.fuseit.com/Solutions/SFDC-Explorer/Help-WSDL-Parser.aspx)

@isTest
public class servicesWsIngfaceComMockImpl implements WebServiceMock {
	public void doInvoke(
			Object stub,
			Object request,
			Map<String, Object> response,
			String endpoint,
			String soapAction,
			String requestName,
			String responseNS,
			String responseName,
			String responseType) {
       
		System.debug(LoggingLevel.INFO, 'servicesWsIngfaceComMockImpl.doInvoke() - ' +
			'\n request: ' + request +
			'\n response: ' + response +
			'\n endpoint: ' + endpoint +
			'\n soapAction: ' + soapAction +
			'\n requestName: ' + requestName +
			'\n responseNS: ' + responseNS +
			'\n responseName: ' + responseName +
			'\n responseType: ' + responseType);

		if(request instanceOf servicesWsIngfaceCom.eliminaEstablecimiento) {
			response.put( 'response_x', new servicesWsIngfaceCom.eliminaEstablecimientoResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.eliminaSerie) {
			response.put( 'response_x', new servicesWsIngfaceCom.eliminaSerieResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.eliminDispositivo) {
			response.put( 'response_x', new servicesWsIngfaceCom.eliminDispositivoResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.enviarDispositivo) {
			response.put( 'response_x', new servicesWsIngfaceCom.enviarDispositivoResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.enviarEface) {
			response.put( 'response_x', new servicesWsIngfaceCom.enviarEfaceResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.enviarEstablecimiento) {
			response.put( 'response_x', new servicesWsIngfaceCom.enviarEstablecimientoResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.enviaSerie) {
			response.put( 'response_x', new servicesWsIngfaceCom.enviaSerieResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.getSeries) {
			response.put( 'response_x', new servicesWsIngfaceCom.getSeriesResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.hello) {
			response.put( 'response_x', new servicesWsIngfaceCom.helloResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.modificarDispositivo) {
			response.put( 'response_x', new servicesWsIngfaceCom.modificarDispositivoResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.modificarEstablecimiento) {
			response.put( 'response_x', new servicesWsIngfaceCom.modificarEstablecimientoResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.modificarSerie) {
			response.put( 'response_x', new servicesWsIngfaceCom.modificarSerieResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.nitContribuyentes) {
			response.put( 'response_x', new servicesWsIngfaceCom.nitContribuyentesResponse());
		}
		else if(request instanceOf servicesWsIngfaceCom.verificaDocumentos) {
			response.put( 'response_x', new servicesWsIngfaceCom.verificaDocumentosResponse());
		}
	}
}