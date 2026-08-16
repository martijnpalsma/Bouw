import os
import base64
import json
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename
import openai

app = Flask(__name__, static_folder='.')
CORS(app)

# Configuratie
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

# Maak upload folder aan
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# OpenAI API key (moet ingesteld worden als environment variable)
openai.api_key = os.environ.get('OPENAI_API_KEY', '')

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def analyze_building_image(image_path, conversation_history=None):
    """
    Analyseer gebouwfoto met GPT-4 Vision
    """
    if not openai.api_key:
        return {
            "error": "OpenAI API key niet geconfigureerd",
            "demo_response": True,
            "analysis": {
                "constructie": "Demo analyse - Configureer OPENAI_API_KEY",
                "materialen": ["Baksteen", "Beton", "Hout"],
                "isolatie": ["Spouwmuurisolatie mogelijk aanwezig"],
                "vragen": ["Wanneer is het gebouw gebouwd?"]
            }
        }
    
    try:
        # Encode image
        base64_image = encode_image(image_path)
        
        # Bouw de berichten lijst
        messages = []
        
        # Voeg conversatiegeschiedenis toe indien aanwezig
        if conversation_history:
            messages.extend(conversation_history)
        
        # System prompt voor gedetailleerde gebouwanalyse
        if not conversation_history or len(conversation_history) == 0:
            system_prompt = """Je bent een expert bouwkundige en constructie-analist. 
            Analyseer de gebouwfoto's grondig en geef gedetailleerde informatie over:

            1. CONSTRUCTIE: Type gebouw, constructiemethode, draagconstructie
            2. MATERIALEN: Alle zichtbare bouwmaterialen (muren, dak, kozijnen, etc.)
            3. ISOLATIE: Inschatting van isolatiematerialen en -methoden
            4. STAAT: Conditie van het gebouw en materialen
            5. GESCHATTE BOUWPERIODE: Op basis van architectuur en materiaalgebruik
            
            Als informatie onduidelijk is of je meer details nodig hebt, stel dan 
            CONCRETE verduidelijkingsvragen aan de gebruiker.
            
            Geef je antwoord in VALIDE JSON formaat met deze structuur:
            {
                "constructie": {
                    "type": "string",
                    "draagconstructie": "string",
                    "verdiepingen": "number",
                    "details": "string"
                },
                "materialen": {
                    "gevel": ["string"],
                    "dak": ["string"],
                    "kozijnen": ["string"],
                    "fundering": "string (indien zichtbaar)",
                    "overig": ["string"]
                },
                "isolatie": {
                    "geschat": ["string"],
                    "waarschijnlijkheid": "hoog/middel/laag",
                    "aanbevelingen": ["string"]
                },
                "staat": {
                    "algemeen": "string",
                    "onderhoud": "string",
                    "aandachtspunten": ["string"]
                },
                "bouwperiode": {
                    "geschat": "string",
                    "indicatoren": ["string"]
                },
                "verduidelijkingsvragen": [
                    {
                        "vraag": "string",
                        "reden": "string"
                    }
                ],
                "conclusie": "string",
                "betrouwbaarheid": "hoog/middel/laag"
            }
            
            Wees zo specifiek mogelijk en baseer je analyse op zichtbare details."""
            
            messages.append({
                "role": "system",
                "content": system_prompt
            })
        
        # Voeg de afbeelding toe aan het bericht
        messages.append({
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Analyseer deze gebouwfoto in detail volgens het opgegeven formaat. Geef een complete analyse van constructie, materialen en isolatie."
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{base64_image}",
                        "detail": "high"
                    }
                }
            ]
        })
        
        # API call naar GPT-4 Vision
        response = openai.chat.completions.create(
            model="gpt-4o",
            messages=messages,
            max_tokens=2000,
            temperature=0.3
        )
        
        # Parse de response
        content = response.choices[0].message.content
        
        # Probeer JSON te extraheren
        try:
            # Verwijder mogelijke markdown code blocks
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0]
            elif "```" in content:
                content = content.split("```")[1].split("```")[0]
            
            analysis = json.loads(content.strip())
        except json.JSONDecodeError:
            # Als JSON parsing faalt, return de tekst in een gestructureerd formaat
            analysis = {
                "raw_response": content,
                "error": "Response is niet in JSON formaat",
                "parsed": False
            }
        
        return {
            "success": True,
            "analysis": analysis,
            "model": "gpt-4o",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        return {
            "error": str(e),
            "success": False
        }

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory('.', path)

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """
    Upload gebouwfoto en start analyse
    """
    if 'file' not in request.files:
        return jsonify({'error': 'Geen bestand gevonden'}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({'error': 'Geen bestand geselecteerd'}), 400
    
    if not allowed_file(file.filename):
        return jsonify({'error': 'Bestandstype niet toegestaan'}), 400
    
    # Controleer bestandsgrootte
    file.seek(0, os.SEEK_END)
    file_length = file.tell()
    if file_length > MAX_FILE_SIZE:
        return jsonify({'error': 'Bestand te groot (max 10MB)'}), 400
    file.seek(0)
    
    try:
        # Bewaar het bestand
        filename = secure_filename(file.filename)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_filename = f"{timestamp}_{filename}"
        filepath = os.path.join(UPLOAD_FOLDER, unique_filename)
        file.save(filepath)
        
        # Analyseer de foto
        result = analyze_building_image(filepath)
        
        # Voeg bestandsinformatie toe
        result['filename'] = unique_filename
        result['original_filename'] = filename
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({'error': f'Upload fout: {str(e)}'}), 500

@app.route('/api/clarify', methods=['POST'])
def clarify():
    """
    Beantwoord verduidelijkingsvragen en verfijn de analyse
    """
    data = request.json
    
    if not data or 'filename' not in data or 'answer' not in data:
        return jsonify({'error': 'Ontbrekende vereiste velden'}), 400
    
    filename = data['filename']
    answer = data['answer']
    conversation_history = data.get('conversation_history', [])
    
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    
    if not os.path.exists(filepath):
        return jsonify({'error': 'Bestand niet gevonden'}), 404
    
    try:
        # Voeg het antwoord van de gebruiker toe aan de conversatie
        conversation_history.append({
            "role": "user",
            "content": answer
        })
        
        # Vraag GPT-4 Vision om de analyse te verfijnen
        base64_image = encode_image(filepath)
        
        conversation_history.append({
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": f"Op basis van deze aanvullende informatie: '{answer}', verfijn de gebouwanalyse. Geef een bijgewerkte analyse in hetzelfde JSON formaat."
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{base64_image}",
                        "detail": "high"
                    }
                }
            ]
        })
        
        result = analyze_building_image(filepath, conversation_history)
        result['filename'] = filename
        result['conversation_history'] = conversation_history
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({'error': f'Analyse fout: {str(e)}'}), 500

@app.route('/api/health', methods=['GET'])
def health():
    """
    Health check endpoint
    """
    return jsonify({
        'status': 'healthy',
        'api_configured': bool(openai.api_key),
        'timestamp': datetime.now().isoformat()
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
