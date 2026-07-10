"""
Kadaster Connector (PDOK API)
"""

from typing import Dict, Any, Optional
from .base import BaseConnector
from ..models import KadasterData, AddressQuery, Coordinates
from ..config import config
import structlog

logger = structlog.get_logger()


class KadasterConnector(BaseConnector):
    """Connector voor Kadaster PDOK API"""
    
    def __init__(self):
        super().__init__(
            base_url=config.kadaster_api_url,
            api_key=config.kadaster_api_key
        )
    
    def fetch_data(
        self, 
        query: AddressQuery = None,
        coordinates: Coordinates = None
    ) -> Optional[KadasterData]:
        """
        Haal kadaster data op voor een adres of coördinaat
        """
        try:
            if coordinates:
                return self._fetch_by_coordinates(coordinates)
            elif query:
                return self._fetch_by_address(query)
            else:
                logger.error("kadaster_geen_query_of_coords")
                return None
                
        except Exception as e:
            logger.error("kadaster_fetch_error", error=str(e))
            return None
    
    def _fetch_by_address(self, query: AddressQuery) -> Optional[KadasterData]:
        """Haal kadaster data op via adres (vereist eerst coördinaten)"""
        # Voor kadaster hebben we coördinaten nodig
        # Dit zou normaal via BAG connector gehaald worden
        logger.warning(
            "kadaster_address_lookup_requires_coordinates",
            msg="Use coordinates from BAG data for kadaster lookup"
        )
        return None
    
    def _fetch_by_coordinates(self, coords: Coordinates) -> Optional[KadasterData]:
        """Haal kadaster data op via coördinaten"""
        try:
            # Gebruik PDOK Locatieserver voor kadastraal perceel
            params = {
                'lat': coords.latitude,
                'lon': coords.longitude,
                'type': 'perceel'
            }
            
            response = self._make_request(
                'GET',
                'locatieserver/v3/lookup',
                params=params
            )
            
            if not response or 'response' not in response:
                return None
            
            docs = response['response'].get('docs', [])
            if not docs:
                return None
            
            perceel = docs[0]
            
            return KadasterData(
                kadastraal_object_id=perceel.get('id'),
                perceeloppervlakte=perceel.get('perceeloppervlakte'),
                eigendomssituatie=perceel.get('eigendomssituatie'),
                zakelijke_rechten=perceel.get('zakelijkerechten', []),
                gemeente_code=perceel.get('gemeentecode'),
                sectie=perceel.get('sectie'),
                perceelnummer=perceel.get('perceelnummer')
            )
            
        except Exception as e:
            logger.error("kadaster_coords_lookup_error", error=str(e))
            return None
    
    def get_eigendom_info(self, kadastraal_object_id: str) -> Optional[Dict[str, Any]]:
        """
        Haal eigendomsinformatie op (vereist authenticatie)
        Dit is premium data en vereist een API key
        """
        if not self.api_key:
            logger.warning("kadaster_eigendom_requires_api_key")
            return None
        
        try:
            return self._make_request(
                'GET',
                f'brk/api/v1/kadastraalonroerendezaken/{kadastraal_object_id}'
            )
        except Exception as e:
            logger.error("kadaster_eigendom_error", error=str(e))
            return None
