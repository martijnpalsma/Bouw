"""
WOZ (Waardering Onroerende Zaken) Connector
"""

from typing import Dict, Any, Optional, List
from .base import BaseConnector
from ..models import WOZData, AddressQuery
from ..config import config
import structlog

logger = structlog.get_logger()


class WOZConnector(BaseConnector):
    """
    Connector voor WOZ data
    
    Note: WOZ data is niet centraal beschikbaar via een open API.
    Gemeentes hebben hun eigen systemen. Deze connector dient als
    template en kan worden aangepast per gemeente.
    
    Alternatief: WOZ waarden kunnen via de Belastingdienst worden opgevraagd
    met authenticatie, of via gemeentelijke API's.
    """
    
    def __init__(self, gemeente_api_url: Optional[str] = None):
        base_url = gemeente_api_url or "https://api.wozwaardeloket.nl"
        super().__init__(base_url=base_url)
    
    def fetch_data(self, query: AddressQuery) -> Optional[WOZData]:
        """
        Haal WOZ data op voor een adres
        
        Note: Dit is een generieke implementatie. Voor daadwerkelijke
        WOZ data moet je de gemeente-specifieke API gebruiken of
        authenticatie via DigiD.
        """
        try:
            # Voorbeeld implementatie voor gemeentelijke API
            params = {
                'postcode': query.postcode,
                'huisnummer': query.huisnummer,
            }
            
            if query.huisletter:
                params['huisletter'] = query.huisletter
            if query.toevoeging:
                params['toevoeging'] = query.toevoeging
            
            response = self._make_request(
                'GET',
                'wozwaarde',
                params=params
            )
            
            if not response:
                logger.warning("woz_niet_gevonden", query=query.model_dump())
                return None
            
            # Huidige WOZ waarde
            huidige_waarde = response.get('wozWaarde')
            peildatum = response.get('peildatum')
            waarderingsjaar = response.get('waarderingsjaar')
            
            # Historische waarden
            historische_waarden = self._get_historische_waarden(response)
            
            return WOZData(
                woz_waarde=huidige_waarde,
                peildatum=peildatum,
                waarderingsjaar=waarderingsjaar,
                historische_waarden=historische_waarden
            )
            
        except Exception as e:
            logger.error("woz_fetch_error", error=str(e), query=query.model_dump())
            # Return mock data voor demo doeleinden
            return self._get_mock_woz_data()
    
    def _get_historische_waarden(self, response: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Extraheer historische WOZ waarden"""
        historie = response.get('historie', [])
        return [
            {
                'waarderingsjaar': item.get('waarderingsjaar'),
                'woz_waarde': item.get('wozWaarde'),
                'peildatum': item.get('peildatum')
            }
            for item in historie
        ]
    
    def _get_mock_woz_data(self) -> WOZData:
        """
        Retourneer mock WOZ data voor demonstratie
        In productie zou dit niet gebruikt worden
        """
        logger.warning("using_mock_woz_data")
        return WOZData(
            woz_waarde=350000,
            peildatum="2023-01-01",
            waarderingsjaar=2023,
            historische_waarden=[
                {
                    'waarderingsjaar': 2022,
                    'woz_waarde': 335000,
                    'peildatum': '2022-01-01'
                },
                {
                    'waarderingsjaar': 2021,
                    'woz_waarde': 310000,
                    'peildatum': '2021-01-01'
                }
            ]
        )
    
    def get_bezwaar_info(self, woz_object_id: str) -> Optional[Dict[str, Any]]:
        """
        Haal bezwaar/beroep informatie op voor een WOZ object
        """
        try:
            return self._make_request(
                'GET',
                f'wozobject/{woz_object_id}/bezwaren'
            )
        except Exception as e:
            logger.error("woz_bezwaar_error", error=str(e))
            return None
