#!/usr/bin/env python3
"""
Test script om de agent te testen zonder echte API calls
"""

from building_data_agent.models import (
    AddressQuery,
    BAGData,
    WOZData,
    EnergielabelData,
    BuildingData,
    Coordinates
)
from building_data_agent import BuildingDataAgent


def create_mock_data():
    """Creëer mock data voor testen"""
    
    query = AddressQuery(
        postcode="1071DJ",
        huisnummer=1
    )
    
    bag_data = BAGData(
        verblijfsobject_id="0363010012345678",
        pand_id="0363100012345678",
        oppervlakte=2500,
        bouwjaar=1885,
        status="Verblijfsobject in gebruik",
        gebruiksdoel=["bijeenkomstfunctie", "celfunctie"],
        aantal_kamers=None,
        coordinates=Coordinates(
            latitude=52.3600,
            longitude=4.8852
        ),
        straat="Museumstraat",
        woonplaats="Amsterdam",
        gemeente="Amsterdam",
        provincie="Noord-Holland"
    )
    
    woz_data = WOZData(
        woz_waarde=15000000,
        peildatum="2023-01-01",
        waarderingsjaar=2023,
        historische_waarden=[
            {"waarderingsjaar": 2022, "woz_waarde": 14500000, "peildatum": "2022-01-01"},
            {"waarderingsjaar": 2021, "woz_waarde": 14000000, "peildatum": "2021-01-01"}
        ]
    )
    
    energielabel_data = EnergielabelData(
        label="C",
        label_geldig_tot="2030-12-31",
        opnamedatum="2020-05-15",
        energieindex=1.8,
        energiebehoefte=250.5,
        eis_energiebehoefte=300.0,
        energieklasse="C",
        gebouwtype="Utiliteitsbouw",
        gebouwsubtype="Bijeenkomstfunctie",
        meting_geldig=True
    )
    
    building_data = BuildingData(
        query=query,
        bag_data=bag_data,
        woz_data=woz_data,
        energielabel_data=energielabel_data,
        data_sources_used=["BAG", "WOZ", "Energielabel"]
    )
    
    return building_data


def main():
    """Test de agent met mock data"""
    
    print("=" * 60)
    print("Building Data Agent - Test met Mock Data")
    print("=" * 60)
    print()
    
    # Creëer mock data
    print("Creëren van mock data...")
    building_data = create_mock_data()
    print("✓ Mock data gecreëerd")
    print()
    
    # Toon data
    print("--- Gebouwdata ---")
    print(f"Adres: {building_data.query.postcode} {building_data.query.huisnummer}")
    print(f"Straat: {building_data.bag_data.straat}")
    print(f"Woonplaats: {building_data.bag_data.woonplaats}")
    print(f"Oppervlakte: {building_data.bag_data.oppervlakte} m²")
    print(f"Bouwjaar: {building_data.bag_data.bouwjaar}")
    print(f"WOZ Waarde: € {building_data.woz_data.woz_waarde:,}")
    print(f"Energielabel: {building_data.energielabel_data.label}")
    print()
    
    # Initialiseer agent
    agent = BuildingDataAgent()
    
    # Genereer rapport
    print("Genereren van taxatierapport...")
    report = agent.generate_valuation_report(building_data)
    print("✓ Rapport gegenereerd")
    print()
    
    print("--- Taxatierapport ---")
    print(f"Geschatte waarde: € {report.estimated_value:,}")
    print()
    
    print("Taxatiefactoren:")
    for key, value in report.valuation_factors.items():
        print(f"  • {key}: {value}")
    print()
    
    if report.remarks:
        print("Opmerkingen:")
        for remark in report.remarks:
            print(f"  • {remark}")
        print()
    
    # Sla op
    print("Opslaan van rapporten...")
    report.save_json("test_rapport.json")
    print("✓ JSON rapport opgeslagen: test_rapport.json")
    
    try:
        report.save_pdf("test_rapport.pdf")
        print("✓ PDF rapport opgeslagen: test_rapport.pdf")
    except ImportError:
        print("⚠ PDF generatie vereist reportlab")
    
    print()
    print("=" * 60)
    print("Test succesvol afgerond!")
    print("=" * 60)


if __name__ == "__main__":
    main()
