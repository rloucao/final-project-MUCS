from flask import Flask, jsonify, request
from supabase import create_client, Client
from config import Config
from flask_cors import CORS
import os
import logging
from datetime import datetime


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


app = Flask(__name__)
CORS(app)#, origins=os.getenv('ORIGINS'))


supabase_url = Config.SUPABASE_URL
supabase_key = Config.SUPABASE_KEY
supabase: Client = create_client(supabase_url, supabase_key)

@app.route("/login" , methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    pwd = data.get("password")

    if not email or not pwd:
        return jsonify({"error": "Email and password are required"}, 400)

    try:
        
        auth_response = supabase.auth.sign_in_with_password({
        "email": email,
        "password": pwd,
        })
    
        user_data = None
        if auth_response.user:
            user_data = {
                "id": auth_response.user.id,
                "email": auth_response.user.email,
                "created_at": auth_response.user.created_at,
                "user_metadata": auth_response.user.user_metadata
            }

            # get user information from supabase
            user_info = supabase.table("profiles").select("*").eq("id", auth_response.user.id).execute()
            user_data["user_metadata"] = user_info.data[0]
            print(user_data)
        
        return jsonify({
            "success": True, 
            "user": user_data,
            "session": auth_response.session.access_token if auth_response.session else None
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}, 500)
        

@app.route('/register', methods=['POST'])
def register_user():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    full_name = data.get('full_name')
    phone = data.get('phone')
    
    if not email or not password or not full_name or not phone:
        return jsonify({"error": "Email, password, name and phone are required!"} , 400)

    try:
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "full_name": full_name,
                    "phone": phone,
                    "email" : email
                }
            }
        })

        user_data = None
        if auth_response.user:
            user_data = {
                "id": auth_response.user.id,
                "email": auth_response.user.email,
                "created_at": auth_response.user.created_at,
                "user_metadata": auth_response.user.user_metadata
            }
        
        return jsonify({
            "success": True, 
            "user": user_data,
            "session": auth_response.session.access_token if auth_response.session else None
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}, 500)

@app.route('/logout', methods=['POST'])
def logout():
    try:
        supabase.auth.sign_out()
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}, 500)


@app.route('/sync_data', methods=['POST'])
def sync_data():
    data = request.json
    print(data)
    return jsonify({"success": True})

@app.route('/get_plants', methods=['GET'])
def get_plants():
    try:
        response = supabase.table("plant_list").select("*").execute()
        return jsonify({"success": True, "plants": response.data})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}, 500)

@app.route('/send_sensor_data', methods=['POST'])
def receive_data():
    data = request.args.get('data')
    # data = 25.60-60.30-450-1234567890
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    parts = data.split('-')
    
    try:
        temp = float(parts[0]) if len(parts) > 0 else None
        humidity = float(parts[1]) if len(parts) > 1 else None
        light = float(parts[2]) if len(parts) > 2 else None
        # Keep MAC ID as string or convert to int, not float
        mac_id = parts[3] if len(parts) > 3 else None
        
        #print(f"Received data: {data}")
        logger.info(f"Received data: {data}")
        # Log the parsed values
        logger.info(f"Parsed values - Temp: {temp}, Humidity: {humidity}, Light: {light}, MAC ID: {mac_id}")
        #print(f"Parsed - Temp: {temp}, Humidity: {humidity}, Light: {light}, MAC: {mac_id}")
        
        if temp is None or humidity is None or light is None or mac_id is None:
            return jsonify({"error": "Invalid data format"}), 400
            
    except (ValueError, IndexError) as e:
        return jsonify({"error": f"Data parsing error: {str(e)}"}), 400
    
    # Save to supabase
    try:
        # Check if plant exists
        #print("checking if plant exists in database...")
        logger.info("Checking if plant exists in database...")
        res = supabase.table("plant").select("*").eq("id", mac_id).execute()
        #print(res.data)
        logger.info(f"Plant check result: {res.data}")

        if not res.data:
            #print("Plant not found. Inserting new entry...")
            logger.info("Plant not found. Inserting new entry...")
            supabase.table("plant").insert({
                "mac_id": mac_id,
                "name": '[''Abutilon hybridum'']', 
                "location": "lobby"
            }).execute()
            #print(f"Created new plant entry for MAC: {mac_id}")
            logger.info(f"Created new plant entry for MAC: {mac_id}")

        # Insert sensor data
        supabase.table("plant_info").insert({
            "MAC_ID": mac_id,
            "Temp": temp,
            "Moisture": humidity,
            "Light": light,
            "Status": "healthy"
        }).execute()
        
        # Update the plant's last_intervened time with proper timestamp
        current_time = datetime.utcnow().isoformat()
        supabase.table("plant").update({
            "last_intervened": current_time
        }).eq("id", mac_id).execute()
        
        #print(f"Successfully saved data for MAC: {mac_id}")
        logger.info(f"Successfully saved data for MAC: {mac_id}")
        
    except Exception as e:
        print(f"Database error: {str(e)}")
        return jsonify({"error": str(e)}), 500
    
    return jsonify({"success": True}), 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=False)