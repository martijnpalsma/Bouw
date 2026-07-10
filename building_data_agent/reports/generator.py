"""
Report generation utilities
"""

from typing import Optional
from datetime import datetime
from ..models import ValuationReport
import structlog

logger = structlog.get_logger()


class ReportGenerator:
    """Genereer rapporten in verschillende formaten"""
    
    def generate_pdf(self, report: ValuationReport, filename: str):
        """
        Genereer PDF rapport
        
        Args:
            report: ValuationReport object
            filename: Output bestandsnaam
        """
        try:
            from reportlab.lib.pagesizes import A4
            from reportlab.lib.styles import getSampleStyleSheet
            from reportlab.lib.units import cm
            from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
            from reportlab.lib import colors
            
            doc = SimpleDocTemplate(filename, pagesize=A4)
            story = []
            styles = getSampleStyleSheet()
            
            # Titel
            title = Paragraph("Gebouw Taxatierapport", styles['Title'])
            story.append(title)
            story.append(Spacer(1, 1*cm))
            
            # Datum
            date_text = f"Datum: {report.valuation_date.strftime('%d-%m-%Y')}"
            story.append(Paragraph(date_text, styles['Normal']))
            story.append(Spacer(1, 0.5*cm))
            
            # Adresgegevens
            query = report.building_data.query
            address_text = f"""
            <b>Adres:</b><br/>
            {query.postcode} {query.huisnummer}
            {query.huisletter or ''} {query.toevoeging or ''}
            """
            story.append(Paragraph(address_text, styles['Normal']))
            story.append(Spacer(1, 0.5*cm))
            
            # Geschatte waarde
            if report.estimated_value:
                value_text = f"<b>Geschatte waarde:</b> € {report.estimated_value:,}"
                story.append(Paragraph(value_text, styles['Heading2']))
                story.append(Spacer(1, 0.5*cm))
            
            # Taxatiefactoren
            if report.valuation_factors:
                story.append(Paragraph("<b>Taxatiefactoren:</b>", styles['Heading3']))
                
                factors_data = []
                for key, value in report.valuation_factors.items():
                    factors_data.append([key.replace('_', ' ').title(), str(value)])
                
                factors_table = Table(factors_data)
                factors_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, -1), colors.lightgrey),
                    ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
                    ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                    ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
                    ('FONTSIZE', (0, 0), (-1, -1), 10),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                story.append(factors_table)
                story.append(Spacer(1, 0.5*cm))
            
            # Opmerkingen
            if report.remarks:
                story.append(Paragraph("<b>Opmerkingen:</b>", styles['Heading3']))
                for remark in report.remarks:
                    story.append(Paragraph(f"• {remark}", styles['Normal']))
                story.append(Spacer(1, 0.5*cm))
            
            # Data bronnen
            sources_text = f"<b>Data bronnen:</b> {', '.join(report.building_data.data_sources_used)}"
            story.append(Paragraph(sources_text, styles['Normal']))
            
            # Genereer PDF
            doc.build(story)
            
            logger.info("pdf_report_generated", filename=filename)
            
        except ImportError:
            logger.error("reportlab_not_installed", msg="Install with: pip install reportlab")
            raise
        except Exception as e:
            logger.error("pdf_generation_error", error=str(e))
            raise
    
    def generate_html(self, report: ValuationReport, filename: str):
        """
        Genereer HTML rapport
        
        Args:
            report: ValuationReport object
            filename: Output bestandsnaam
        """
        try:
            from jinja2 import Template
            
            template = Template("""
<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Gebouw Taxatierapport</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .section { margin: 20px 0; }
        .value { font-size: 24px; color: #4CAF50; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .remarks { background-color: #f9f9f9; padding: 10px; border-left: 3px solid #4CAF50; }
    </style>
</head>
<body>
    <h1>Gebouw Taxatierapport</h1>
    
    <div class="section">
        <p><strong>Datum:</strong> {{ report.valuation_date.strftime('%d-%m-%Y') }}</p>
        <p><strong>Adres:</strong> 
            {{ report.building_data.query.postcode }} 
            {{ report.building_data.query.huisnummer }}
            {{ report.building_data.query.huisletter or '' }}
            {{ report.building_data.query.toevoeging or '' }}
        </p>
    </div>
    
    {% if report.estimated_value %}
    <div class="section">
        <p><strong>Geschatte waarde:</strong></p>
        <p class="value">€ {{ "{:,}".format(report.estimated_value) }}</p>
    </div>
    {% endif %}
    
    {% if report.valuation_factors %}
    <div class="section">
        <h2>Taxatiefactoren</h2>
        <table>
            <tr>
                <th>Factor</th>
                <th>Waarde</th>
            </tr>
            {% for key, value in report.valuation_factors.items() %}
            <tr>
                <td>{{ key.replace('_', ' ').title() }}</td>
                <td>{{ value }}</td>
            </tr>
            {% endfor %}
        </table>
    </div>
    {% endif %}
    
    {% if report.remarks %}
    <div class="section">
        <h2>Opmerkingen</h2>
        <div class="remarks">
            <ul>
                {% for remark in report.remarks %}
                <li>{{ remark }}</li>
                {% endfor %}
            </ul>
        </div>
    </div>
    {% endif %}
    
    <div class="section">
        <p><strong>Data bronnen:</strong> {{ ', '.join(report.building_data.data_sources_used) }}</p>
    </div>
</body>
</html>
            """)
            
            html_content = template.render(report=report)
            
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            logger.info("html_report_generated", filename=filename)
            
        except ImportError:
            logger.error("jinja2_not_installed", msg="Install with: pip install jinja2")
            raise
        except Exception as e:
            logger.error("html_generation_error", error=str(e))
            raise
