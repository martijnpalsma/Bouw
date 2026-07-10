"""
BAG (Basisregistratie Adressen en Gebouwen) Connector
"""

from typing import Dict, Any, Optional
from .base import BaseConnector
from ..models import BAGData, Coordinates, AddressQuery
from ..config import config
import structlog

logger = structlog.get_logger()


class BAGConnector(BaseConnector):
    """Connector voor BAG API"""
    
    def __init__(self):
        super().__init__(
            base_url=config.bag_api_url,
            api_key=config.bag_api_key
        )
    
    def fetch_data(self, query: AddressQuery) -> Optional[BAGData]:
        """Haal BAG data op voor een adres"""
        try:
            # Stap 1: Zoek adresseerbaar object
            adres_data = self._zoek_adres(query)
            if not adres_data:
                logger.warning("bag_adres_niet_gevonden", query=query.model_dump())
                return None
            
            # Stap 2: Haal verblijfsobject details op
            verblijfsobject_id = adres_data.get('identificatie')
            if not verblijfsobject_id:
                return None
            
            verblijfsobject = self._get_verblijfsobject(verblijfsobject_id)
            
            # Stap 3: Haal pand details op
            pand_id = verblijfsobject.get('pandIdentificaties', [None])[0]
            pand_data = None
            if pand_id:
                pand_data = self._get_pand(pand_id)
            
            # Construeer BAGData object
            return self._construct_bag_data(adres_data, verblijfsobject, pand_data)
            
        except Exception as e:
            logger.error("bag_fetch_error", error=str(e), query=query.model_dump())
            return None
    
    def _zoek_adres(self, query: AddressQuery) -> Optional[Dict[str, Any]]:
        """Zoek een adres in de BAG"""
        params = {
            'postcode': query.postcode,
            'huisnummer': query.huisnummer,
        }
        
        if query.huisletter:
            params['huisletter'] = query.huisletter
        if query.toevoeging:
            params['huisnummertoevoeging'] = query.toevoeging
        
        try:
            response = self._make_request(
                'GET',
                'adressen',
                params=params
            )
            
            adressen = response.get('_embedded', {}).get('adressen', [])
            return adressen[0] if adressen else None
            
        except Exception as e:
            logger.error("bag_zoek_adres_error", error=str(e))
            return None
    
    def _get_verblijfsobject(self, identificatie: str) -> Dict[str, Any]:
        """Haal verblijfsobject details op"""
        return self._make_request(
            'GET',
            f'adresseerbareobjecten/{identificatie}'
        )
    
    def _get_pand(self, pand_id: str) -> Dict[str, Any]:
        """Haal pand details op"""
        try:
            return self._make_request(
                'GET',
                f'panden/{pand_id}'
            )
        except Exception as e:
            logger.error("bag_get_pand_error", error=str(e), pand_id=pand_id)
            return {}
    
    def _construct_bag_data(
        self,
        adres_data: Dict[str, Any],
        verblijfsobject: Dict[str, Any],
        pand_data: Optional[Dict[str, Any]]
    ) -> BAGData:
        """Construeer BAGData object uit API responses"""
        
        # Coördinaten
        coords = None
        geometrie = verblijfsobject.get('geometrie', {})
        if geometrie and 'punt' in geometrie:
            punt = geometrie['punt']
            coords = Coordinates(
                latitude=punt.get('coordinates', [0, 0])[1],
                longitude=punt.get('coordinates', [0, 0])[0]
            )
        
        # Adres onderdelen
        openbare_ruimte = adres_data.get('openbareRuimteNaam', '')
        woonplaats = adres_data.get('woonplaatsNaam', '')
        
        return BAGData(
            verblijfsobject_id=verblijfsobject.get('identificatie'),
            pand_id=pand_data.get('identificatie') if pand_data else None,
            oppervlakte=verblijfsobject.get('oppervlakte'),
            bouwjaar=pand_data.get('oorspronkelijkBouwjaar') if pand_data else None,
            status=verblijfsobject.get('status'),
            gebruiksdoel=verblijfsobject.get('gebruiksdoelen', []),
            aantal_kamers=verblijfsobject.get('aantalKamers'),
            coordinates=coords,
            straat=openbare_ruimte,
            woonplaats=woonplaats,
            gemeente=adres_data.get('gemeenteNaam'),
            provincie=None  # Niet direct beschikbaar in BAG API
        )
