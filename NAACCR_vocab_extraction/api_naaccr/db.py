from sqlalchemy import Integer, Column, String, create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base

# to run db.py use this import
from api_naaccr.constants import DB_SCHEMA, DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME

# for scrapy use this import:
#from .constants import DB_SCHEMA, DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME

metadata = MetaData(schema=DB_SCHEMA)
Base = declarative_base(metadata=metadata)


class AlgorithmSchema(Base):

    __tablename__ = 'api_algorithm_schema'

    id = Column(Integer, primary_key=True, autoincrement=True)
    algorithm = Column(String(20))
    version = Column(String(100))
    schema_id = Column(String(100))
    schema_description = Column(String(1000))
    naaccr_item = Column(String(100))
    table_id = Column(String(100))
    table_name = Column(String(1000))


class AlgorithmTable(Base):

    __tablename__ = 'api_algorithm_table'

    id = Column(Integer, primary_key=True, autoincrement=True)
    algorithm = Column(String(20))
    version = Column(String(100))
    table_id = Column(String(100))
    table_name = Column(String(1000))
    table_title = Column(String(1000))
    value_code = Column(String(100))
    value_description = Column(String(5000))


if __name__ == '__main__':
    engine = create_engine('postgresql+psycopg2://{}:{}@{}:{}/{}'.format(DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME))
    Base.metadata.create_all(engine)
