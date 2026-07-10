"""
Basis connector klasse voor data bronnen
"""

import requests
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from ..config import config
import structlog

logger = structlog.get_logger()


class BaseConnector(ABC):
    """Basis klasse voor alle data connectors"""
    
    def __init__(self, base_url: str, api_key: Optional[str] = None):
        self.base_url = base_url
        self.api_key = api_key
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({"X-Api-Key": api_key})
        
        self.session.headers.update({
            "User-Agent": "BuildingDataAgent/1.0",
            "Accept": "application/json"
        })
    
    def _make_request(
        self, 
        method: str, 
        endpoint: str, 
        params: Optional[Dict[str, Any]] = None,
        json_data: Optional[Dict[str, Any]] = None,
        timeout: Optional[int] = None
    ) -> Dict[str, Any]:
        """Maak een HTTP request"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        timeout = timeout or config.request_timeout
        
        try:
            logger.info(
                "making_api_request",
                method=method,
                url=url,
                params=params
            )
            
            response = self.session.request(
                method=method,
                url=url,
                params=params,
                json=json_data,
                timeout=timeout
            )
            
            response.raise_for_status()
            
            logger.info(
                "api_request_success",
                status_code=response.status_code,
                url=url
            )
            
            return response.json() if response.content else {}
            
        except requests.exceptions.HTTPError as e:
            logger.error(
                "api_request_failed",
                error=str(e),
                status_code=e.response.status_code if e.response else None,
                url=url
            )
            raise
        except requests.exceptions.RequestException as e:
            logger.error(
                "api_request_exception",
                error=str(e),
                url=url
            )
            raise
    
    @abstractmethod
    def fetch_data(self, **kwargs) -> Dict[str, Any]:
        """Haal data op - moet geïmplementeerd worden door subklassen"""
        pass
    
    def health_check(self) -> bool:
        """Check of de API bereikbaar is"""
        try:
            response = self.session.get(self.base_url, timeout=5)
            return response.status_code < 500
        except:
            return False
