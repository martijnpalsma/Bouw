"""
Unit tests voor Building Data Agent
"""

import pytest
from building_data_agent.models import AddressQuery, BAGData, WOZData, Coordinates
from building_data_agent import BuildingDataAgent


class TestAddressQuery:
    """Tests voor AddressQuery model"""
    
    def test_valid_postcode(self):
        """Test valide postcode"""
        query = AddressQuery(postcode="1012JS", huisnummer=1)
        assert query.postcode == "1012JS"
    
    def test_postcode_normalization(self):
        """Test postcode normalisatie"""
        query = AddressQuery(postcode="1012 js", huisnummer=1)
        assert query.postcode == "1012JS"
    
    def test_invalid_postcode_length(self):
        """Test ongeldige postcode lengte"""
        with pytest.raises(ValueError):
            AddressQuery(postcode="1012", huisnummer=1)
    
    def test_invalid_postcode_format(self):
        """Test ongeldig postcode formaat"""
        with pytest.raises(ValueError):
            AddressQuery(postcode="ABCD12", huisnummer=1)


class TestBuildingDataAgent:
    """Tests voor BuildingDataAgent"""
    
    def test_agent_initialization(self):
        """Test agent initialisatie"""
        agent = BuildingDataAgent()
        assert agent.bag_connector is not None
        assert agent.woz_connector is not None
    
    def test_agent_with_disabled_connectors(self):
        """Test agent met uitgeschakelde connectors"""
        agent = BuildingDataAgent(
            enable_bag=True,
            enable_woz=False,
            enable_kadaster=False,
            enable_energielabel=False
        )
        assert agent.bag_connector is not None
        assert agent.woz_connector is None
        assert agent.kadaster_connector is None
        assert agent.energielabel_connector is None
    
    def test_estimate_value_with_woz(self):
        """Test waarde schatting met WOZ data"""
        agent = BuildingDataAgent()
        factors = {"woz_waarde": 350000}
        estimated = agent._estimate_value(factors)
        assert estimated == 350000
    
    def test_estimate_value_without_woz(self):
        """Test waarde schatting zonder WOZ data"""
        agent = BuildingDataAgent()
        factors = {"oppervlakte": 100, "bouwjaar": 2020}
        estimated = agent._estimate_value(factors)
        assert estimated > 0


class TestModels:
    """Tests voor data modellen"""
    
    def test_bag_data_creation(self):
        """Test BAGData creatie"""
        bag = BAGData(
            oppervlakte=100,
            bouwjaar=2020,
            straat="Teststraat",
            woonplaats="Amsterdam"
        )
        assert bag.oppervlakte == 100
        assert bag.bouwjaar == 2020
    
    def test_coordinates_creation(self):
        """Test Coordinates creatie"""
        coords = Coordinates(latitude=52.3676, longitude=4.9041)
        assert coords.latitude == 52.3676
        assert coords.longitude == 4.9041


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
