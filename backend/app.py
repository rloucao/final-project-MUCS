from flask import Flask, jsonify, request
from supabase import create_client, Client
from config import Config
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


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

@app.route('/receive_data', methods=['GET'])
def receive_data():
    data = request.args.get('data')
    print(data)
    return jsonify({"success": True})

if __name__ == "__main__":
    app.run(debug=True)