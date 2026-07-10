"""
FastAPI applicatie voor Building Data Agent
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
from pydantic import BaseModel

from ..agent import BuildingDataAgent
from ..models import AddressQuery, BuildingData
from ..config import config
from ..utils.logging_config import setup_logging
import structlog

# Setup logging
setup_logging()
logger = structlog.get_logger()

# Initialize FastAPI app
app = FastAPI(
    title="Building Data Agent API",
    description="API voor het ophalen van gebouwtaxatie en inspectie data",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize agent
agent = BuildingDataAgent()


class BuildingDataRequest(BaseModel):
    """Request model voor gebouwdata"""
    postcode: str
    huisnummer: int
    huisletter: Optional[str] = None
    toevoeging: Optional[str] = None


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "Building Data Agent API",
        "version": "1.0.0"
    }


@app.get("/health")
async def health():
    """Gedetailleerde health check"""
    return {
        "status": "healthy",
        "connectors": {
            "bag": agent.bag_connector is not None,
            "woz": agent.woz_connector is not None,
            "kadaster": agent.kadaster_connector is not None,
            "energielabel": agent.energielabel_connector is not None
        }
    }


@app.post("/api/v1/building-data", response_model=BuildingData)
async def get_building_data(request: BuildingDataRequest):
    """
    Haal alle gebouwdata op voor een adres
    
    Args:
        request: BuildingDataRequest met adresgegevens
        
    Returns:
        BuildingData object met alle verzamelde data
    """
    try:
        logger.info("api_request_building_data", request=request.model_dump())
        
        result = agent.get_building_data(
            postcode=request.postcode,
            huisnummer=request.huisnummer,
            huisletter=request.huisletter,
            toevoeging=request.toevoeging
        )
        
        return result
        
    except ValueError as e:
        logger.error("validation_error", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error("api_error", error=str(e))
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/api/v1/bag")
async def get_bag_data(
    postcode: str = Query(..., description="Postcode (bijv. 1012JS)"),
    huisnummer: int = Query(..., description="Huisnummer"),
    huisletter: Optional[str] = Query(None, description="Huisletter"),
    toevoeging: Optional[str] = Query(None, description="Toevoeging")
):
    """
    Haal alleen BAG data op
    """
    try:
        if not agent.bag_connector:
            raise HTTPException(status_code=503, detail="BAG connector not available")
        
        query = AddressQuery(
            postcode=postcode,
            huisnummer=huisnummer,
            huisletter=huisletter,
            toevoeging=toevoeging
        )
        
        result = agent.bag_connector.fetch_data(query)
        
        if not result:
            raise HTTPException(status_code=404, detail="BAG data not found")
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error("bag_api_error", error=str(e))
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/api/v1/woz")
async def get_woz_data(
    postcode: str = Query(..., description="Postcode"),
    huisnummer: int = Query(..., description="Huisnummer"),
    huisletter: Optional[str] = Query(None, description="Huisletter"),
    toevoeging: Optional[str] = Query(None, description="Toevoeging")
):
    """
    Haal alleen WOZ data op
    """
    try:
        if not agent.woz_connector:
            raise HTTPException(status_code=503, detail="WOZ connector not available")
        
        query = AddressQuery(
            postcode=postcode,
            huisnummer=huisnummer,
            huisletter=huisletter,
            toevoeging=toevoeging
        )
        
        result = agent.woz_connector.fetch_data(query)
        
        if not result:
            raise HTTPException(status_code=404, detail="WOZ data not found")
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error("woz_api_error", error=str(e))
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/api/v1/energielabel")
async def get_energielabel_data(
    postcode: str = Query(..., description="Postcode"),
    huisnummer: int = Query(..., description="Huisnummer"),
    huisletter: Optional[str] = Query(None, description="Huisletter"),
    toevoeging: Optional[str] = Query(None, description="Toevoeging")
):
    """
    Haal alleen energielabel data op
    """
    try:
        if not agent.energielabel_connector:
            raise HTTPException(status_code=503, detail="Energielabel connector not available")
        
        query = AddressQuery(
            postcode=postcode,
            huisnummer=huisnummer,
            huisletter=huisletter,
            toevoeging=toevoeging
        )
        
        result = agent.energielabel_connector.fetch_data(query)
        
        if not result:
            raise HTTPException(status_code=404, detail="Energielabel data not found")
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error("energielabel_api_error", error=str(e))
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post("/api/v1/valuation-report")
async def generate_valuation_report(request: BuildingDataRequest):
    """
    Genereer een taxatierapport voor een adres
    """
    try:
        # Haal gebouwdata op
        building_data = agent.get_building_data(
            postcode=request.postcode,
            huisnummer=request.huisnummer,
            huisletter=request.huisletter,
            toevoeging=request.toevoeging
        )
        
        # Genereer rapport
        report = agent.generate_valuation_report(building_data)
        
        return report
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error("report_api_error", error=str(e))
        raise HTTPException(status_code=500, detail="Internal server error")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host=config.api_host,
        port=config.api_port,
        log_level=config.log_level.lower()
    )
