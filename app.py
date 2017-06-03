from flask import Flask, json, jsonify, render_template, request

app = Flask(__name__) # our wsgi app

resources = {
        "auth":"POST /api/auth"
        , "matrix": "GET, PUT, POST /api/matrix/(:id)"
        }

@app.route('/api')
@app.route('/api/<any>', methods=['POST', 'GET', 'PUT', 'DELETE'])
def api(any=None):
    if not any:
        return jsonify(resources)
    else:
        if any == "auth" and request.method!='POST':
            return jsonify("Method not allowed, sucker!")
        if any == "matrix":
            return jsonify("TODO: matrix endpoints")
        return jsonify("nada")


@app.route('/')
@app.route('/<any>')
def spa(any=None):
    return render_template('index.html',any=any)

