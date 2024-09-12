from flask import Flask,render_template,request

app=Flask(__name__)

@app.route('/',methods=["get","post"])
def index():
    return render_template('index.html')

@app.route('/second',methods=["get","post"])
def second():
    return render_template('second.html')

if __name__=='__main__':
    app.run()
