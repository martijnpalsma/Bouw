#!/usr/bin/env python3
"""
Voorbeeld script voor het gebruik van de Building Data Agent
"""

from building_data_agent import BuildingDataAgent
from building_data_agent.utils.logging_config import setup_logging

# Setup logging
setup_logging()


def main():
    """Hoofd functie"""
    
    print("=" * 60)
    print("Building Data Agent - Voorbeeld")
    print("=" * 60)
    print()
    
    # Initialiseer agent
    print("Initialiseren van agent...")
    agent = BuildingDataAgent(
        enable_bag=True,
        enable_woz=True,
        enable_kadaster=True,
        enable_energielabel=True
    )
    print("✓ Agent geïnitialiseerd")
    print()
    
    # Voorbeeld adres (Rijksmuseum Amsterdam)
    postcode = "1071DJ"
    huisnummer = 1
    
    print(f"Ophalen van gebouwdata voor {postcode} {huisnummer}...")
    print()
    
    try:
        # Haal data op
        result = agent.get_building_data(
            postcode=postcode,
            huisnummer=huisnummer
        )
        
        print("✓ Data succesvol opgehaald!")
        print()
        print("Data bronnen gebruikt:", ", ".join(result.data_sources_used))
        print()
        
        # BAG Data
        if result.bag_data:
            print("--- BAG Data ---")
            print(f"Straat: {result.bag_data.straat}")
            print(f"Woonplaats: {result.bag_data.woonplaats}")
            print(f"Oppervlakte: {result.bag_data.oppervlakte} m²")
            print(f"Bouwjaar: {result.bag_data.bouwjaar}")
            print(f"Gebruiksdoel: {', '.join(result.bag_data.gebruiksdoel or [])}")
            if result.bag_data.coordinates:
                print(f"Coördinaten: {result.bag_data.coordinates.latitude}, {result.bag_data.coordinates.longitude}")
            print()
        
        # WOZ Data
        if result.woz_data:
            print("--- WOZ Data ---")
            print(f"WOZ Waarde: € {result.woz_data.woz_waarde:,}")
            print(f"Waarderingsjaar: {result.woz_data.waarderingsjaar}")
            print(f"Peildatum: {result.woz_data.peildatum}")
            print()
        
        # Energielabel
        if result.energielabel_data:
            print("--- Energielabel ---")
            print(f"Label: {result.energielabel_data.label}")
            print(f"Energieindex: {result.energielabel_data.energieindex}")
            print(f"Geldig tot: {result.energielabel_data.label_geldig_tot}")
            print()
        
        # Kadaster
        if result.kadaster_data:
            print("--- Kadaster Data ---")
            print(f"Perceeloppervlakte: {result.kadaster_data.perceeloppervlakte} m²")
            print(f"Sectie: {result.kadaster_data.sectie}")
            print(f"Perceelnummer: {result.kadaster_data.perceelnummer}")
            print()
        
        # Genereer taxatierapport
        print("Genereren van taxatierapport...")
        report = agent.generate_valuation_report(result)
        
        if report.estimated_value:
            print(f"✓ Geschatte waarde: € {report.estimated_value:,}")
        
        if report.remarks:
            print()
            print("Opmerkingen:")
            for remark in report.remarks:
                print(f"  • {remark}")
        
        print()
        print("--- Opslaan van rapporten ---")
        
        # Sla rapport op als JSON
        report.save_json("taxatierapport.json")
        print("✓ JSON rapport opgeslagen: taxatierapport.json")
        
        # Sla rapport op als PDF
        try:
            report.save_pdf("taxatierapport.pdf")
            print("✓ PDF rapport opgeslagen: taxatierapport.pdf")
        except ImportError:
            print("⚠ PDF generatie vereist reportlab: pip install reportlab")
        
        print()
        print("=" * 60)
        print("Voorbeeld succesvol afgerond!")
        print("=" * 60)
        
    except Exception as e:
        print(f"❌ Fout opgetreden: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
