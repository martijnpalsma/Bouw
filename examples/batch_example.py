#!/usr/bin/env python3
"""
Batch processing voorbeeld
Verwerk meerdere adressen in één keer
"""

from building_data_agent import BuildingDataAgent
from building_data_agent.utils.logging_config import setup_logging
import pandas as pd

# Setup logging
setup_logging()


def main():
    """Hoofd functie"""
    
    print("=" * 60)
    print("Building Data Agent - Batch Processing Voorbeeld")
    print("=" * 60)
    print()
    
    # Initialiseer agent
    agent = BuildingDataAgent()
    
    # Voorbeeld adressen
    addresses = [
        {"postcode": "1071DJ", "huisnummer": 1},  # Rijksmuseum
        {"postcode": "1012JS", "huisnummer": 1},  # Koninklijk Paleis
        {"postcode": "1017XX", "huisnummer": 1},  # Heineken Experience
    ]
    
    print(f"Verwerken van {len(addresses)} adressen...")
    print()
    
    # Verwerk batch
    results = agent.batch_process(
        addresses,
        output_format="json",
        output_file="batch_results.json"
    )
    
    print(f"✓ {len(results)} adressen succesvol verwerkt")
    print()
    
    # Toon samenvatting
    print("--- Samenvatting ---")
    for i, result in enumerate(results, 1):
        query = result.query
        print(f"\n{i}. {query.postcode} {query.huisnummer}")
        
        if result.bag_data:
            print(f"   Straat: {result.bag_data.straat}")
            print(f"   Oppervlakte: {result.bag_data.oppervlakte} m²")
            print(f"   Bouwjaar: {result.bag_data.bouwjaar}")
        
        if result.woz_data:
            print(f"   WOZ waarde: € {result.woz_data.woz_waarde:,}")
        
        if result.energielabel_data:
            print(f"   Energielabel: {result.energielabel_data.label}")
    
    print()
    print("✓ Resultaten opgeslagen in: batch_results.json")
    print()


if __name__ == "__main__":
    main()
