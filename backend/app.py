from flask import Flask, jsonify, request
from supabase import create_client, Client
from config import Config

app = Flask(__name__)

supabase : Client = create_client(Config.SUPABASE_URL, Config.SUPABASE_KEY)

@app.route("/login" , methods=["GET"])
def login():
    try:
        email = request.args.get("email")
        pwd = request.args.get("password")


        if not email or not pwd:
            return jsonify({"error": "Email and password are required"}, 400)
        
        res = supabase.auth.sign_in_with_password({"email": email, "password" : pwd})

        if "error" in res:
            return jsonify({"error" : res["error"]["message"]}, 401)
        
        return jsonify({
            "message" : "Login successfully",
            "access_token" : res.session.access_token,
            "refresh_token" : res.session.refresh_token,
            "user" : res.user
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}, 500)
        

@app.route("/register" , methods=["POST"])
def register():
    try:

        data = request.get_json()
        name = data.get("name")
        phone = data.get("phone")
        email = data.get("email")
        pwd = data.get("password")


        if not name or not phone or not email or not pwd:
            return jsonify({"error" : "Name, phone, email and password are required"}, 400)
        

        # error here
        auth_res = supabase.auth.sign_up({"email": email, "password": pwd})


        if "error" in auth_res:
            return jsonify({"error" : auth_res["error"]["message"]}, 401)
        
        user_id = auth_res.user.id
        user_data= {
            "id" : user_id,
            #"email" : email,
            "name" : name,
            "phone" : phone
        } 


        db_res = supabase.table("users").insert(user_data).execute()

        if db_res.status_code != 201:
            print("Error code: ",db_res.status_code )
            return jsonify({"error" : "Something went wrong while updating user info"}, 500)
        
        return jsonify({
            "message" : "User register successfully",
            "user" : {
                "id" : user_id,
                "email" : email,
                "name" : name,
            }
        })

    except Exception as e:
        return jsonify({"error" : str(e)}, 500)
    



if __name__ == "__main__":
    app.run(debug=True)