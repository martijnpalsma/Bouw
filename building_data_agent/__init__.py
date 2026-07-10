"""
Building Data Agent - Gespecialiseerde agent voor gebouwtaxatie en inspectie data
"""

__version__ = "1.0.0"
__author__ = "Building Data Team"

from .agent import BuildingDataAgent
from .models import AddressQuery, BuildingData, ValuationReport
from .config import Config

__all__ = [
    "BuildingDataAgent",
    "AddressQuery", 
    "BuildingData",
    "ValuationReport",
    "Config"
]
