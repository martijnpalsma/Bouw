"""
Building Data Agent - Hoofdklasse
"""

from typing import Optional, List, Dict, Any
import concurrent.futures
from datetime import datetime

from .models import (
    AddressQuery, 
    BuildingData, 
    ValuationReport,
    BAGData,
    WOZData,
    KadasterData,
    EnergielabelData
)
from .connectors import (
    BAGConnector,
    WOZConnector,
    KadasterConnector,
    EnergielabelConnector
)
from .config import config
import structlog

logger = structlog.get_logger()


class BuildingDataAgent:
    """
    Hoofd agent voor het ophalen van gebouwtaxatie en inspectie data
    """
    
    def __init__(
        self,
        enable_bag: bool = True,
        enable_woz: bool = True,
        enable_kadaster: bool = True,
        enable_energielabel: bool = True,
    ):
        """
        Initialiseer de Building Data Agent
        
        Args:
            enable_bag: Schakel BAG connector in
            enable_woz: Schakel WOZ connector in
            enable_kadaster: Schakel Kadaster connector in
            enable_energielabel: Schakel Energielabel connector in
        """
        self.enable_bag = enable_bag
        self.enable_woz = enable_woz
        self.enable_kadaster = enable_kadaster
        self.enable_energielabel = enable_energielabel
        
        # Initialiseer connectors
        self.bag_connector = BAGConnector() if enable_bag else None
        self.woz_connector = WOZConnector() if enable_woz else None
        self.kadaster_connector = KadasterConnector() if enable_kadaster else None
        self.energielabel_connector = EnergielabelConnector() if enable_energielabel else None
        
        logger.info(
            "building_data_agent_initialized",
            enabled_sources={
                'bag': enable_bag,
                'woz': enable_woz,
                'kadaster': enable_kadaster,
                'energielabel': enable_energielabel
            }
        )
    
    def get_building_data(
        self,
        postcode: str,
        huisnummer: int,
        huisletter: Optional[str] = None,
        toevoeging: Optional[str] = None
    ) -> BuildingData:
        """
        Haal gebouwdata op voor een adres
        
        Args:
            postcode: Postcode (bijv. "1012JS")
            huisnummer: Huisnummer
            huisletter: Huisletter (optioneel)
            toevoeging: Toevoeging (optioneel)
            
        Returns:
            BuildingData object met alle verzamelde data
        """
        query = AddressQuery(
            postcode=postcode,
            huisnummer=huisnummer,
            huisletter=huisletter,
            toevoeging=toevoeging
        )
        
        return self.fetch_all_data(query)
    
    def fetch_all_data(self, query: AddressQuery) -> BuildingData:
        """
        Haal alle data op voor een adres query
        
        Args:
            query: AddressQuery object
            
        Returns:
            BuildingData object met alle verzamelde data
        """
        logger.info("fetching_all_building_data", query=query.model_dump())
        
        building_data = BuildingData(query=query)
        data_sources = []
        
        # Haal BAG data op (altijd eerst, voor coördinaten)
        if self.enable_bag and self.bag_connector:
            logger.info("fetching_bag_data")
            bag_data = self.bag_connector.fetch_data(query)
            if bag_data:
                building_data.bag_data = bag_data
                data_sources.append('BAG')
        
        # Haal overige data op (parallel indien mogelijk)
        if config.batch_parallel:
            building_data = self._fetch_parallel(query, building_data)
        else:
            building_data = self._fetch_sequential(query, building_data)
        
        # Update welke bronnen gebruikt zijn
        if building_data.woz_data:
            data_sources.append('WOZ')
        if building_data.kadaster_data:
            data_sources.append('Kadaster')
        if building_data.energielabel_data:
            data_sources.append('Energielabel')
        
        building_data.data_sources_used = data_sources
        
        logger.info(
            "building_data_fetched",
            sources_used=data_sources,
            query=query.model_dump()
        )
        
        return building_data
    
    def _fetch_sequential(
        self, 
        query: AddressQuery, 
        building_data: BuildingData
    ) -> BuildingData:
        """Haal data sequentieel op"""
        
        # WOZ
        if self.enable_woz and self.woz_connector:
            logger.info("fetching_woz_data")
            woz_data = self.woz_connector.fetch_data(query)
            if woz_data:
                building_data.woz_data = woz_data
        
        # Kadaster (gebruik coördinaten van BAG)
        if self.enable_kadaster and self.kadaster_connector and building_data.bag_data:
            logger.info("fetching_kadaster_data")
            kadaster_data = self.kadaster_connector.fetch_data(
                coordinates=building_data.bag_data.coordinates
            )
            if kadaster_data:
                building_data.kadaster_data = kadaster_data
        
        # Energielabel
        if self.enable_energielabel and self.energielabel_connector:
            logger.info("fetching_energielabel_data")
            energielabel_data = self.energielabel_connector.fetch_data(query)
            if energielabel_data:
                building_data.energielabel_data = energielabel_data
        
        return building_data
    
    def _fetch_parallel(
        self, 
        query: AddressQuery, 
        building_data: BuildingData
    ) -> BuildingData:
        """Haal data parallel op met ThreadPoolExecutor"""
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=config.max_workers) as executor:
            futures = {}
            
            # WOZ
            if self.enable_woz and self.woz_connector:
                futures['woz'] = executor.submit(self.woz_connector.fetch_data, query)
            
            # Kadaster (gebruik coördinaten van BAG)
            if self.enable_kadaster and self.kadaster_connector and building_data.bag_data:
                futures['kadaster'] = executor.submit(
                    self.kadaster_connector.fetch_data,
                    coordinates=building_data.bag_data.coordinates
                )
            
            # Energielabel
            if self.enable_energielabel and self.energielabel_connector:
                futures['energielabel'] = executor.submit(
                    self.energielabel_connector.fetch_data, query
                )
            
            # Verzamel resultaten
            for source, future in futures.items():
                try:
                    result = future.result(timeout=config.request_timeout)
                    if result:
                        if source == 'woz':
                            building_data.woz_data = result
                        elif source == 'kadaster':
                            building_data.kadaster_data = result
                        elif source == 'energielabel':
                            building_data.energielabel_data = result
                except Exception as e:
                    logger.error(f"{source}_fetch_failed", error=str(e))
        
        return building_data
    
    def generate_valuation_report(
        self, 
        building_data: BuildingData
    ) -> ValuationReport:
        """
        Genereer een taxatierapport op basis van gebouwdata
        
        Args:
            building_data: BuildingData object
            
        Returns:
            ValuationReport object
        """
        logger.info("generating_valuation_report")
        
        valuation_factors = building_data.get_valuation_factors()
        
        # Eenvoudige schatting (in productie zou dit complexer zijn)
        estimated_value = self._estimate_value(valuation_factors)
        
        report = ValuationReport(
            building_data=building_data,
            estimated_value=estimated_value,
            valuation_factors=valuation_factors,
            remarks=self._generate_remarks(building_data)
        )
        
        logger.info(
            "valuation_report_generated",
            estimated_value=estimated_value
        )
        
        return report
    
    def _estimate_value(self, factors: Dict[str, Any]) -> Optional[int]:
        """
        Schat de waarde van een gebouw
        
        Note: Dit is een zeer vereenvoudigde schatting voor demo doeleinden.
        In productie zou dit een complex model zijn met vele factoren.
        """
        # Als we een WOZ waarde hebben, gebruik die
        if 'woz_waarde' in factors and factors['woz_waarde']:
            return factors['woz_waarde']
        
        # Anders maak een ruwe schatting
        base_value = 200000  # Base waarde
        
        if 'oppervlakte' in factors and factors['oppervlakte']:
            # Ruwweg €2500 per m²
            base_value = factors['oppervlakte'] * 2500
        
        # Correctie voor bouwjaar
        if 'bouwjaar' in factors and factors['bouwjaar']:
            current_year = datetime.now().year
            age = current_year - factors['bouwjaar']
            if age < 5:
                base_value *= 1.1  # +10% voor nieuwbouw
            elif age > 50:
                base_value *= 0.9  # -10% voor oude gebouwen
        
        # Correctie voor energielabel
        if 'energielabel' in factors:
            label = factors['energielabel']
            if label in ['A++++', 'A+++', 'A++', 'A+', 'A']:
                base_value *= 1.05  # +5%
            elif label in ['E', 'F', 'G']:
                base_value *= 0.95  # -5%
        
        return int(base_value)
    
    def _generate_remarks(self, building_data: BuildingData) -> List[str]:
        """Genereer opmerkingen voor het rapport"""
        remarks = []
        
        if not building_data.bag_data:
            remarks.append("BAG data niet beschikbaar")
        
        if not building_data.woz_data:
            remarks.append("WOZ data niet beschikbaar - schatting gebaseerd op andere factoren")
        
        if not building_data.energielabel_data:
            remarks.append("Energielabel niet geregistreerd")
        
        if building_data.bag_data and building_data.bag_data.bouwjaar:
            current_year = datetime.now().year
            age = current_year - building_data.bag_data.bouwjaar
            if age > 30:
                remarks.append(f"Gebouw is {age} jaar oud - mogelijk renovatie nodig")
        
        return remarks
    
    def batch_process(
        self,
        addresses: List[Dict[str, Any]],
        output_format: str = "json",
        output_file: Optional[str] = None
    ) -> List[BuildingData]:
        """
        Verwerk een batch van adressen
        
        Args:
            addresses: List van address dictionaries
            output_format: Output formaat (json, excel, csv)
            output_file: Output bestandsnaam (optioneel)
            
        Returns:
            List van BuildingData objecten
        """
        logger.info("batch_processing_started", count=len(addresses))
        
        results = []
        
        for addr in addresses:
            try:
                query = AddressQuery(**addr)
                data = self.fetch_all_data(query)
                results.append(data)
            except Exception as e:
                logger.error("batch_item_failed", error=str(e), address=addr)
        
        # Sla resultaten op indien gewenst
        if output_file:
            self._save_batch_results(results, output_format, output_file)
        
        logger.info("batch_processing_completed", success_count=len(results))
        
        return results
    
    def _save_batch_results(
        self,
        results: List[BuildingData],
        format: str,
        filename: str
    ):
        """Sla batch resultaten op in gewenst formaat"""
        if format == "json":
            import json
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(
                    [r.to_dict() for r in results],
                    f,
                    indent=2,
                    ensure_ascii=False,
                    default=str
                )
        elif format == "excel":
            import pandas as pd
            df = pd.DataFrame([r.to_dict() for r in results])
            df.to_excel(filename, index=False)
        elif format == "csv":
            import pandas as pd
            df = pd.DataFrame([r.to_dict() for r in results])
            df.to_csv(filename, index=False)
        else:
            raise ValueError(f"Unsupported format: {format}")
        
        logger.info("batch_results_saved", filename=filename, format=format)
