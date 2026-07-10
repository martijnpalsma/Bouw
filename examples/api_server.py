#!/usr/bin/env python3
"""
API server voorbeeld
Start de FastAPI server
"""

import uvicorn
from building_data_agent.api import app
from building_data_agent.config import config
from building_data_agent.utils.logging_config import setup_logging

# Setup logging
setup_logging()


if __name__ == "__main__":
    print("=" * 60)
    print("Building Data Agent API Server")
    print("=" * 60)
    print()
    print(f"Starting server on {config.api_host}:{config.api_port}...")
    print()
    print("API Documentation:")
    print(f"  - Swagger UI: http://localhost:{config.api_port}/docs")
    print(f"  - ReDoc: http://localhost:{config.api_port}/redoc")
    print()
    print("Example requests:")
    print(f'  curl -X POST http://localhost:{config.api_port}/api/v1/building-data \\')
    print('    -H "Content-Type: application/json" \\')
    print('    -d \'{"postcode": "1071DJ", "huisnummer": 1}\'')
    print()
    print("=" * 60)
    print()
    
    uvicorn.run(
        app,
        host=config.api_host,
        port=config.api_port,
        log_level=config.log_level.lower()
    )
