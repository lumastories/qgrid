#!/usr/bin/python
# -*- coding: utf-8 -*-
from flask import Flask, json, jsonify, render_template, request
from flask_jwt import JWT, current_identity, jwt_required
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import check_password_hash, generate_password_hash

app = Flask(__name__)  # our wsgi app

### DATABASE

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////tmp/test.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class User(db.Model):

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True)
    password_hash = db.Column(db.String(128))

    @property
    def password(self):
        raise AttributeError('`password` is not a readable attribute')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def verify_password(self, password):
        return check_password_hash(self.password_hash, password)

    def __init__(self, username):
        self.username = username

    def __repr__(self):
        return '<User {}>'.format(self.username)

class Matrix(db.Model):

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=False)
    slug = db.Column(db.String(80), unique=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    user = db.relationship('User', backref=db.backref('matrices',
                           lazy='dynamic'))

    def __init__(
        self,
        name,
        user,
        slug,
        ):
        self.name = name
        self.slug = slug
        self.user = user

    def __repr__(self):
        return '<Matrix {}>'.format(self.name)


class Cell(db.Model):

    id = db.Column(db.Integer, primary_key=True)
    col_index = db.Column(db.Integer)
    row_index = db.Column(db.Integer)
    value = db.Column(db.String(100))
    matrix_id = db.Column(db.Integer, db.ForeignKey('matrix.id'))
    matrix = db.relationship('Matrix', backref=db.backref('cells',
                             lazy='dynamic'))

    def __init__(
        self,
        col_index,
        row_index,
        value,
        matrix,
        ):
        self.col_index = col_index
        self.row_index = row_index
        self.value = value
        self.matrix = matrix


class Name(db.Model):

    id = db.Column(db.Integer, primary_key=True)
    index = db.Column(db.Integer)
    name = db.Column(db.String(100))
    row = db.Column(db.Boolean)
    matrix_id = db.Column(db.Integer, db.ForeignKey('matrix.id'))
    matrix = db.relationship('Matrix', backref=db.backref('names',
                             lazy='dynamic'))

    def __init__(
        self,
        index,
        name,
        row,
        matrix,
        ):
        self.index = index
        self.name = name
        self.row = row
        self.matrix = matrix


### mock data

db.drop_all()
db.create_all()

# make a user with four 3x3 labeled and populated matricies

u = User(username='nate')
u.set_password('123baby')
db.session.add(u)

for i in range(400):
    m = Matrix(name='Matrix ' + str(i), slug='123123' + str(i), user=u)
    db.session.add(m)

    for j in [0, 1, 2]:
        for k in [0, 1, 2]:
            c = Cell(j, k, 'text'+str(j)+str(k), m)
            db.session.add(c)

        n1 = Name(index=j, name='col'+str(j), row=False, matrix=m)
        n2 = Name(index=j, name='row'+str(j), row=True, matrix=m)
        db.session.add(n1)
        db.session.add(n2)

db.session.commit()

### ----------------- end mock data

## API

### Auth

def authenticate(username, password):
    user = User.query.get(username=username)
    if user and user.verify_password(password.encode('utf-8')):
        return user

def identity(payload):
    user_id = payload['identity']
    return User.query.get(id=user_id)

jwt = JWT(app, authenticate, identity)

resources = {'auth': 'POST /api/auth',
             'matrix': 'GET, PUT, POST /api/matrix/(:id)',
             'user/:id/matrix/(:id)' : 'GET, PUT, POST /api/user/:id/matrix/(:id)'
             }


@app.route('/api')
@app.route('/api/<any>', methods=['POST', 'GET', 'PUT', 'DELETE'])
def api(any=None):
    if not any:
        return jsonify(resources)
    else:
        if any == 'auth' and request.method == 'POST':
            user = authenticate(request.data['username'], request.data['password'])
            if user:
                return jsonify('Welcome :)')    
            return jsonify('Method not allowed, sucker!')
        if any == 'matrix':
            db_matrixs = Matrix.query.order_by(Matrix.name)
            
            json_matrixs = []
            for m in db_matrixs:
                cells = Cell.query.filter_by(matrix=m)
                names = Name.query.filter_by(matrix=m).order_by(Name.index)
                
                #####
                grid = []
                row = []
                max_row_index = max([c.row_index for c in cells])
                for c in cells:
                    row.append(c.value)
                    if c.row_index == max_row_index:
                        grid.append(row)
                        row = []
                
                # #####

                jm = {
                    'name':m.name,
                    'grid': grid,
                    'row_names': [n.name for n in names if n.row],
                    'col_names': [n.name for n in names if not n.row]
                }
                json_matrixs.append(jm)

            return jsonify(json_matrixs)

        return jsonify('nada')




@app.route('/')
@app.route('/<any>')
def spa(any=None):
    return render_template('index.html', any=any)
