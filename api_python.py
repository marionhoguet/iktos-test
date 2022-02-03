import flask
import pandas as pd
import wget
from flask import jsonify, Response
import json
import random

app = flask.Flask(__name__)


dataset = pd.read_csv('dataset.csv', header=None)


def checkIndexesAndType(number, axis):
    try:
        number = int(number)
    except:
        return False
    row, col = dataset.shape
    if axis == "column" and number >= col:
        return False
    if axis == "row" and number >= row:
        return False
    return True    

@app.route('/')
def hello_world():
   return "Hello, World!"

@app.route('/getRow/<number>')
def getRow(number):
    row, col = dataset.shape
    if checkIndexesAndType(number, "row"):
        return Response(dataset.iloc[int(number),:].to_json(orient="records"), mimetype="application/json")
    return jsonify(response="Bad parameter"), 500

@app.route('/getColumnMeanValue/<number>')
def getColumnMeanValue(number):
    row, col = dataset.shape
    if checkIndexesAndType(number, "column"):
        try:
            return jsonify(response=dataset.iloc[:,int(number)].mean())
        except:
            return jsonify(response="Bad column type"), 500
    return jsonify(response="Bad parameter"), 500

@app.route('/getColumnMostFrequentValue/<number>')
def getColumnMostFrequentValue(number):
    if checkIndexesAndType(number, "column"):
        return jsonify(response=str(dataset.iloc[:,int(number)].mode()[0]))
    return jsonify(response="Bad parameter"), 500

@app.route('/getColumnMedian/<number>')
def getColumnMedian(number):
    if checkIndexesAndType(number, "column"):
        try:
            return jsonify(response=dataset.iloc[:,int(number)].median())
        except:
            return jsonify(response="Bad column type"), 500
    return jsonify(response="Bad parameter"), 500

@app.route('/getRandomRow')
def getRandomRow():
    row, col = dataset.shape
    randomIndex = random.randint(0,row-1)
    return Response(dataset.iloc[int(randomIndex),:].to_json(orient="records"), mimetype="application/json")
