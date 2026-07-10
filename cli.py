#!/usr/bin/env python3
"""
Command-line interface voor Building Data Agent
"""

import argparse
import json
import sys
from building_data_agent import BuildingDataAgent
from building_data_agent.models import AddressQuery
from building_data_agent.utils.logging_config import setup_logging


def main():
    """Hoofdfunctie voor CLI"""
    
    parser = argparse.ArgumentParser(
        description="Building Data Agent - Gebouwtaxatie en Inspectie Data Ophalen"
    )
    
    # Subcommands
    subparsers = parser.add_subparsers(dest="command", help="Beschikbare commando's")
    
    # Fetch command
    fetch_parser = subparsers.add_parser("fetch", help="Haal gebouwdata op")
    fetch_parser.add_argument("postcode", help="Postcode (bijv. 1012JS)")
    fetch_parser.add_argument("huisnummer", type=int, help="Huisnummer")
    fetch_parser.add_argument("--huisletter", help="Huisletter")
    fetch_parser.add_argument("--toevoeging", help="Toevoeging")
    fetch_parser.add_argument("--output", "-o", help="Output bestand (JSON)")
    fetch_parser.add_argument("--format", choices=["json", "pretty"], default="pretty", 
                            help="Output formaat")
    
    # Report command
    report_parser = subparsers.add_parser("report", help="Genereer taxatierapport")
    report_parser.add_argument("postcode", help="Postcode")
    report_parser.add_argument("huisnummer", type=int, help="Huisnummer")
    report_parser.add_argument("--huisletter", help="Huisletter")
    report_parser.add_argument("--toevoeging", help="Toevoeging")
    report_parser.add_argument("--output", "-o", required=True, help="Output bestand")
    report_parser.add_argument("--format", choices=["pdf", "json", "html"], default="pdf",
                             help="Rapport formaat")
    
    # Batch command
    batch_parser = subparsers.add_parser("batch", help="Verwerk batch adressen")
    batch_parser.add_argument("input", help="Input CSV/JSON bestand")
    batch_parser.add_argument("--output", "-o", required=True, help="Output bestand")
    batch_parser.add_argument("--format", choices=["json", "excel", "csv"], default="json",
                            help="Output formaat")
    
    # API command
    api_parser = subparsers.add_parser("api", help="Start API server")
    api_parser.add_argument("--host", default="0.0.0.0", help="Host address")
    api_parser.add_argument("--port", type=int, default=8000, help="Port nummer")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Setup logging
    setup_logging()
    
    # Execute command
    if args.command == "fetch":
        fetch_command(args)
    elif args.command == "report":
        report_command(args)
    elif args.command == "batch":
        batch_command(args)
    elif args.command == "api":
        api_command(args)


def fetch_command(args):
    """Haal gebouwdata op"""
    
    print(f"Ophalen van data voor {args.postcode} {args.huisnummer}...")
    
    agent = BuildingDataAgent()
    
    result = agent.get_building_data(
        postcode=args.postcode,
        huisnummer=args.huisnummer,
        huisletter=args.huisletter,
        toevoeging=args.toevoeging
    )
    
    if args.format == "json":
        output = json.dumps(result.to_dict(), indent=2, ensure_ascii=False, default=str)
        
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output)
            print(f"✓ Data opgeslagen in {args.output}")
        else:
            print(output)
    
    else:  # pretty format
        print()
        print("=" * 60)
        print("GEBOUWDATA")
        print("=" * 60)
        print()
        
        print(f"Adres: {result.query.postcode} {result.query.huisnummer}")
        print(f"Data bronnen: {', '.join(result.data_sources_used)}")
        print()
        
        if result.bag_data:
            print("--- BAG Data ---")
            print(f"Straat: {result.bag_data.straat}")
            print(f"Woonplaats: {result.bag_data.woonplaats}")
            print(f"Oppervlakte: {result.bag_data.oppervlakte} m²")
            print(f"Bouwjaar: {result.bag_data.bouwjaar}")
            print()
        
        if result.woz_data:
            print("--- WOZ Data ---")
            print(f"WOZ Waarde: € {result.woz_data.woz_waarde:,}")
            print(f"Waarderingsjaar: {result.woz_data.waarderingsjaar}")
            print()
        
        if result.energielabel_data:
            print("--- Energielabel ---")
            print(f"Label: {result.energielabel_data.label}")
            print()
        
        if args.output:
            result_json = json.dumps(result.to_dict(), indent=2, ensure_ascii=False, default=str)
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(result_json)
            print(f"✓ Data opgeslagen in {args.output}")


def report_command(args):
    """Genereer taxatierapport"""
    
    print(f"Genereren van rapport voor {args.postcode} {args.huisnummer}...")
    
    agent = BuildingDataAgent()
    
    # Haal data op
    building_data = agent.get_building_data(
        postcode=args.postcode,
        huisnummer=args.huisnummer,
        huisletter=args.huisletter,
        toevoeging=args.toevoeging
    )
    
    # Genereer rapport
    report = agent.generate_valuation_report(building_data)
    
    # Sla rapport op
    if args.format == "pdf":
        report.save_pdf(args.output)
    elif args.format == "json":
        report.save_json(args.output)
    elif args.format == "html":
        from building_data_agent.reports.generator import ReportGenerator
        generator = ReportGenerator()
        generator.generate_html(report, args.output)
    
    print(f"✓ Rapport opgeslagen in {args.output}")
    
    if report.estimated_value:
        print(f"Geschatte waarde: € {report.estimated_value:,}")


def batch_command(args):
    """Verwerk batch adressen"""
    
    print(f"Lezen van adressen uit {args.input}...")
    
    # Lees input
    if args.input.endswith('.json'):
        with open(args.input, 'r', encoding='utf-8') as f:
            addresses = json.load(f)
    elif args.input.endswith('.csv'):
        import pandas as pd
        df = pd.read_csv(args.input)
        addresses = df.to_dict('records')
    else:
        print("❌ Onbekend input formaat. Gebruik .json of .csv")
        sys.exit(1)
    
    print(f"Verwerken van {len(addresses)} adressen...")
    
    agent = BuildingDataAgent()
    
    results = agent.batch_process(
        addresses,
        output_format=args.format,
        output_file=args.output
    )
    
    print(f"✓ {len(results)} adressen verwerkt")
    print(f"✓ Resultaten opgeslagen in {args.output}")


def api_command(args):
    """Start API server"""
    
    import uvicorn
    from building_data_agent.api import app
    
    print("=" * 60)
    print("Building Data Agent API Server")
    print("=" * 60)
    print()
    print(f"Starting server op {args.host}:{args.port}...")
    print()
    print("API Documentatie:")
    print(f"  - Swagger UI: http://{args.host}:{args.port}/docs")
    print(f"  - ReDoc: http://{args.host}:{args.port}/redoc")
    print()
    
    uvicorn.run(
        app,
        host=args.host,
        port=args.port
    )


if __name__ == "__main__":
    main()
