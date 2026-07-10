"""
Data modellen voor de Building Data Agent
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, field_validator


class AddressQuery(BaseModel):
    """Query model voor adresgegevens"""
    postcode: str = Field(..., description="Postcode in formaat 1234AB")
    huisnummer: int = Field(..., description="Huisnummer")
    huisletter: Optional[str] = Field(None, description="Huisletter (optioneel)")
    toevoeging: Optional[str] = Field(None, description="Huisnummer toevoeging (optioneel)")
    
    @field_validator('postcode')
    @classmethod
    def validate_postcode(cls, v: str) -> str:
        """Valideer en normaliseer postcode"""
        v = v.replace(" ", "").upper()
        if len(v) != 6:
            raise ValueError("Postcode moet 6 tekens zijn (1234AB)")
        if not v[:4].isdigit() or not v[4:].isalpha():
            raise ValueError("Postcode moet formaat 1234AB hebben")
        return v


class Coordinates(BaseModel):
    """Geografische coördinaten"""
    latitude: float
    longitude: float
    rd_x: Optional[float] = None  # Rijksdriehoek X
    rd_y: Optional[float] = None  # Rijksdriehoek Y


class BAGData(BaseModel):
    """BAG (Basisregistratie Adressen en Gebouwen) data"""
    verblijfsobject_id: Optional[str] = None
    pand_id: Optional[str] = None
    oppervlakte: Optional[int] = None  # in m²
    bouwjaar: Optional[int] = None
    status: Optional[str] = None
    gebruiksdoel: Optional[List[str]] = None
    aantal_kamers: Optional[int] = None
    coordinates: Optional[Coordinates] = None
    straat: Optional[str] = None
    woonplaats: Optional[str] = None
    gemeente: Optional[str] = None
    provincie: Optional[str] = None


class WOZData(BaseModel):
    """WOZ (Waardering Onroerende Zaken) data"""
    woz_waarde: Optional[int] = None
    peildatum: Optional[str] = None
    waarderingsjaar: Optional[int] = None
    historische_waarden: Optional[List[Dict[str, Any]]] = None


class KadasterData(BaseModel):
    """Kadaster data"""
    kadastraal_object_id: Optional[str] = None
    perceeloppervlakte: Optional[int] = None  # in m²
    eigendomssituatie: Optional[str] = None
    zakelijke_rechten: Optional[List[str]] = None
    gemeente_code: Optional[str] = None
    sectie: Optional[str] = None
    perceelnummer: Optional[str] = None


class EnergielabelData(BaseModel):
    """Energielabel data"""
    label: Optional[str] = None  # A++++ tot G
    label_geldig_tot: Optional[str] = None
    opnamedatum: Optional[str] = None
    energieindex: Optional[float] = None
    energiebehoefte: Optional[float] = None  # kWh/m²/jaar
    eis_energiebehoefte: Optional[float] = None
    energieklasse: Optional[str] = None
    gebouwtype: Optional[str] = None
    gebouwsubtype: Optional[str] = None
    meting_geldig: Optional[bool] = None


class InspectionData(BaseModel):
    """Inspectie data (uit omgevingsloket/vergunningen)"""
    vergunningen: Optional[List[Dict[str, Any]]] = None
    inspecties: Optional[List[Dict[str, Any]]] = None
    meldingen: Optional[List[Dict[str, Any]]] = None
    handhaving: Optional[List[Dict[str, Any]]] = None


class BuildingData(BaseModel):
    """Gecombineerde gebouwdata"""
    query: AddressQuery
    bag_data: Optional[BAGData] = None
    woz_data: Optional[WOZData] = None
    kadaster_data: Optional[KadasterData] = None
    energielabel_data: Optional[EnergielabelData] = None
    inspection_data: Optional[InspectionData] = None
    
    retrieved_at: datetime = Field(default_factory=datetime.now)
    data_sources_used: List[str] = Field(default_factory=list)
    
    def to_dict(self) -> Dict[str, Any]:
        """Converteer naar dictionary"""
        return self.model_dump(exclude_none=True)
    
    def get_valuation_factors(self) -> Dict[str, Any]:
        """Haal relevante taxatiefactoren op"""
        factors = {}
        
        if self.bag_data:
            factors['oppervlakte'] = self.bag_data.oppervlakte
            factors['bouwjaar'] = self.bag_data.bouwjaar
            factors['aantal_kamers'] = self.bag_data.aantal_kamers
            factors['gebruiksdoel'] = self.bag_data.gebruiksdoel
        
        if self.woz_data:
            factors['woz_waarde'] = self.woz_data.woz_waarde
            factors['waarderingsjaar'] = self.woz_data.waarderingsjaar
        
        if self.kadaster_data:
            factors['perceeloppervlakte'] = self.kadaster_data.perceeloppervlakte
        
        if self.energielabel_data:
            factors['energielabel'] = self.energielabel_data.label
            factors['energieindex'] = self.energielabel_data.energieindex
        
        return factors


class ValuationReport(BaseModel):
    """Taxatierapport"""
    building_data: BuildingData
    valuation_date: datetime = Field(default_factory=datetime.now)
    estimated_value: Optional[int] = None
    valuation_factors: Dict[str, Any] = Field(default_factory=dict)
    remarks: List[str] = Field(default_factory=list)
    
    def save_pdf(self, filename: str):
        """Sla rapport op als PDF"""
        from .reports.generator import ReportGenerator
        generator = ReportGenerator()
        generator.generate_pdf(self, filename)
    
    def save_json(self, filename: str):
        """Sla rapport op als JSON"""
        import json
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.model_dump(exclude_none=True), f, indent=2, ensure_ascii=False, default=str)
