import logging
import os 
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    # конфиг через ENV
    app.config.from_mapping(
        SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL"),
        SQLALCHEMY_TRACK_MODIFICATIONS = False
    )
    db.init_app(app)
    migrate.init_app(app, db)
    from .views import bp
    app.register_blueprint(bp)

    with app.app_context():
        logging.basicConfig(level=logging.INFO)
        logging.info(f"Connected to database: {db.engine.url}")
    
    return app