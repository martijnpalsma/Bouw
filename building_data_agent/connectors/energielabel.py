"""
Energielabel Connector (EP-Online API)
"""

from typing import Dict, Any, Optional
from .base import BaseConnector
from ..models import EnergielabelData, AddressQuery
from ..config import config
import structlog

logger = structlog.get_logger()


class EnergielabelConnector(BaseConnector):
    """Connector voor Energielabel API (EP-Online)"""
    
    def __init__(self):
        super().__init__(
            base_url=config.energielabel_api_url
        )
    
    def fetch_data(self, query: AddressQuery) -> Optional[EnergielabelData]:
        """Haal energielabel data op voor een adres"""
        try:
            # Zoek energielabel op basis van adres
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
                'energielabel',
                params=params
            )
            
            if not response or 'energielabels' not in response:
                logger.warning("energielabel_niet_gevonden", query=query.model_dump())
                return None
            
            labels = response.get('energielabels', [])
            if not labels:
                return None
            
            # Neem het meest recente label
            label_data = labels[0]
            
            return EnergielabelData(
                label=label_data.get('labelLetter'),
                label_geldig_tot=label_data.get('opnameGeldigTot'),
                opnamedatum=label_data.get('opnameDatum'),
                energieindex=label_data.get('energieindex'),
                energiebehoefte=label_data.get('energiebehoefte'),
                eis_energiebehoefte=label_data.get('eisEnergiebehoeffte'),
                energieklasse=label_data.get('energieklasse'),
                gebouwtype=label_data.get('gebouwtype'),
                gebouwsubtype=label_data.get('gebouwsubtype'),
                meting_geldig=label_data.get('metingGeldig', False)
            )
            
        except Exception as e:
            logger.error("energielabel_fetch_error", error=str(e), query=query.model_dump())
            return None
    
    def get_label_details(self, pand_id: str) -> Optional[Dict[str, Any]]:
        """Haal gedetailleerde energielabel informatie op"""
        try:
            return self._make_request(
                'GET',
                f'energielabel/{pand_id}'
            )
        except Exception as e:
            logger.error("energielabel_details_error", error=str(e), pand_id=pand_id)
            return None
