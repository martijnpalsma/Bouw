"""
Setup configuration for Building Data Agent
"""

from setuptools import setup, find_packages

with open("README_DATA_AGENT.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="building-data-agent",
    version="1.0.0",
    author="Building Data Team",
    description="Gespecialiseerde agent voor gebouwtaxatie en inspectie data",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/building-data-agent",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=[
        "requests>=2.31.0",
        "python-dotenv>=1.0.0",
        "pydantic>=2.5.0",
        "pydantic-settings>=2.1.0",
        "pandas>=2.1.0",
        "numpy>=1.24.0",
        "fastapi>=0.104.0",
        "uvicorn>=0.24.0",
        "httpx>=0.25.0",
        "diskcache>=5.6.0",
        "reportlab>=4.0.0",
        "jinja2>=3.1.0",
        "openpyxl>=3.1.0",
        "shapely>=2.0.0",
        "pyproj>=3.6.0",
        "python-dateutil>=2.8.0",
        "pytz>=2023.3",
        "structlog>=23.2.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-asyncio>=0.21.0",
            "pytest-cov>=4.1.0",
            "black>=23.11.0",
            "flake8>=6.1.0",
            "mypy>=1.7.0",
        ],
        "redis": [
            "redis>=5.0.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "building-agent=cli:main",
        ],
    },
)
